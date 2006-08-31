require 'autotag/tags'

module Autotag
  class AudioFile
    include Tags
    attr_reader :filename, :fin
    TAGS_TO_READ= [APEv2,ID3v1,ID3v2]
    
    def self.open(filename)
      inst= self.new(filename)
      yield inst
      inst.close
    end
    
    def close()
      @fin.close
    end
    
    def ignore_header(bytes)
      @ignore_header += bytes
    end
    def ignore_footer(bytes)
      @ignore_footer += bytes
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
      @tags= {}
      tags_found= true
      while(tags_found)
        tags_found= false
        TAGS_TO_READ.each {|tag_class|
          t= tag_class.new(self)
          if t.tag_exists?
            @tags[tag_class]= t.read
            tags_found= true
          end
        }
      end
      @tags
    end
    
    def seek_to_start(bytes=0)
      @fin.seek(size_of_header + bytes, IO::SEEK_SET)
    end
    def seek_to_end(bytes=0)
      @fin.seek(-size_of_footer - bytes, IO::SEEK_END)
    end
    
    def size_of_header
      @ignore_header
    end
    def size_of_footer
      @ignore_footer
    end
    
    private
    
    def initialize(filename)
      @filename= filename
      @fin= File.open(filename,'rb')
      @ignore_header= @ignore_footer= 0
    end
    
  end
end
