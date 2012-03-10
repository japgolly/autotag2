# encoding: utf-8
require 'test/test_helper'
require 'autotag/engine'
require 'tmpdir'
require 'fileutils'

module Autotag
  module IntegrationTestSupport
    include FileUtils
    include Autotag::Tags
    
    def assert_file(file, audio_size, start_of_audio, end_of_audio, metadata_base, metadata_per_tag)
      assert_file_metadata(file, metadata_base, metadata_per_tag) do |af|
        assert_af_data af, nil, nil, audio_size, start_of_audio, end_of_audio
      end
    end
    
    def assert_file_metadata(file, metadata_base, metadata_per_tag)
      expected_tags= {}
      metadata_per_tag.each {|tag,data|
        expected_tags[tag]= metadata_base.merge(data)
      }
      # open file
      AudioFile.open_file(file) do |af|
        # read tags
        t= af.read_tags
        # check tags
        t.each_value {|m|
          assert_valid_metadata m
          m.delete :_padding
        }
        assert_hashes_equal expected_tags, t
        # yield
        yield(af) if block_given?
      end
    end
    
    def assert_file_changed(filename)
      info= File.stat(utf82filename(filename))
      modified_sec_ago= Time.now - info.mtime
      assert modified_sec_ago <= 3, "File was supposed to be modified but wasn't.\nFile: \"#{filename}\""
    end
    
    def assert_file_unchanged(filename, size=nil)
      info= File.stat(utf82filename(filename))
      modified_sec_ago= Time.now - info.mtime
      assert modified_sec_ago > 3, "File wasn't supposed to be modified.\nFile: \"#{filename}\""
      assert_equal size, info.size if size
    end
    
    def assert_runtime_options(*opt)
      exp= {:debug=>nil,:force=>false,:pretend=>false,:quiet=>false}
      opt.each{|o| exp[o]= true}
      assert_equal exp, @e.runtime_options
    end
    
    def engine_test_on(dir, change_file_dates)
      remove_tmpdir
      copy_to_tmpdir "#{test_data_dir}/#{dir}", change_file_dates
      Dir.chdir(tmpdir) {yield}
    ensure
      remove_tmpdir
    end
    
    def copy_to_tmpdir(dir, change_file_dates)
      if change_file_dates
        mkdir_p tmpdir
        Dir.chdir(dir) {
          orig_files= Dir.glob('**/*.*')
          new_files= orig_files.map{|f|"#{tmpdir}/#{f}"}
          dirmap= {}
          orig_files.map{|f| (dirmap[File.dirname(f)] ||= [])<< f}
          dirmap.each {|dir,files|
            mkdir_p "#{tmpdir}/#{dir}" unless dir=='.'
            files.each {|f| cp f, "#{tmpdir}/#{f}"}
          }
          # I don't know why :preserve doesn't work :(
          fake_time= Time.now - 3600*24*365*5
          File.utime(fake_time,fake_time,*new_files)
        }
      else
        cp_r "#{dir}/.", tmpdir
      end
    end
    
    def new_engine_instance(*args)
      e= Engine.new(*args)
      e.instance_eval 'def runtime_options; @runtime_options; end'
      e.instance_eval 'def ui; @ui; end'
      e
    end
    
    def remove_tmpdir
      rm_rf tmpdir
      if File.exists?(tmpdir)
        UnicodeIO.chdir(tmpdir) do
          UnicodeIO.glob(-1).each {|f| UnicodeIO.delete(f) if UnicodeIO.file?(f)}
        end
        rm_rf tmpdir
      end
    end
    
    def tmpdir
      @@tmpdir ||= File.join(Dir.tmpdir, 'autotag_test_tmp_dir').freeze
      @@tmpdir
    end

  end
end