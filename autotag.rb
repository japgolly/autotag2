module Autotag
  Dir.glob('autotag/**/*.rb').each {|f| require f}
end

Autotag::Engine.run