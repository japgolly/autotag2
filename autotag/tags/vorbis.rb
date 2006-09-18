require "#{File.dirname __FILE__}/base"

module Autotag::Tags
  class Vorbis < Base
    
    def create
    end
    
    def read
      other_key= :_pre_tag
      starting_pos= fin.tell
      parse_vorbis_headers {|type,len|
        case type
        when 1 # padding
        when 4 # tag
          self[:_header]= true
          self[:_tool]= read_string
          item_count= read_int_le
          item_count.times do
            read_string =~ /^(.+?)=(.+)$/
            self[tag2sym($1)]= $2
          end
          other_key= :_post_tag
        else
#          self[other_key] ||= ''
#          self[other_key]<< fin.read(len)
        end
      }
      @af.ignore_header(fin.tell - starting_pos)
      metadata
    end
    
    def tag_exists?
      found= false
      parse_vorbis_headers {|type,len|
        found= true if type == 4
      }
      found
    end
    
    #--------------------------------------------------------------------------
    private
    
    def parse_vorbis_headers
      @af.seek_to_start
      return unless fin.read(4) == 'fLaC'
      last= 0
      while last == 0
        header= read_int_no
        type= (0x7F000000 & header) >> 24
        len= (0x00FFFFFF & header)
        last= (0x80000000 & header) >> 31
        pos= fin.tell
        yield(type,len) if len > 0
        fin.seek(pos + len, IO::SEEK_SET)
      end
    end
    
    def read_int_le(x=nil)
      x ||= fin.read(4)
      x.unpack('V')[0]
    end
    def read_int_no(x=nil)
      x ||= fin.read(4)
      x.unpack('N')[0]
    end
    
    def read_string
      fin.read(read_int_le)
    end
    
    def tag2sym(tag)
      TAG2SYM[tag] || tag
    end
    
    #--------------------------------------------------------------------------
    SYM2TAG= {
      :album => 'ALBUM',
      :album_type => 'ALBUMTYPE',
      :artist => 'ARTIST',
      :disc => 'DISCNUMBER',
      :genre => 'GENRE',
      :replaygain_album_gain => 'replaygain_album_gain',
      :replaygain_album_peak => 'replaygain_album_peak',
      :replaygain_track_gain => 'replaygain_track_gain',
      :replaygain_track_peak => 'replaygain_track_peak',
      :total_discs => 'TOTALDISCS',
      :total_tracks => 'TOTALTRACKS',
      :track => 'TITLE',
      :track_number => 'TRACKNUMBER',
      :year => 'DATE',
    }.deep_freeze
    TAG2SYM= SYM2TAG.invert.deep_freeze
  end
end