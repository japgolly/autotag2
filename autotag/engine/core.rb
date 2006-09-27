require 'autotag/audio_file'
require 'autotag/engine/config'
require 'autotag/engine/conversions'
require 'autotag/engine/misc'
require 'autotag/engine/override_file_reader'
require 'autotag/ruby_ext'
require 'iconv'

module Autotag
  class Engine
    include Config
    include Conversions
    include Misc
    include OverrideFileReader
    
    def run
      init
      process_root @root_dir
      shutdown
    end
    
    private
    
    def init
      puts "Golly's MP3 Auto-tagger v#{Autotag::VERSION}"
      puts "Copyright (c) 2006 David Barri. All rights reserved."
      @root_dir= Dir.pwd
      @stats= {}
    end
    
    def shutdown
      puts
    end
    
    # Process the root directory.
    # Contains: dirs of artists.
    # Eg: x:/music
    def process_root(root_dir)
      in_dir(root_dir) {
        @metadata= {}
        # Find artists
        each_matching :dir, file_patterns(:artist), file_ignore_patterns(:artist) do |d,p|
          process_artist_dir(d,p)
        end
      }
    end
    
    # Process the artist directory.
    # Contains: dirs of albums.
    # Eg: x:/music/Andromeda
    def process_artist_dir(dir,pat)
      raise unless filename2utf8(dir) =~ pat
      @metadata[:artist]= filename2human_text($1)
      in_dir(dir) {
        read_overrides(:artist)
        # Find albums
        each_matching :dir, file_patterns(:album), file_ignore_patterns(:album) do |d,p|
          process_album_dir(d,p)
        end
        # TODO Find albumtype directories
      }
    end
    
    # Process the album directory.
    # Contains: tracks, dirs of cds.
    # Eg: x:/music/Andromeda/2006 - Chimera
    def process_album_dir(dir,pat)
      raise unless filename2utf8(dir) =~ pat
      @metadata[:year]= $1
      @metadata[:album]= filename2human_text($2)
      in_dir(dir) {
        read_overrides(:album)
        
        # Find tracks
        tracks2= advanced_glob(:file, file_patterns(:track), file_ignore_patterns(:track))
        unless tracks2.empty?
          tracks= {}
          tracks2.each {|f,fu,p|
            raise unless fu =~ p
            o= {:track_number => $1, :track => filename2human_text($2)}
            remove_leading_zeros! o[:track_number]
            tracks[f]= o
          }
          with_metadata do
            @metadata[:total_tracks]= tracks.values.map{|o|o[:track_number]}.reject{|x|x !~ /^\d+$/}.map{|x|x.to_i}.sort.last.to_s
            tracks.each do |f,o|
              with_metadata do
                @metadata.merge! o
                if @metadata[:_track_overrides]
                  v= @metadata[:_track_overrides][@metadata[:track_number]]
                  @metadata[:track]= v if v
                end
                process_track!(f)
              end
            end
          end # with_metadata
        end # unless tracks.empty?
        
        # TODO Find cd directories
        # Find and call process_album_dir()
      }
    end
    
    # Process a track.
    def process_track!(filename)
      
      replace_track= false
      AudioFile.open_file(filename) do |af|
        # read tags from file
        existing_tags= af.read_tags
        
        # Copy preservable attributes
        existing_tags.each_value {|tag|
          preservable_attributes.each {|a|
            @metadata[a] ||= tag[a] if tag[a]
          }
        }
        
        # Create new file
        File.open(temp_filename,'wb') do |fout|
          replace_track= true
          # Write header tags
          fout<< create_tags(af, tags_to_write(true), true)
          # Copy audio
          fout<< af.read_all
          # Write footer tags
          fout<< create_tags(af, tags_to_write(false), false)
        end
        
      end # AudioFile.open
      replace_track!(filename) if replace_track
    end
    
    #----------------------------------------------------------------------------
    
    def create_tags(af, tag_classes, header)
      x= ''
      tag_classes.each {|tag_class|
        t= af.tag_processor(tag_class)
        t.set_metadata(@metadata)
        t[header ? :_header : :_footer]= true
        x<< t.create
      }
      x
    end
    
    def replace_track!(filename)
      raise 'Temp file doesnt exist. Cant replace old file.' unless File.exists?(temp_filename)
      File.delete filename
      File.rename temp_filename, filename
    end
    
  end
end
