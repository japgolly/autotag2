require 'autotag/app_info'
require 'autotag/ruby_ext'
require 'autotag/unicode'

module Autotag::Tag
  
  # This module includes a number of tag-related error classes.
  module Errors
    class TagError < RuntimeError; end
    class CreateNotSupported < TagError; end
    class InvalidTag < TagError; end
    class TagNotFound < TagError; end
  end


  # This module contains methods that are only meant to be called
  # at class-level in the definition of classes that extend Tag::Base.
  module DSL
    def set_defaults(d)
      class_variable_set :@@defaults, d.deep_clone.deep_freeze
      class_eval 'def get_defaults; @@defaults; end'
    end
  end
  
  
  # This class is the base class that all tag readers/writers should extend.
  # 
  # The following keys are used in the metadata hash:
  #   :album
  #   :album_type
  #   :artist
  #   :disc
  #   :disc_title
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
  class Base
    include Autotag::Unicode
    include Errors
    extend DSL
    
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
    
    def self.has_albumart_support?
      false
    end
    
    def create
      raise CreateNotSupported
    end
    
    def get_defaults
      {}
    end
    
    def set_metadata(m)
      @metadata.clear
      @metadata.merge! m
      self
    end
    
    #==========================================================================
    protected
    attr_reader :metadata
    
    def apply_defaults!
      @metadata |= get_defaults
    end
    
    def fin
      @af.fin
    end
    
    def get_items_without_params
      @metadata.reject{|k,v| k.to_s[0] == '_'[0]}
    end
    
    def merge_tag_values!(collection, key1, key2, seperator, key1_default_value=nil)
      if collection.has_key?(key2)
        collection[key1]= "#{collection[key1] || key1_default_value}#{seperator}#{collection.delete key2}"
      end
    end
    
    # seperator must be exactly 1 character
    def split_merged_tag_values!(key1, key2, seperator)
      if self[key1] =~ Regexp.new("([^#{seperator}]+)#{seperator}([^#{seperator}]+)")
        self[key1],self[key2]= $1,$2
      end
    end
    
    def value_or_nil(v)
      (v.nil? || v == '') ? nil : v
    end
  end # class Base
end
