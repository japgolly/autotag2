require 'autotag/tags'

module Autotag
  class AudioFile
    include Tags
    attr_reader :filename, :fin, :type
    TAGS_TO_READ= [APEv2,ID3v1,ID3v2]
    
    def self.open_file(filename)
      inst= self.new(filename,:file)
      yield inst
      inst.close
    end
    
    def self.open_string(string)
      inst= self.new(string,:string)
      yield inst
      inst.close
    end
    
    def close()
      fin.close
    end
    
    def ignore_header(bytes)
      @ignore_header += bytes
    end
    def ignore_footer(bytes)
      @ignore_footer += bytes
    end
    
    def read_all
      seek_to_start
      fin.read(size)
    end
    
    def read_and_ignore_header(bytes)
      seek_to_start
      x= fin.read(bytes)
      ignore_header(bytes)
      x
    end
    def read_and_ignore_footer(bytes)
      seek_to_end(bytes)
      x= fin.read(bytes)
      ignore_footer(bytes)
      x
    end
    
    def read_tags
      @tag_data= {}
      tags_found= true
      while(tags_found)
        tags_found= false
        TAGS_TO_READ.each {|tag_class|
          t= tag_processor(tag_class)
          if t.tag_exists?
            @tag_data[tag_class]= t.read
            tags_found= true
          end
        }
      end
      @tag_data
    end
    
    def seek_to_start(bytes=0)
      fin.seek(size_of_header + bytes, IO::SEEK_SET)
    end
    def seek_to_end(bytes=0)
      fin.seek(-size_of_footer - bytes, IO::SEEK_END)
    end
    
    def size
      @total_size - @ignore_footer - @ignore_header
    end
    def size_of_header
      @ignore_header
    end
    def size_of_footer
      @ignore_footer
    end
    
    def tag_processor(tag_class)
      @tag_processors[tag_class] ||= tag_class.new(self)
    end
    
    private
    
    def initialize(source, type)
      case @type= type
      when :file
        @filename= source
        @fin= File.open(source,'rb')
        @total_size= fin.stat.size
      when :string
        require 'stringio'
        @fin= StringIO.open(source,'rb')
        @total_size= source.size
      else
        raise "Unsupported type: #{type.inspect}"
      end
      @ignore_header= @ignore_footer= 0
      @tag_processors= {}
    end
    
  end
end
