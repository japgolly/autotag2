require 'autotag/tags'

module Autotag
  class Engine
    module Config
      include Autotag::Tags
      
      # Returns an array of regexs to match dir/file names.
      def file_patterns(type)
        case type
        when :artist
          [/^(.+)$/u]
        when :album
          [
            /^(.{4}) - (.+)$/u,
            /^(.{4})\. (.+)$/u,
          ]
        when :track
          [
            /^(.{2}) - (.+)\.(?:mp3|flac)$/iu,
            /^(.{2})\. (.+)\.(?:mp3|flac)$/iu,
          ]
        else raise
        end
      end
      
      # Returns an array of regexs of dir/file names to ignore.
      def file_ignore_patterns(type)
        x= [/^\./]
        case type
        when :artist
        when :album
        when :track
        else raise
        end
        x
      end
      
      # Returns an array of metadata attributes that can be ignored when
      # comparing existing tags to new tags (in order to determine whether
      # or not files are up-to-date).
      def ignorable_attributes#(tag)
        [:_padding,:_tool]
      end
      
      # Returns an array of metadata attributes that will be copied from
      # existing tags to new tags.
      def preservable_attributes
        [:replaygain_track_gain, :replaygain_album_gain, :replaygain_track_peak, :replaygain_album_peak]
      end
      
      # TODO Add format arg (ie. mp3, flac, etc)
      def tags_to_write(header)
        if header
          [ID3v2]
        else
          [APEv2]
        end
      end
      
    end # module Config
  end # class Engine
end # module Autotag
