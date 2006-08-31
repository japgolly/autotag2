require "#{File.dirname __FILE__}/base"

module Autotag::Tags
  class ID3v2 < Base
    
    def tag_exists?
      @af.seek_to_start
      fin.read(3) == 'ID3'
    end
    
    def read
      # Read header
      @af.seek_to_start
      header= @af.read_and_ignore_header(10)
      self[:_version]= (header[4]==0 ? header[3] : "#{header[3]}.#{header[4]}".to_f)
      #TODO: Doesn't support extended headers
      size= read_int(header[6..9])
      pos=0
      
      # Read tag
      while(1)
        frame= {:id => fin.read(4)}
        frame[:size]= read_int
        frame[:flags]= fin.read(2)
        pos += 10
        break if frame[:id] == "\0\0\0\0" || pos > size
        pos += frame[:size]
        frame[:value]= read_string(fin.read(frame[:size]))
        if frame[:id] == 'TXXX'
          if frame[:value] =~ /^(.+?)\0(.+)$/
            self[tag2sym($1,true)]= $2
          else
            self[frame[:id]]= frame[:value]
          end
        else
          self[tag2sym(frame[:id])]= frame[:value]
        end
      end
      
      # Done
      @af.ignore_header size
      metadata
    end
    
    private
    
    def read_int(x=nil)
      x ||= fin.read(4)
      (x[3]&127) | ((x[2]&127) << 7) | ((x[1]&127) << 14) | ((x[0]&127) << 21)
    end
    
    def read_string(x)
      encoding= x[0]
      x= x[1..-1]
      case encoding
      when 0
        # ISO-8859-1 [ISO-8859-1]. Terminated with $00.
        x[0..-2].to_s
      when 1
        # UTF-16 [UTF-16] encoded Unicode [UNICODE] with BOM. All strings in the same frame SHALL have the same byteorder. Terminated with $00 00.
        # Unicode strings must begin with the Unicode BOM ($FF FE or $FE FF) to identify the byte order.
        raise 'Pending'
      when 2
        # UTF-16BE [UTF-16] encoded Unicode [UNICODE] without BOM. Terminated with $00 00.
        raise 'Pending'
      when 3
        # UTF-8 [UTF-8] encoded Unicode [UNICODE]. Terminated with $00.
        x[0..-2].to_s
      else
        raise "Invalid encoding flag: '#{encoding}'"
      end
    end
    
    def tag2sym(tag,extended_tag=false)
      if extended_tag
        TAGXXX2SYM[tag] || tag
      else
        TAG2SYM[self[:_version]][tag] || tag
      end
    end
    
    SYM2TAG= {
      :artist       => %w{0 1 2 TPE1 TPE1},
      :album        => %w{0 1 2 TALB TALB},
      :track        => %w{0 1 2 TIT2 TIT2},
      :track_number => %w{0 1 2 TRCK TRCK},
      :year         => %w{0 1 2 TYER TDRC},
    }
    SYM2TAGXXX= {
      :album_type            => 'Albumtype',
      :replaygain_album_gain => 'replaygain_album_gain',
      :replaygain_album_peak => 'replaygain_album_peak',
      :replaygain_track_gain => 'replaygain_track_gain',
      :replaygain_track_peak => 'replaygain_track_peak',
    }
    TAG2SYM= []
    SYM2TAG.each{|sym,tags|
      tags.each_index{|ver|
        TAG2SYM[ver] ||= {}
        TAG2SYM[ver][tags[ver]]= sym
      }
    }
    TAGXXX2SYM= SYM2TAGXXX.invert
    
  end
end