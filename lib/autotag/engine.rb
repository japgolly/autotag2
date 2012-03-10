# encoding: utf-8
require 'autotag/engine/core'

module Autotag
  class Engine
    def self.run(*args)
      new(*args).run
    end
  end
end
