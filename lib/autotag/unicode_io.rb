# encoding: utf-8
require 'autotag/unicode'
require 'autotag/utils'

case Autotag::Utils::get_os
when :windows
  require 'autotag/unicode_io/windows'
else
  require 'autotag/unicode_io/ruby'
end
