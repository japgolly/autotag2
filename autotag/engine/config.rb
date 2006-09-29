require 'autotag/tags'

module Autotag
  class Engine
    module Config
      include Autotag::Tags
      
      # Returns an array of regexs to match dir/file names.
      def file_patterns(type)
        FILE_PATTERNS[type] or raise
      end
      
      # Returns an array of regexs of dir/file names to ignore.
      def file_ignore_patterns(type)
        FILE_IGNORE_PATTERNS
      end
      
      # Returns an array of metadata attributes that can be ignored when
      # comparing existing tags to new tags (in order to determine whether
      # or not files are up-to-date).
      def ignorable_attributes#(tag)
        IGNORABLE_ATTRIBUTES
      end
      
      # Returns an array of metadata attributes that will be copied from
      # existing tags to new tags.
      def preservable_attributes
        PRESERVABLE_ATTRIBUTES
      end
      
      # Will eventually add format arg (ie. mp3, flac, etc)
      def tags_to_write(header)
        header ? TAGS_TO_WRITE_HEADER : TAGS_TO_WRITE_FOOTER
      end
      
      #--------------------------------------------------------------------------
      private
      
      sep= '(?: +- +|\. *)'
      FILE_PATTERNS= {
        :artist => [/^(.+)$/],
        :album  => [Regexp.new('^(.{4})'+sep+'(.+)$',nil,'U')],
        :cd     => [/^(?:cd|disc) +([a-z0-9]+)$/iu],
        :track  => [Regexp.new('^(.{2})'+sep+'(.+)\.(?:mp3|flac)$',true,'U')],
      }
      FILE_IGNORE_PATTERNS= [/^\./]
      IGNORABLE_ATTRIBUTES= [:_padding,:_tool]
      PRESERVABLE_ATTRIBUTES= [:replaygain_track_gain, :replaygain_album_gain, :replaygain_track_peak, :replaygain_album_peak]
      TAGS_TO_WRITE_HEADER= [ID3v2]
      TAGS_TO_WRITE_FOOTER= [APEv2]
      
      freeze_all_constants
      
    end # module Config
  end # class Engine
end # module Autotag
