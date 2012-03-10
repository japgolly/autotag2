# encoding: utf-8
$:<< File.dirname(__FILE__)
$:.unshift File.expand_path('../../lib',__FILE__)

require 'rubygems'
require 'bundler'
Bundler.require :test

require 'minitest/unit'
MiniTest::Unit.autorun

require 'pp'
require 'autotag/env'

module Autotag
  require 'autotag/audio_file'
  require 'autotag/tag'
  require 'autotag/tags'

  class TestCase < MiniTest::Unit::TestCase
    include Autotag
    include Autotag::Tag::Errors

    unless $0 =~ /test\/all_tests.rb$/
      def test_do_nothing; end
    end

    protected

    def assert_hashes_equal(expected,test)
      assert_kind_of Hash, test

      # Sync encodings
      test= test.deep_clone
      test.each do |k,a|
        e= expected[k]
        if e.is_a?(String) and a.is_a?(String)
          a.force_encoding(e.encoding)
        end
      end

      # Compare
      if expected != test
        expected_keys= expected.keys.sort
        test_keys= test.keys.sort
        assert_equal expected_keys, test_keys, "Missing: #{(expected_keys-test_keys).sorted_inspect}\nHas but shouldn't have: #{(test_keys-expected_keys).sorted_inspect}"
        expected_keys.each {|k|
          e,a = expected[k],test[k]
          puts "KEY: #{k.inspect}\nEXPECTED: #{e.inspect}\nACTUAL  : #{a.inspect}" unless e == a
          assert_equal e, a
        }
        raise 'should never reach here'
      end
    end

    def assert_af_data(af, header_size, footer_size, audio_size, start_of_audio, end_of_audio)
      assert_equal audio_size, af.size
      assert_equal header_size, af.size_of_header if header_size
      assert_equal footer_size, af.size_of_footer if footer_size
      assert_equal start_of_audio.to_bin, af.read_all[0..(start_of_audio.size-1)] if start_of_audio
      assert_equal end_of_audio.to_bin, af.read_all[(-end_of_audio.size)..-1] if end_of_audio
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

    def filename2utf8(filename)
      filename.encode('utf-8')
    end

    def utf82filename(filename)
      filename
    end

    def get_file_contents(filename)
      File.read(filename,nil,nil,encoding: 'binary')
    end

  end
end

class String
  def h
    s= eval '"'+(self.strip.split(/ +/).map{|x| "\\x#{x}"}.join)+'"'
    s.to_bin
  end
end

require 'autotag/engine/ui'
class Autotag::Engine::UI
  alias :old_quiet_mode :quiet_mode
  def quiet_mode() true end
end
