module Autotag
  class Engine
      
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
        @metadata[:artist]= convert_filedir_name(File.basename(dir))
        read_metadata_from_text_files true, false, false
        # TODO: Handle albumtype directories
        each_subdir('???? - *') {|d| process_album_dir d}
      end
    end
    
    def process_album_dir(dir)
      @metadata[:album]= convert_filedir_name(File.basename(dir))
      indent :title => "Processing album directory: #{dir}", :dir => dir do
        Dir.glob('?? - *.mp3').each {|filename|
          process_mp3 filename
        }
      end
    end
    
    def process_mp3(filename)
      puts filename
      
      filename =~ /^(..) - (.+).mp3$/i
      @metadata[:tracknumber],@metadata[:track]= $1,convert_filedir_name($2)
      
      # open file
      AudioFile.open(filename) do |af|
        af.read_tags.each {|tag,hash| puts "#{tag}: #{hash.inspect}"}
        # read tags from file
      end
      # create new tags in memory (using replygain data)
      # compare tags
      # if changes need to be made then
        # rename file
        # open new file
        # create new file
    end
    
    #----------------------------------------------------------------------------
    
    def convert_filedir_name(str)
      str= str.gsub %r{ _ }, ' / '      # "aaa _ bbb" --> "aaa / bbb"
      str= str.gsub %r{_$}, '?'         # "aaa_" --> "aaa?"
      str= str.gsub %r{(?!= )_ }, ': '  # "aaa_ bbb" --> "aaa: bbb"
      str= str.gsub "''", '"'           # "Take The ''A'' Train" --> "Take The "A" Train"
    end
    
    def each_subdir(mask='*')
      dirs= Dir.glob(mask, File::FNM_DOTMATCH) - ['.','..']
      dirs.delete_if {|d| not File.stat(d).directory?}
      dirs.each {|d| yield d}
    end
    
    def indent(options={})
  #    puts "\n"
      puts options[:title] if options[:title]
      @indent<< '  '
      if options[:dir]
        Dir.chdir(options[:dir]) {yield}
      else
        yield
      end
      @indent= @indent[0..-3]
    end
    
    def puts(str=nil)
      str= "#{@indent}#{str}" if str
      Kernel.puts str
    end
    
    def read_metadata_from_text_files(read_artist, read_album, read_track)
      ['index.txt','autotag.txt'].each {|filename|
        # TODO: Handle UTF-8/16 files
        File.readlines(filename).each {|l|
          l.strip!
          @metadata[:artist]=    $1.strip if read_artist && l =~ /^ARTIST *:(.+)/i
          @metadata[:album]=     $1.strip if read_album  && l =~ /^ALBUM *:(.+)/i
          @metadata[:albumtype]= $1.strip if read_album  && l =~ /^ALBUMTYPE *:(.+)/i
        } if File.exists?(filename)
      }
    end
    
  end
end
