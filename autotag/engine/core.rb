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
        
        # Process tracks in this directory
        process_dir_of_tracks
        
        # Find cd directories
        dirs2= advanced_glob(:dir, file_patterns(:cd), file_ignore_patterns(:cd))
        unless dirs2.empty?
          dirs= map_advanced_glob_results(dirs2,:disc) {|m| {:disc => m[1]} }
          with_metadata do
            @metadata[:total_discs]= find_highest_numeric_value(dirs.values,:disc)
            dirs.each do |d,o|
              with_metadata do
                @metadata.merge! o
                in_dir(d) {
                  process_dir_of_tracks
                }
              end # with_metadata
            end # dirs.each
          end # with_metadata
        end # unless dirs.empty?
      }
    end
    
    # Process a directory containing tracks.
    # Contains: tracks.
    # Eg: x:/music/Andromeda/2006 - Chimera
    # Eg: x:/music/Andromeda/2006 - Chimera/CD 1
    def process_dir_of_tracks
      read_overrides(:album)
      
      # Find tracks
      tracks2= advanced_glob(:file, file_patterns(:track), file_ignore_patterns(:track))
      unless tracks2.empty?
        tracks= map_advanced_glob_results(tracks2,:track_number) {|m| {:track_number => m[1], :track => filename2human_text(m[2])} }
        with_metadata do
          @metadata[:total_tracks]= find_highest_numeric_value(tracks.values,:track_number)
          tracks.each do |f,o|
            with_metadata do
              @metadata.merge! o
              if @metadata[:_track_overrides]
                v= @metadata[:_track_overrides][@metadata[:track_number]]
                @metadata[:track]= v if v
              end
              process_track!(f)
            end # with_metadata
          end # tracks.each
        end # with_metadata
      end # unless tracks2.empty?
      
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
        
        # Create seperate metadata hashes for each tag
        expected_tags= {}
        create_expected_tags(af, expected_tags, tags_to_write(true), true)
        create_expected_tags(af, expected_tags, tags_to_write(false), false)
        
        # Update if needed
        unless tags_equal?(expected_tags,existing_tags)
          File.open(temp_filename,'wb') do |fout|
            replace_track= true
            # Write header tags
            fout<< create_bin_tags(af, expected_tags, tags_to_write(true))
            # Copy audio
            fout<< af.read_all
            # Write footer tags
            fout<< create_bin_tags(af, expected_tags, tags_to_write(false))
          end
        end
        
      end # AudioFile.open
      replace_track!(filename) if replace_track
    end
    
    #----------------------------------------------------------------------------
    
    def create_bin_tags(af, metadata_by_tag, tag_classes)
      x= ''
      tag_classes.each {|tag_class|
        x<< af.tag_processor(tag_class).set_metadata(metadata_by_tag[tag_class]).create
      }
      x
    end
    
    def create_expected_tags(af, collection, tag_classes, header)
      tag_classes.each {|tag_class|
        m= (collection[tag_class] || @metadata.deep_clone)
        m.delete(:_track_overrides)
        m[header ? :_header : :_footer]= true
        collection[tag_class]= af.tag_processor(tag_class).get_defaults.merge(m)
      }
    end
    
    def replace_track!(filename)
      raise 'Temp file doesnt exist. Cant replace old file.' unless File.exists?(temp_filename)
      File.delete filename
      File.rename temp_filename, filename
    end
    
    def tags_to_write_all
      @@tags_to_write_all ||= (tags_to_write(true) + tags_to_write(false)).uniq.freeze
    end
    
    def tags_equal?(a,b)
      return false unless a.keys == b.keys
      a.each_key {|t|
        return false unless (a[t] - ignorable_attributes) == (b[t] - ignorable_attributes)
      }
      true
    end
    
  end
end