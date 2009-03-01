require 'autotag/tags'

module Autotag
  class Engine
    module Config
      include Autotag::Tags
      
      def debug_output_filename
        'autotag_debug.txt'
      end
      
      # Returns the album type value for albums that don't have a 
      def default_album_type
        nil
      end
      
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
      
      # Returns a pattern that matches year values when the actual year is unknown.
      def null_year_pattern
        NULL_YEAR_PATTERN
      end
      
      # Returns an array of metadata attributes that will be copied from
      # existing tags to new tags.
      def preservable_attributes
        PRESERVABLE_ATTRIBUTES
      end
      
      # Returns a map of album types. album type value => array of collection directories
      def supported_album_types
        SUPPORTED_ALBUM_TYPES
      end
      
      # Returns a list of file extentions of processible audio files.
      def supported_audio_formats
        SUPPORTED_AUDIO_FORMATS
      end
      
      # Will eventually add format arg (ie. mp3, flac, etc)
      def tags_to_write(format,header)
        (header ? TAGS_TO_WRITE_HEADER[format] : TAGS_TO_WRITE_FOOTER[format]) || []
      end
      
      def useless_file_patterns
        USELESS_FILE_PATTERNS
      end
      
      def va_artist_pattern
        VA_ARTIST_PATTERN
      end
      
      def va_filename_patterns
        VA_FILENAME_PATTERNS
      end

      def va_artist_tag
        VA_ARTIST_TAG
      end
      
      #--------------------------------------------------------------------------
      private
      
      sep= '(?: +- +|\. *)'
      FILE_PATTERNS= {
        :artist => [/^(.+)$/u],
        :album  => [Regexp.new('^(.{4})'+sep+'(.+)$',nil,'U')],
        :cd     => [Regexp.new('^(?:cd|disc) +([a-z0-9]+)(?:'+sep+'(.+))?$',true,'U')],
        :track  => [Regexp.new('^(.{1,3})'+sep+'(.+)$',true,'U')],
      }
      FILE_IGNORE_PATTERNS= [/^\./u]
      IGNORABLE_ATTRIBUTES= [:_padding,:_tool]
      PRESERVABLE_ATTRIBUTES= [
        :replaygain_track_gain, :replaygain_track_peak,
        :replaygain_album_gain, :replaygain_album_peak,
        :_non_metadata_tags,
      ]
      TAGS_TO_WRITE_HEADER= {'mp3' => [ID3v2], 'flac' => [Vorbis]}
      TAGS_TO_WRITE_FOOTER= {'mp3' => [APEv2]}
      SUPPORTED_AUDIO_FORMATS= ['mp3','flac']
      SUPPORTED_ALBUM_TYPES= {
      #TODO More SUPPORTED_ALBUM_TYPES
      #Mini Albums
      #Remix Albums
        nil => ['Albums'],
        'Bonus' => ['Bonus CDs', 'Bonus Discs'],
        'Bootleg' => ['Bootlegs'],
        'Compilation' => ['Compilations'],
        'Demo' => ['Demos'],
        'Fan Club' => ['Fan Club CDs'],
        'Live Album' => ['Live Albums'],
        'Other' => ['Other'],
        'Rarities' => ['Rarities'],
        'Remastered' => ['Remastered'],
        'Single' => ['Singles'],
      }
      USELESS_FILE_PATTERNS= [/\.(?:jpe?g|gif|bmp|mpe?g|avi|mov|wmv|divx|asf|xvid|nfo)$/iu]
      VA_ARTIST_PATTERN= %r!^(?:various(?: artists?)?|v/?a|v / a)$!iu
      VA_FILENAME_PATTERNS= [%r!^(.+?)[ 　](?://|--)[ 　](.+)$!u, /^(.+?)[ 　]-[ 　](.+)$/u]
      VA_ARTIST_TAG= 'Various Artists'
      NULL_YEAR_PATTERN= /^[a-z]{4}$/iu
      
      # File extentions should be case-insensitive on Windows
      if Autotag::Utils::get_os == :windows
        asd= lambda{|h| n= {}; h.each{|k,v|n[k.downcase]=v}; h.clear; h.merge! n}
        asd.call TAGS_TO_WRITE_HEADER
        asd.call TAGS_TO_WRITE_FOOTER
        SUPPORTED_AUDIO_FORMATS.each_index{|i|SUPPORTED_AUDIO_FORMATS[i].downcase!}
      end
      
      freeze_all_constants
      
    end # module Config
  end # class Engine
end # module Autotag
