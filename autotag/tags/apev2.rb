require "#{File.dirname __FILE__}/base"

module Autotag::Tags
  class APEv2 < Base
    
    def tag_exists?
      sof_tag_exists? || eof_tag_exists?
    end
    
    def read
      sof_read if sof_tag_exists?
      eof_read if eof_tag_exists?
      metadata
    end

    private
    
    def sof_tag_exists?
      @af.seek_to_start 32
      fin.read(8) == 'APETAGEX' && read_int == 2000
    end
    def eof_tag_exists?
      @af.seek_to_end 32
      fin.read(8) == 'APETAGEX' && read_int == 2000
    end
    
    def sof_read
      @af.seek_to_start 32
      info= read_tag_headerfooter(fin.read(32))
      @af.ignore_header(32) if info[:has_header]
      @af.ignore_header(info[:size])
      @af.seek_to_start
      read_tag_content(info)
    end
    def eof_read
      @af.seek_to_end 32
      info= read_tag_headerfooter(fin.read(32))
      @af.ignore_footer(info[:size])
      @af.seek_to_end
      @af.ignore_footer(32) if info[:has_header]
      read_tag_content(info)
    end
    
    def read_tag_content(info)
      info[:items].times do
        len= read_int
        flags= read_int
        key= read_string
        value= fin.read(len)
        self[tag2sym(key)]= value
      end
    end
    
    def read_tag_headerfooter(data)
      flags= read_int(data[20..23])
      {
        :items => read_int(data[16..19]),
        :size => read_int(data[12..15]),
        :has_header => flags[31]==1,
        :has_footer => flags[30]==0,
        :read_only => flags[0]==1,
      }
    end
    
    def read_int(x=nil)
      (x || fin.read(4)).unpack('L').first
    end

    def read_string
      x= ''
      while (ch= fin.getc) != 0
        x<< ch
      end
      x
    end
    
    def sym2tag(sym)
      SYM2TAG[sym] || sym
    end
    
    def tag2sym(tag)
      TAG2SYM[tag] || tag
    end
    
    SYM2TAG= {
      :albumtype => 'Albumtype',
      :replaygain_track_gain => 'replaygain_track_gain',
      :replaygain_album_gain => 'replaygain_album_gain',
      :replaygain_track_peak => 'replaygain_track_peak',
      :replaygain_album_peak => 'replaygain_album_peak',
      :artist => 'Artist',
      :album => 'Album',
      :track => 'Title',
      :year => 'Year',
      :tracknumber => 'Track',
    }
    TAG2SYM= SYM2TAG.invert
  end
end