require 'test_helper'
require 'autotag/engine'
require 'tmpdir'
require 'fileutils'

class FullTest < Autotag::TestCase
  include FileUtils
  
  def test_full
    engine_test_on('full_test'){
      # Assert we are really running on the test directory
      assert_equal tmpdir, Dir.getwd
      @e= MockEngine.new
      @e.instance_eval 'def process_root(dir,*a); @root= dir.dup; end'
      @e.instance_eval 'def root; @root; end'
      @e.run
      assert_equal tmpdir, @e.root
      # Start
      @e= MockEngine.new
      @e.run
    }
  end
  
  #----------------------------------------------------------------
  private
  
  class MockEngine < Autotag::Engine
    def puts(str=nil) end
  end
  
  def engine_test_on(dir)
    remove_tmpdir
    copy_to_tmpdir "#{test_data_dir}/#{dir}"
    Dir.chdir(tmpdir) {yield}
  ensure
    remove_tmpdir
  end
  
  def copy_to_tmpdir(dir)
    mkdir_p tmpdir
    cp_r "#{dir}/.",tmpdir
  end
  
  def remove_tmpdir
    rm_rf tmpdir
  end
  
  def tmpdir
    @@tmpdir ||= File.join(Dir::tmpdir, 'autotag_test_tmp_dir')
    @@tmpdir.dup
  end
  
end