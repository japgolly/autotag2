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
    
    def fin
      @af.fin
    end
    
    def value_or_nil(v)
      (v.nil? || v == '') ? nil : v
    end
    
  end
end