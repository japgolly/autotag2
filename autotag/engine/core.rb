require 'autotag/app_info'
require 'autotag/audio_file'
require 'autotag/engine/albumart'
require 'autotag/engine/cmdline_options'
require 'autotag/engine/config'
require 'autotag/engine/conversions'
require 'autotag/engine/misc'
require 'autotag/engine/override_file_reader'
require 'autotag/engine/ui'
require 'autotag/ruby_ext'
require 'autotag/tags'
require 'autotag/unicode_io'
require 'iconv'

module Autotag
  class Engine
    include CommandLineOptions
    include Config
    include Conversions
    include Misc
    include OverrideFileReader
    include AlbumArt
    
    def initialize(*args)
      @engine_args= args
      @ui= UI.new(self)
    end
    
    def run
      Utils.exec_with_console_title(Autotag::TITLE_AND_VERSION) do
        init
        process_job_queue!
        shutdown
      end
    end
    
    #--------------------------------------------------------------------------
    private
    
    def init
      # Parse command line
      parse_commandline!(@engine_args.dup)
      
      # Start debug mode
      if @runtime_options[:debug]
        @debug_out= case @runtime_options[:debug]
          when :stdout then File.new(1,'w+')
          when :stderr then File.new(2,'w+')
          else File.new(debug_output_filename,'w')
        end
        debug_out{ Autotag::TITLE_AND_VERSION }
        debug_out{ "Cmdline args: #{@engine_args.map{|a|a.inspect}.join ' '}" }
        debug_out{ "Started #{Time.now}" }
      end
      
      # Init UI
      @ui.init(@runtime_options[:quiet])
      
      # Init config
      @album_types_dirs_glob_string= ('{'+supported_album_types.values.flatten.join(',')+'}').freeze
      @album_types_dir_to_value= {}
      supported_album_types.each{|v,a|a.each{|d| @album_types_dir_to_value[d]= v }}
      @album_types_dir_to_value.deep_freeze
      @supported_audio_formats= supported_audio_formats.join(',').freeze

      build_job_queue
    end
    
    def shutdown
      @ui.shutdown
      if @debug_out
        debug_out{ "\nFinished #{Time.now}" }
        @debug_out.close
      end
    end
    
    def build_job_queue
      @job_queue= []
      unless @specified_dirs
        @job_queue<< {:dir => UnicodeIO.pwd, :type => :root, :glob => {}}
      else
        @specified_dirs.uniq.each {|d|
          d= File.expand_path(d)
          dirtree= d.gsub(/[\/\\]$/,'').split(/[\/\\]/).reverse
          glob= {}
          type= nil
          
          # Check if CD dir
          if !type && find_matching_pattern(dirtree[0], file_patterns(:cd), file_ignore_patterns(:cd))
            match= false
            UnicodeIO.chdir(d) do
              # Look for tracks
              match ||= !advanced_glob(:file, file_patterns(:track), file_ignore_patterns(:track), :file_extentions => @supported_audio_formats).empty?
            end
            type= :cd if match
          end
          
          # Check if Album dir
          if !type && find_matching_pattern(dirtree[0], file_patterns(:album), file_ignore_patterns(:album))
            match= false
            UnicodeIO.chdir(d) do
              # Look for tracks or cd dirs
              match ||= !advanced_glob(:dir, file_patterns(:cd), file_ignore_patterns(:cd)).empty?
              match ||= !advanced_glob(:file, file_patterns(:track), file_ignore_patterns(:track), :file_extentions => @supported_audio_formats).empty?
            end
            type= :album if match
          end
          
          # Check if AlbumType dir
          if !type && @album_types_dir_to_value.has_key?(dirtree[0])
            type= :album_type
          end
          
          # Check if Artist dir
          if !type && find_matching_pattern(dirtree[0], file_patterns(:artist), file_ignore_patterns(:artist))
            match= false
            UnicodeIO.chdir(d) do
              # Look for albums or albumtype dirs
              match ||= !UnicodeIO.glob(0,nil,@album_types_dirs_glob_string).empty?
              match ||= !advanced_glob(:dir, file_patterns(:album), file_ignore_patterns(:album)).empty?
            end
            type= :artist if match
          end
          
          # Create job
          glob[:cd]=         dirtree.shift if type == :cd
          glob[:album]=      dirtree.shift if [:cd,:album].include?(type)
          glob[:album_type]= dirtree.shift if [:cd,:album,:album_type].include?(type) && @album_types_dir_to_value.has_key?(dirtree[0])
          glob[:artist]=     dirtree.shift if type
          type ||= :root
          newdir= dirtree.reverse.join('/')
          @job_queue<< {:dir => newdir, :orig_dir => d, :type => type, :glob => glob}
        }
      end
    end
    
    def process_job_queue!
      @job_queue.each {|job|
        @glob= job[:glob]        
        process_root job[:dir], (job[:orig_dir] || job[:dir])
        @glob= nil
      }
    end
    
    # Process the root directory.
    # Contains: dirs of artists.
    # Eg: x:/music
    def process_root(root_dir, root_dir_after_globbing)
      in_dir(root_dir) {
        on_event :root_dir_enter, root_dir, root_dir_after_globbing
        @metadata= {}
        # Find artists
        each_matching :dir, file_patterns(:artist), file_ignore_patterns(:artist), :glob => @glob[:artist] do |d,p|
          process_artist_dir(d,p)
        end
      }
    end
    
    # Process the artist directory.
    # Contains: dirs of albums.
    # Eg: x:/music/Andromeda
    def process_artist_dir(dir,pat)
      raise unless dir =~ pat
      @metadata[:artist]= filename2human_text($1)
      in_dir(dir) {
        on_event :artist_dir_enter, dir
        
        # Find albums
        process_dir_of_albums
        
        # Find albumtype directories
        UnicodeIO.glob(0,nil,@glob[:album_type] || @album_types_dirs_glob_string).ci_sort.each do |d|
          next unless UnicodeIO.directory?(d)
          in_dir(d) do
            on_event :album_type_dir_enter, dir
            with_metadata do
              @metadata[:album_type]= @album_types_dir_to_value[d]
              process_dir_of_albums
            end # with_metadata
          end # in_dir
        end # UnicodeIO.glob
      }
    end
    
    # Process a directory containing albums.
    # Contains: album directories.
    # Eg: x:/music/Dream Theater/
    # Eg: x:/music/Dream Theater/Albums/
    # Eg: x:/music/Dream Theater/Singles/
    def process_dir_of_albums
      read_overrides(:artist)
      each_matching :dir, file_patterns(:album), file_ignore_patterns(:album), :glob => @glob[:album] do |d,p|
        process_album_dir(d,p)
      end
    end
    
    # Process the album directory.
    # Contains: tracks, dirs of cds.
    # Eg: x:/music/Andromeda/2006 - Chimera
    def process_album_dir(dir,pat)
      raise unless dir =~ pat
      @metadata[:year]= $1
      @metadata[:album]= filename2human_text($2)
      @metadata[:album_type]= default_album_type unless @metadata.has_key?(:album_type)
      @metadata.delete(:album_type) if @metadata[:album_type].nil?
      @metadata.delete(:year) if @metadata[:year] =~ null_year_pattern
      @metadata.delete(:albumart)
      in_dir(dir) {
        on_event :album_dir_enter, dir
        
        # Load album art
        load_all_albumart
        
        # Process tracks in this directory
        process_dir_of_tracks
        
        # Find cd directories
        dirs2= advanced_glob(:dir, file_patterns(:cd), file_ignore_patterns(:cd), :glob => @glob[:cd])
        unless dirs2.empty?
          dirs= map_advanced_glob_results(dirs2,:disc) do |m|
            o= {:disc => m[1]}
            o[:disc_title]= filename2human_text(m[2]) if m[2]
            o
          end
          # Create a seperate collection called all_cd_dirs because if we are using a specific glob_str for the
          # cd directory, then not all cd dirs will be loaded and therefore the :total_discs attribute will be
          # incorrect.
          all_cd_dirs= if @glob[:cd]
              x= advanced_glob(:dir, file_patterns(:cd), file_ignore_patterns(:cd))
              map_advanced_glob_results(x,:disc) {|m|{:disc => m[1]}}
            else
              dirs
            end
          with_metadata do
            @metadata[:total_discs]= find_highest_numeric_value(all_cd_dirs.values,:disc)
            @metadata.delete_if_nil :total_discs
            dirs.keys.ci_sort.each do |d|
              o= dirs[d]
              with_metadata do
                @metadata.merge! o
                in_dir(d) {
                  on_event :cd_dir_enter, d
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
      tracks2= advanced_glob(:file, file_patterns(:track), file_ignore_patterns(:track), :file_extentions => @supported_audio_formats)
      unless tracks2.empty?
        tracks= map_advanced_glob_results(tracks2,:track_number) {|m| {:track_number => m[1], :track => filename2human_text(m[2])} }
        with_metadata do
          @metadata[:total_tracks]= find_highest_numeric_value(tracks.values,:track_number)
          @metadata.delete_if_nil :total_tracks
          tracks.keys.ci_sort.each do |f|
            o= tracks[f]
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
      format= @metadata.delete(:_format)
      format= format.downcase if Autotag::Utils::get_os == :windows
      debug_out{[ "\nTrack: #{File.join UnicodeIO.pwd,filename}", "Format: #{format}" ]}
      
      # V/A processing
      if @metadata[:artist] =~ va_artist_pattern
        @metadata[:album_artist]= @metadata.delete(:artist)
        t= @metadata.delete(:track)
        va_filename_patterns.each {|p|
          if t =~ p
            @metadata[:artist],@metadata[:track] = $1,$2
            break
          end
        }
        raise "Track in various artist album missing artist information. (#{UnicodeIO.pwd}/#{filename})" unless @metadata[:track] && @metadata[:artist]
      end
      
      replace_track= false
      AudioFile.open_file(filename) do |af|
        on_event :track_process, filename, af
      
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
        create_expected_tags(af, expected_tags, tags_to_write(format,true), true)
        create_expected_tags(af, expected_tags, tags_to_write(format,false), false)
        debug_out{ "Existing tags: #{existing_tags.inspect}" }
        debug_out{ "Expected tags: #{expected_tags.inspect}" }
        
        # Check if track is up-to-date
        if !@runtime_options[:force] and tags_equal?(expected_tags,existing_tags)
          debug_out{ "Retagging: no" }
          on_event :track_uptodate, filename
        else
          debug_out{ "Retagging: yes" }
          UnicodeIO::UFile.open(temp_filename,'wb') do |fout|
            replace_track= true
            # Write header tags
            fout<< create_bin_tags(af, expected_tags, tags_to_write(format,true))
            # Copy audio
            fout<< af.read_all
            # Write footer tags
            fout<< create_bin_tags(af, expected_tags, tags_to_write(format,false))
          end unless @runtime_options[:pretend]
          on_event :track_updated, filename
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
        collection[tag_class].delete(:albumart) unless tag_class.has_albumart_support?
      }
    end
    
    def debug_out
      return unless @debug_out
      yield.each {|l| @debug_out.puts l}
    end
    
    def on_event(event,*args)
      @ui.on_event(event,*args)
    end
    
    def replace_track!(filename)
      raise 'Temp file doesnt exist. Cant replace old file.' unless File.exists?(temp_filename)
      UnicodeIO.delete filename
      UnicodeIO.rename temp_filename, filename
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
