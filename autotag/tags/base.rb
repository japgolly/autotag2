require 'autotag/app_info'
require 'autotag/unicode'

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
    include Autotag::Unicode
    
    def initialize(audiofile)
      @af= audiofile
      @metadata= {}
    end
    
    def [](k)
      @metadata[k]
    end
    
    def []=(k,v)
      if v.nil?
        @metadata.delete k
      else
        @metadata[k]= v
      end
    end
    
    def set_metadata(m)
      @metadata.clear
      @metadata.merge! m
      self
    end
    
    #--------------------------------------------------------------------------
    protected
    attr_reader :metadata
    
    def fin
      @af.fin
    end
    
    def get_items_without_params
      @metadata.reject{|k,v| k.to_s[0] == '_'[0]}
    end
    
    def value_or_nil(v)
      (v.nil? || v == '') ? nil : v
    end
    
  end
end