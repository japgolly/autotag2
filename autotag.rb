# encoding: utf-8
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'autotag/engine'

Autotag::Engine.run(*ARGV)