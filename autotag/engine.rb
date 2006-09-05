require 'autotag/audio_file'
require 'autotag/metadata_overrides'

module Autotag
  class Engine
    include MetadataOverrides
    include Tags
    
    TAGS_TO_WRITE= {}
    TAGS_TO_WRITE[:header]= {ID3v2 => {:_version => 4}}
    TAGS_TO_WRITE[:footer]= APEv2
    TAGS_TO_WRITE[:all]= ([TAGS_TO_WRITE[:header]] + [TAGS_TO_WRITE[:footer]]).flatten.map{|t| t.is_a?(Hash) ? t.keys : t }.flatten.uniq
      
    def self.run
      new.run
    end
    
    def run
      init
  #    process_root Dir.pwd
  #    process_root 'x:\music\2. Tag Me'
      process_root 'test/data'
    end
    
    #============================================================================
    private
    
    def init
      puts "Golly's MP3 Auto-tagger v#{Autotag::VERSION}"
      puts "Copyright (c) 2006 David Barri. All rights reserved."
      @indent= ''
    end
    
    #----------------------------------------------------------------------------
    
    def process_root(root)
      @metadata= {}
      indent :title => "Processing root directory: #{root}", :dir => root do
        each_subdir {|d| process_artist_dir d}
      end
    end
    
    def process_artist_dir(dir)
      indent :title => "Processing artist directory: #{dir}", :dir => dir do
        @metadata[:artist]= process_file_or_directory_name(File.basename(dir))
        read_metadata_overrides :artist
        # TODO: Handle albumtype directories
        each_subdir('???? - *') {|d| process_album_dir d}
      end
    end
    
    def process_album_dir(dir)
      File.basename(dir) =~ /^(....) - (.+)$/i
      @metadata[:year],@metadata[:album]= $1,process_file_or_directory_name($2)
      @metadata.delete(:year) unless @metadata[:year] =~ /\d+/
      indent :title => "Processing album directory: #{dir}", :dir => dir do
        Dir.glob('?? - *.mp3').each {|filename|
          process_mp3 filename
        }
      end
    end
    
    def process_mp3(filename)
      puts filename
      # open file
      AudioFile.open(filename) do |af|
        # read tags from file
        existing_tags= af.read_tags
        
        # create new tags in memory (using replygain data)
        metadata= @metadata.clone
        filename =~ /^(..) - (.+).mp3$/i
        metadata[:tracknumber],metadata[:track]= $1,process_file_or_directory_name($2)
        existing_tags.each_value {|etag|
          [:replaygain_track_gain, :replaygain_album_gain, :replaygain_track_peak, :replaygain_album_peak].each {|k|
            metadata[k]= etag[k] if etag[k]
          }
        }
        tn= metadata[:tracknumber].to_i rescue nil
        metadata[:track]= metadata[tn] if tn && metadata.has_key?(tn)
        metadata.delete_if{|k,v|k.is_a?Fixnum}
        
        # compare tags
        expected_tags= {}
        TAGS_TO_WRITE[:all].each {|tag_class|
          expected_tags[tag_class]= metadata.clone
          expected_tags[tag_class].merge!(TAGS_TO_WRITE[:header][tag_class]) if TAGS_TO_WRITE[:header].is_a?(Hash) && TAGS_TO_WRITE[:header][tag_class]
          expected_tags[tag_class].merge!(TAGS_TO_WRITE[:footer][tag_class]) if TAGS_TO_WRITE[:footer].is_a?(Hash) && TAGS_TO_WRITE[:footer][tag_class]
        }

        if existing_tags == expected_tags
          puts 'Up to date'
        else
          puts 'Updating'
          # create tmp file
          # write header tags
          # copy mp3
          # write footer tags
          # rename files
        end
        
      end # AudioFile.open
    end # def process_mp3
    
    #----------------------------------------------------------------------------
    
    def each_subdir(mask='*')
      dirs= Dir.glob(mask, File::FNM_DOTMATCH) - ['.','..']
      dirs.delete_if {|d| not File.stat(d).directory?}
      dirs.each {|d| yield d}
    end
    
    def indent(options={})
#      puts "\n"
      puts options[:title] if options[:title]
      @indent<< '  '
      if options[:dir]
        Dir.chdir(options[:dir]) {yield}
      else
        yield
      end
      @indent= @indent[0..-3]
    end
    
    def process_file_or_directory_name(str)
      x= str.dup
      x.gsub! %r{ _ }, ' / '      # "aaa _ bbb" --> "aaa / bbb"
      x.gsub! %r{_$}, '?'         # "aaa_" --> "aaa?"
      x.gsub! %r{(?!= )_ }, ': '  # "aaa_ bbb" --> "aaa: bbb"
      x.gsub! "''", '"'           # "Take The ''A'' Train" --> "Take The "A" Train"
      x
    end
    
    def puts(str=nil)
      str= "#{@indent}#{str}" if str
      Kernel.puts str
    end
    
    
  end
end
