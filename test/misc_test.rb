require 'test/test_helper'
require 'autotag/unicode_io'

class MiscTest < Autotag::TestCase
  include Autotag::UnicodeIO
  
  def test_unicodeio_glob
    assert_equal ["code_stats.rb", "autotag", "autotag.rb"].sort, glob(0,nil,"{a,c}*").sort
    assert_equal ["autotag.rb", "code_stats.rb"], glob(0,nil,'*.rb')
    assert_equal ["autotag/engine.rb", "test/engine_test.rb"], glob(1,nil,'e*.rb')
    assert_equal ["autotag/engine.rb"], glob(0,'autotag','e*.rb')
    assert_equal ["autotag/engine/misc.rb", "test/misc_test.rb"], glob(-1,nil,'mi*.rb')
    assert_equal [], glob(0,nil,'mi*.rb')
    assert_equal ["test/misc_test.rb"], glob(1,nil,'mi*.rb')
    assert_equal ["autotag/engine/misc.rb", "test/misc_test.rb"], glob(2,nil,'mi*.rb')
  end
  
  def test_unicodeio_file_dir_bools
    assert file?('autotag.rb')
    assert !directory?('autotag.rb')
    assert !file?('autotag')
    assert directory?('autotag')
  end
  
end