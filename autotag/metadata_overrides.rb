require 'autotag/unicode'

module Autotag
  module MetadataOverrides
    include Unicode
    
    def read_metadata_overrides(level)
      metadata_override_file_names.each {|filename|
        read_unicode_file(filename).split(/[\r\n]/).each {|l|
          unicode_trim! l
          i= false
          i ||= extract_field_override(l,:artist,'ARTIST')
          if level == :album
            i ||= extract_field_override(l,:album,'ALBUM')
            i ||= extract_field_override(l,:albumtype,'ALBUMTYPE')
            i ||= extract_track_override(l)
          end
        } if File.exists?(filename)
      }
    end
    
    #--------------------------------------------------------------------------
    private
    
    def extract_field_override(line_of_text, field,str)
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
        track,value= $1.to_i,unicode_trim($2)
        unless value == ''
          @metadata[track]= value
          return true
        end
      end
      false
    end
    
    def metadata_override_file_names
      @metadata_override_file_names ||= ['autotag.txt']
    end
    
  end
end
