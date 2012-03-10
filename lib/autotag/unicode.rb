# encoding: utf-8

module Autotag
  module Unicode

    def contains_unicode?(str)
      !str.ascii_only?
    end

    def read_unicode_file(filename)
      x= File.read(filename, nil, nil, encoding: 'binary')
      if x[0..1] == "\xFF\xFE"
        x[2..-1].force_encoding 'utf-16le'
      elsif x[0..1] == "\xFE\xFF"
        x[2..-1].force_encoding 'utf-16be'
      elsif x[0..2] == "\xEF\xBB\xBF"
        x[3..-1].force_encoding 'utf-8'
      else
        x.force_encoding 'utf-8'
      end
    end

    def to8(str)
      str.encode 'utf-8'
    end
    def to16(str)
      str.encode 'utf-16le'
    end

    def unicode_trim(str)
      str.gsub(REGEX_TRIM,'')
    end
    def unicode_trim!(str)
      str.gsub!(REGEX_TRIM,'')
    end

    #--------------------------------------------------------------------------
    private

    REGEX_TRIM= /^[ 　]+|[ 　]+$/u

  end
end
