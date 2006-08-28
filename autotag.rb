module Autotag
  VERSION= '2_DEV'
  Dir.glob('autotag/**/*.rb').each {|f| require f}
end

Autotag::Engine.run