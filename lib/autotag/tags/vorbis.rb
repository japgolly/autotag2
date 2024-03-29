# encoding: utf-8
require 'autotag/tag'

# Params:
# * :_non_metadata_tags
# * :_padding
# * :_tool
module Autotag
  module Tags
    class Vorbis < Tag::Base

      def create
        apply_defaults!
        x= FLAC_HEADER_ID.dup.to_bin

        # Add other tags (clearing the last_tag bit)
        if self[:_non_metadata_tags]
          self[:_non_metadata_tags].each {|t|
            descriptor,content = read_int_no(t[0..3]),t[4..-1]
            d= read_tag_descriptor(descriptor)
            x<< create_tag(d[:type],false,content) unless d[:type] == TAG_TYPE_PADDING || d[:type] == TAG_TYPE_METADATA
          }
        end

        # Add metadata
        items= get_items_without_params
        x<< create_metadata_tag(items)

        # Add padding
        x<< create_tag(TAG_TYPE_PADDING,true,"\0"*self[:_padding])

        x
      end

      def read
        @af.seek_to_start
        starting_pos= fin.tell
        self[:_header]= true
        parse_vorbis_headers {|type,len,descriptor|
          case type
          when TAG_TYPE_PADDING
            self[:_padding] ||= 0
            self[:_padding] += len
          when TAG_TYPE_METADATA
            self[:_tool]= read_string
            item_count= read_int_le
            item_count.times do
              read_string =~ /^(.+?)=(.+)$/
              self[tag2sym($1)]= $2
            end
          else
            self[:_non_metadata_tags] ||= []
            self[:_non_metadata_tags]<< (create_int_no(descriptor) + fin.read(len))
          end
        }
        @af.ignore_header(fin.tell - starting_pos)
        metadata
      end

      def tag_exists?
        parse_vorbis_headers {|type,len,descriptor|
          return true
        }
        false
      end

      #--------------------------------------------------------------------------
      private

      def create_int_le(i)
        [i].pack('V')
      end
      def create_int_no(i)
        [i].pack('N')
      end

      def create_metadata_tag(items)
        t= create_string(self[:_tool])
        t<< create_int_le(items.size)
        items.keys.sort.each {|k| t<< create_string("#{sym2tag k}=#{items[k]}")}
        create_tag(TAG_TYPE_METADATA,false,t)
      end

      def create_string(str)
        create_int_le(str.bytes.count) + str.to_bin
      end

      def create_tag(type,last,content)
        header= content.bytes.count
        header |= (type << 24)
        header |= (1 << 31) if last
        create_int_no(header) + content.to_bin
      end

      def sym2tag(sym)
        SYM2TAG[sym] || sym.to_s
      end

      #--------------------------------------------------------------------------

      def parse_vorbis_headers
        @af.seek_to_start
        return unless fin.read(4) == FLAC_HEADER_ID
        last= 0
        while last == 0
          descriptor= read_int_no
          d= read_tag_descriptor(descriptor)
          type,len,last= d[:type],d[:len],d[:last]
          pos= fin.tell
          yield(type,len,descriptor) if len > 0
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

      def read_tag_descriptor(x)
        {
          :type => (0x7F000000 & x) >> 24,
          :len => (0x00FFFFFF & x),
          :last => (0x80000000 & x) >> 31,
        }
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
        :album_artist => 'ALBUM ARTIST',
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
      }
      TAG2SYM= SYM2TAG.invert

      FLAC_HEADER_ID= 'fLaC'
      TAG_TYPE_METADATA= 4
      TAG_TYPE_PADDING= 1

      set_defaults :_padding => 1024, :_tool => Autotag::TITLE
      freeze_all_constants
    end
  end
end
