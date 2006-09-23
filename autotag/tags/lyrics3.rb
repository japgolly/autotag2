require 'autotag/tag'

module Autotag
  module Tags
    class Lyrics3 < Tag::Base
      
      def tag_exists? 
        read_tag_version != nil
      end
      
      def read
        self[:_version]= read_tag_version
        raise TagNotFound unless self[:_version]
        send "read_v#{self[:_version]}"
        metadata
      end
      
      #--------------------------------------------------------------------------
      private
      
      def read_tag_version
        @af.seek_to_end 9
        case fin.read(9)
        when 'LYRICSEND' then 1
        when 'LYRICS200' then 2
        else nil
        end
      end
      
      def read_v1
        # Locate the Lyrics3v1 Tag by seeking to the end tag first.
        # The end tag is located either 9 bytes from the end of a file with no ID3v1 Tag, or 137 bytes from the end of a file containing ID3v1 Tag.
        # Once the end tag is located seek back 5100 bytes and then search forward for the begin tag.
        @af.seek_to_end [5100,@af.size].sort.first
        raise InvalidTag, 'Start of Lyrics3 v1 tag not found' unless fin.read(5200) =~ /(LYRICSBEGIN.+$)/
        self[:_tag]= $1
        @af.ignore_footer self[:_tag].size
      end
      
      def read_v2
        # 1. Read the 9 bytes before the ID3v1 tag, if any. Those 9 bytes must be LYRICS200.
        # 2. Read the previous 6 bytes, which are text digits that, when interpreted as a number, give you the total number of bytes in the Lyrics3 v2.00 tag field, including the LYRICSBEGIN header, but not including the trailing Tag size and LYRICS200 end string.
        # 3. Seek back in the file from the beginning of the tag size field, the number of bytes read in the previous step.
        # 4. Read 11 bytes forward. These 11 bytes must read LYRICSBEGIN.
        # 5. Start reading fields until you have read the number of bytes retrieved in step 2. 
        @af.seek_to_end 9 + 6
        size_text= fin.read(6)
        raise InvalidTag, 'Lyrics3 v2 size descriptor invalid' unless size_text =~ /^\d+$/
        tag_size= 9 + 6 + size_text.to_i
        self[:_tag]= @af.read_and_ignore_footer(tag_size)
        raise InvalidTag, 'Lyrics3 v2 missing header' unless self[:_tag] =~ /^LYRICSBEGIN/
      end
      
    end
  end
end
