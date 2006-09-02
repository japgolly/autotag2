require 'iconv'

# The following keys are used in the metadata hash:
#   :album
#   :album_type
#   :artist
#   :disc
#   :genre
#   :replaygain_album_gain
#   :replaygain_album_peak
#   :replaygain_track_gain
#   :replaygain_track_peak
#   :total_discs
#   :total_tracks
#   :track
#   :track_number
#   :year
module Autotag::Tags
  class Base
    
    def initialize(audiofile)
      @af= audiofile
      @metadata= {}
    end
    
    def [](k)
      @metadata[k]
    end
    
    protected
    attr_reader :metadata
    
    def []=(k,v)
      if v.nil?
        @metadata.delete k
      else
        @metadata[k]= v
      end
    end
    
    def convert_utf16(str,big_endian)
      Iconv.iconv('utf-8', big_endian ?'utf-16be':'utf-16le', str)[0]
    end
    
    def fin
      @af.fin
    end
    
    def value_or_nil(v)
      (v.nil? || v == '') ? nil : v
    end
    
  end
end