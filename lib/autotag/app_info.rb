# encoding: utf-8
module Autotag
  TITLE= "Golly's AutoTagger"
  VERSION= File.read(File.expand_path('../../../.version',__FILE__)).chomp
  COPYRIGHT= "Copyright (c) 2006-#{Time.now.year} David Barri. All rights reserved."

  TITLE_AND_VERSION= "#{TITLE} v#{VERSION}"
end
