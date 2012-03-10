# encoding: utf-8
require 'autotag/tag'

# Params:
# * :_version
module Autotag
  module Tags
    class ID3v1 < Tag::Base

      def tag_exists?
        @af.seek_to_end 128
        fin.read(3) == 'TAG'
      end

      def read
        @tag= @af.read_and_ignore_footer(128)
        self[:_version]= (@tag[125] == 0 ? 1 : 0)
        self[:track]= read_value(3,32)
        self[:artist]= read_value(33,62)
        self[:album]= read_value(63,92)
        self[:year]= read_value(93,96)
        if self[:_version] == 1
          self['Comment']= read_value(97,124)
          self[:track_number]= @tag[126].to_i.to_s
          self[:genre]= @tag[127] unless @tag[127] == 255
        else
          self['Comment']= read_value(97,127)
        end
        metadata
      end

      #--------------------------------------------------------------------------
      private

      def read_value(from,to)
        value_or_nil @tag[from..to].gsub(%r{[ \0]*$},'')
      end

    end
  end
end
