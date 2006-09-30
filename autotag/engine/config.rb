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
      
      # Returns a list of file extentions of processible audio files.
      def supported_audio_formats
        SUPPORTED_AUDIO_FORMATS
      end
      
      # Will eventually add format arg (ie. mp3, flac, etc)
      def tags_to_write(format,header)
        (header ? TAGS_TO_WRITE_HEADER[format] : TAGS_TO_WRITE_FOOTER[format]) || []
      end
      
      #--------------------------------------------------------------------------
      private
      
      sep= '(?: +- +|\. *)'
      FILE_PATTERNS= {
        :artist => [/^(.+)$/],
        :album  => [Regexp.new('^(.{4})'+sep+'(.+)$',nil,'U')],
        :cd     => [Regexp.new('^(?:cd|disc) +([a-z0-9]+)(?:'+sep+'(.+))?$',true,'U')],
        :track  => [Regexp.new('^(.{2})'+sep+'(.+)$',true,'U')],
      }
      FILE_IGNORE_PATTERNS= [/^\./]
      IGNORABLE_ATTRIBUTES= [:_padding,:_tool]
      # TODO Rename :_other_tags to :_audio_header or somethin
      PRESERVABLE_ATTRIBUTES= [:replaygain_track_gain, :replaygain_album_gain, :replaygain_track_peak, :replaygain_album_peak, :_other_tags]
      TAGS_TO_WRITE_HEADER= {'mp3' => [ID3v2], 'flac' => [Vorbis]}
      TAGS_TO_WRITE_FOOTER= {'mp3' => [APEv2]}
      SUPPORTED_AUDIO_FORMATS= ['mp3','flac']
      
      freeze_all_constants
      
    end # module Config
  end # class Engine
end # module Autotag
