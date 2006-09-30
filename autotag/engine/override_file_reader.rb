require 'autotag/unicode'
require 'autotag/engine/misc'

module Autotag
  class Engine
    # This module provides methods that read text files containing
    # info about songs in the current and sub directories. These
    # files allow the user to override the file or directory name
    # and manually specify certain tag fields.
    module OverrideFileReader
      include Unicode
      
      def override_file_names
        OVERRIDE_FILE_NAMES
      end
      
      # level= :artist # /Nevermore/autotag.txt
      # level= :album  # /Nevermore/2003 - Enemies Of Reality/autotag.txt
      def read_overrides(level)
        override_file_names.each do |filename|
          read_unicode_file(filename).split(/[\r\n]+/).each {|l|
            unicode_trim! l
            i= false
            i ||= extract_field_override(l,:artist,'ARTIST')
            if level == :album
              i ||= extract_field_override(l,:album,'ALBUM')
              i ||= extract_field_override(l,:albumtype,'ALBUMTYPE')
              i ||= extract_track_override(l)
            end
          } if File.exists?(filename)
        end
      end
      
      #--------------------------------------------------------------------------
      private
      
      def extract_field_override(line_of_text, field, str)
        if line_of_text =~ Regexp.new("^#{str}[:：](.+)$",0,'U')
          value= unicode_trim($1)
          unless value == ''
            @metadata[field]= value
            return true
          end
        end
        false
      end
      
      def extract_track_override(line_of_text)
        if line_of_text.tr('０-９','0-9') =~ /^(\d{1,3})[.．:：](.+)$/
          track,value= $1,unicode_trim($2)
          unless value == ''
            remove_leading_zeros! track
            @metadata[:_track_overrides] ||= {}
            @metadata[:_track_overrides][track]= value
            return true
          end
        end
        false
      end
      
      OVERRIDE_FILE_NAMES= ['autotag.txt']
      
      freeze_all_constants
    
    end # module OverrideFileReader
  end # class Engine
end # module Autotag
