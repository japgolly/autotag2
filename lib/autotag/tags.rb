# encoding: utf-8
require 'autotag/ruby_ext'

Dir.chdir("#{File.dirname __FILE__}/..") {
  Dir.glob('autotag/tags/*.rb').each {|f| require f}
}

module Autotag
  module Tags
    def self.all
      @@all ||= Autotag::Tags.get_all_subclasses_of(Autotag::Tag::Base).freeze
    end
  end
end
