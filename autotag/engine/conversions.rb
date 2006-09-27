module Autotag
  class Engine
    module Conversions
    
      def filename2human_text(str)
        x= str.dup
        x.gsub! %r{ _ }, ' / '      # "aaa _ bbb" --> "aaa / bbb"
        x.gsub! %r{_$}, '?'         # "aaa_" --> "aaa?"
        x.gsub! %r{(?!= )_ }, ': '  # "aaa_ bbb" --> "aaa: bbb"
        x.gsub! "''", '"'           # "Take The ''A'' Train" --> "Take The "A" Train"
        x
      end
    
    end # module Conversions
  end # class Engine
end # module Autotag
