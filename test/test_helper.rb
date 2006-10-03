require 'autotag/ruby_ext'
require 'test/unit'
require 'pp'

module Autotag
  require 'autotag/audio_file'
  require 'autotag/tag'
  require 'autotag/tags'

  class TestCase < Test::Unit::TestCase
    include Autotag
    include Autotag::Tag::Errors
    
    protected
    
    def assert_hashes_equal(expected,test)
      assert_kind_of Hash, test
      if expected != test
        expected_keys= expected.keys
        test_keys= test.keys
        assert_equal expected_keys, test_keys, "Missing: #{(expected_keys-test_keys).sorted_inspect}\nHas but shouldn't have: #{(test_keys-expected_keys).sorted_inspect}"
        expected_keys.each {|k|
          puts "KEY: #{k.inspect}\nEXP.: #{expected[k].inspect}\nTEST: #{test[k].inspect}" unless expected[k] == test[k]
          assert_equal expected[k], test[k]
        }
        raise 'should never reach here'
      end
    end
    
    def assert_af_data(af, header_size, footer_size, audio_size, start_of_audio, end_of_audio)
      assert_equal audio_size, af.size
      assert_equal header_size, af.size_of_header if header_size
      assert_equal footer_size, af.size_of_footer if footer_size
      assert_equal start_of_audio, af.read_all[0..(start_of_audio.size-1)] if start_of_audio
      assert_equal end_of_audio, af.read_all[(-end_of_audio.size)..-1] if end_of_audio
    end
    
    def assert_valid_metadata(m)
      assert !(m[:_header] && m[:_footer]), 'Tag is marked as both header and footer.'
      assert m[:_header] || m[:_footer], 'Tag is not marked as either header or footer.'
    end
    
    def tag_call(klass,method,source,type=:file)
      r= nil
      AudioFile.send("open_#{type}", "#{test_data_dir}/#{source}") do |af|
        r= klass.new(af).send(method)
      end
      r
    end
    
    def test_data_dir
      'test/data'
    end
    
    def utf82filename(filename)
      @iconv ||= Iconv.new('shift-jis','utf-8')
      @iconv.iconv(filename)
    end
    
  end
end

class String
  def h
    eval '"'+(self.strip.split(/ +/).map{|x| "\\x#{x}"}.join)+'"'
  end
end

require 'autotag/engine/ui'
class Autotag::Engine::UI
  alias :old_put :put
  def put(str=nil) end
  def puts(str=nil) end
end
