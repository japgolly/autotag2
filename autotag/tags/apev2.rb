require 'autotag/tag'

# Params:
# none
module Autotag
  module Tags
    class APEv2 < Tag::Base
      
      def create
        items= get_items_without_params
        tag_body= create_body(items)
        tag_header= create_header(items.size, tag_body.size, true)
        tag_footer= create_footer(items.size, tag_body.size, true)
        tag_header + tag_body + tag_footer
      end
  
      def read
        bof_read if bof_tag_exists?
        eof_read if eof_tag_exists?
        metadata
      end
      
      def tag_exists?
        bof_tag_exists? || eof_tag_exists?
      end
      
      #--------------------------------------------------------------------------
      private
      
      def create_header(item_count, body_size, has_footer)
        create_header_or_footer(item_count, body_size, true, has_footer, true)
      end
      
      def create_footer(item_count, body_size, has_header)
        create_header_or_footer(item_count, body_size, has_header, true, false)
      end
      
      def create_header_or_footer(item_count, body_size, has_header, has_footer, create_header)
        tag_size_minus_header= body_size + (has_footer ? 32 : 0)
        flags= 0
        flags= flags.set_bit(31,has_header)
        flags= flags.set_bit(30,!has_footer)
        flags= flags.set_bit(29,create_header)
        x= 'APETAGEX'
        x<< create_int(2000)
        x<< create_int(tag_size_minus_header)
        x<< create_int(item_count)
        x<< create_int(flags)
        x<< create_int(0)
        x<< create_int(0)
      end
      
      def create_body(items)
        x= ''
        items.keys.sort.each {|k| x<< create_item(k,items[k])}
        x
      end
      
      def create_item(k,v)
        x= create_int(v.length) # len
        x<< create_int(0)       # flags
        x<< "#{sym2tag(k)}\0"   # key
        x<< v                   # value
      end
      
      def create_int(i)
        [i].pack('L')
      end
      
      def sym2tag(sym)
        SYM2TAG[sym] || sym.to_s
      end
      
      #--------------------------------------------------------------------------
      
      def bof_tag_exists?
        @af.seek_to_start 32
        fin.read(8) == 'APETAGEX' && read_int == 2000
      end
      def eof_tag_exists?
        @af.seek_to_end 32
        fin.read(8) == 'APETAGEX' && read_int == 2000
      end
      
      def bof_read
        @af.seek_to_start 32
        info= read_tag_info(fin.read(32))
        @af.ignore_header(32) if info[:has_header]
        @af.ignore_header(info[:size])
        @af.seek_to_start
        read_tag_content(info)
        self[:_header]= true
      end
      def eof_read
        @af.seek_to_end 32
        info= read_tag_info(fin.read(32))
        @af.ignore_footer(info[:size])
        @af.seek_to_end
        @af.ignore_footer(32) if info[:has_header]
        read_tag_content(info)
        self[:_footer]= true
      end
      
      def read_tag_info(data)
        flags= read_int(data[20..23])
        {
          :items => read_int(data[16..19]),
          :size => read_int(data[12..15]),
          :has_header => flags[31]==1,
          :has_footer => flags[30]==0,
          :read_only => flags[0]==1,
        }
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
      
      def tag2sym(tag)
        TAG2SYM[tag.upcase] || tag.upcase
      end
      
      #--------------------------------------------------------------------------
      SYM2TAG= {
        :album => 'Album',
        :album_type => 'Albumtype',
        :artist => 'Artist',
        :disc => 'Disc',
        :genre => 'Genre',
        :replaygain_album_gain => 'replaygain_album_gain',
        :replaygain_album_peak => 'replaygain_album_peak',
        :replaygain_track_gain => 'replaygain_track_gain',
        :replaygain_track_peak => 'replaygain_track_peak',
        :total_discs => 'Totaldiscs',
        :total_tracks => 'Totaltracks',
        :track => 'Title',
        :track_number => 'Track',
        :year => 'Year',
      }.deep_freeze
      TAG2SYM= {}
      SYM2TAG.each{|s,t| TAG2SYM[t.upcase]= s}
      TAG2SYM.deep_freeze
    end
  end
end
