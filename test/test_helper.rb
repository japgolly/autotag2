require 'pp'

module Autotag
  require 'autotag/audio_file'
  require 'autotag/tags'

  class TestCase < Test::Unit::TestCase
    include Autotag
    
    protected
    
    def assert_hashes_equal(expected,test)
      assert_kind_of Hash, test
      if expected != test
        expected_keys= expected.keys
        test_keys= test.keys
        assert_equal expected_keys, test_keys, "Missing: #{(expected_keys-test_keys).inspect}, Has but shouldn't have: #{(test_keys-expected_keys).inspect}"
        expected_keys.each {|k|
          assert_equal expected[k], test[k]
        }
        raise 'should never reach here'
      end
    end
    
    def tag_call(klass,method,file)
      r= nil
      AudioFile.open("#{test_data_dir}/#{file}") do |af|
        r= klass.new(af).send(method)
      end
      r
    end
    
    def test_data_dir
      'test/data'
    end
    
  end
end
