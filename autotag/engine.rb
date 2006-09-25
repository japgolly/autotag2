require 'autotag/audio_file'
require 'autotag/metadata_overrides'
require 'autotag/ruby_ext'
require 'pp' #DELME
$KCODE= 'u'

# TAG PARAMS
# id3v1:
#   _version
# id3v2:
#   _header
#   _footer
#   _version
# apev2:
#   _header
#   _footer
# vorbis:
#   _tool
#   _padding
# lyrics3:
#   _version
#   _tag
module Autotag
  class Engine
    include MetadataOverrides
    include Tags
    
    def self.run
      new.run
    end
    
    def run
      init
      process_root Dir.pwd
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
          process_song filename
        }
      end
    end
    
    def process_song(filename)
      puts filename
      file_updated= false
      # open file
      AudioFile.open_file(filename) do |af|
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
          expected_tags[tag_class]= metadata.merge(DEFAULT_FIELDS[tag_class] || {})
        }

        if existing_tags == expected_tags
          puts 'Up to date'
        else
          puts 'Updating'
          file_updated= true
          # create tmp file
          File.open(TEMP_FILE,'wb') do |fout|
            # write header tags
            create_and_write_tags af, fout, TAGS_TO_WRITE[:header], expected_tags
            # copy mp3
            fout<< af.read_all
            # write footer tags
            create_and_write_tags af, fout, TAGS_TO_WRITE[:footer], expected_tags
          end
        end
        
      end # AudioFile.open
      # rename files
      replace_old_song(filename) if file_updated
    end # def process_mp3
    
    #----------------------------------------------------------------------------
    
    def create_and_write_tags(af,fout,tag_classes,tag_data)
      tag_classes.each {|tag_class|
        fout<< create_tag(af,tag_class,tag_data[tag_class])
      }
    end
    
    def create_tag(af,tag_class,content)
      af.tag_processor(tag_class).set_metadata(content).create
    end
    
    def delete_temp_file
      File.delete(TEMP_FILE) if File.exists?(TEMP_FILE)
    end
    
    def each_subdir(mask='*')
      dirs= Dir.glob(mask, File::FNM_DOTMATCH) - ['.','..']
      dirs.delete_if {|d| not File.stat(d).directory?}
      dirs.each {|d| yield d}
    end
    
    def indent(options={})
#      puts "\n"
      puts options[:title] if options[:title]
      @indent<< '  '
      # TODO This should be in a seperate function which calls indent
      if options[:dir]
        Dir.chdir(options[:dir]) {delete_temp_file; yield}
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
    
    def replace_old_song(filename)
      raise 'Temp file doesnt exist. Cant replace old file.' unless File.exists?(TEMP_FILE)
      File.delete filename
      File.rename TEMP_FILE, filename
    end
    
    #============================================================================
    TAGS_TO_WRITE= {}
    TAGS_TO_WRITE[:header]= [ID3v2]
    TAGS_TO_WRITE[:footer]= [APEv2]
    TAGS_TO_WRITE[:all]= (TAGS_TO_WRITE[:header]+TAGS_TO_WRITE[:footer]).uniq
    TAGS_TO_WRITE.deep_freeze
    DEFAULT_FIELDS= {}
    DEFAULT_FIELDS[ID3v2]= {:_version => 4}
    DEFAULT_FIELDS.deep_freeze
    TEMP_FILE= 'autotag - if autotag is not running you can delete this file.tmp'
  end
end
