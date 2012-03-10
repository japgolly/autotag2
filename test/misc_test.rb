# encoding: utf-8
require_relative 'test_helper'
require 'autotag/unicode_io'

class MiscTest < Autotag::TestCase
  include Autotag::UnicodeIO

  def test_unicodeio_glob
    ac_files= ["code_stats.rb", "Gemfile", "Gemfile.lock"]
    ac_files<< "CHANGELOG" if Autotag::Utils::case_insensitive_filenames?
    assert_equal ac_files.sort, glob(0,nil,"{c,G}*").sort
    assert_equal ["code_stats.rb"], glob(0,nil,'*.rb')
    assert_equal ["test/engine_test.rb"], glob(1,nil,'e*.rb')
    assert_equal ["lib/autotag/engine.rb"], glob(0,'lib/autotag','e*.rb')
    assert_equal ["lib/autotag/engine/misc.rb", "test/misc_test.rb"], glob(-1,nil,'mi*.rb')
    assert_equal [], glob(0,nil,'mi*.rb')
    assert_equal ["test/misc_test.rb"], glob(1,nil,'mi*.rb')
    assert_equal ["lib/autotag/engine/misc.rb", "test/misc_test.rb"], glob(3,nil,'mi*.rb')
  end

  def test_unicodeio_file_dir_bools
    assert file?('bin/autotag')
    assert !directory?('bin/autotag')
    assert !file?('lib/autotag')
    assert directory?('lib/autotag')
  end

end
