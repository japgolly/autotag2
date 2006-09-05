$KCODE= 'u'
require 'jcode'
require 'iconv'

module Autotag
  module Unicode
    
    def converter(charset)
      charset= charset.to_s
      @@converters[charset] ||= Iconv.new('utf-8',charset)
    end
    
    def convert_utf16(str, big_endian=false)
      converter(big_endian ? 'utf-16be':'utf-16le').iconv(str)
    end
    
    def read_unicode_file(filename)
      x= File.read(filename)
      if x[0..1] == "\xFF\xFE"
        convert_utf16(x[2..-1],false)
      elsif x[0..1] == "\xFE\xFF"
        convert_utf16(x[2..-1],true)
      elsif x[0..2] == "\xEF\xBB\xBF"
        x[3..-1]
      else
        x
      end
    end
    
    def unicode_trim(str)
      str.gsub(REGEX_TRIM,'')
    end
    def unicode_trim!(str)
      str.gsub!(REGEX_TRIM,'')
    end
    
    #--------------------------------------------------------------------------
    private
    
    @@converters= {}
    
    REGEX_TRIM= Regexp.new('^[ 　]+|[ 　]+$',0,'U')
    
  end
end
