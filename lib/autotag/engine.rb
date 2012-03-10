# encoding: utf-8
$KCODE= 'u'
require 'autotag/engine/core'

module Autotag
  class Engine
    def self.run(*args)
      new(*args).run
    end
  end
end
