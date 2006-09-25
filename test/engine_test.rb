require 'test_helper'
require 'autotag/engine'

class EngineTest < Autotag::TestCase
  
  class MockEngine < Autotag::Engine
    attr_accessor :metadata
    attr_writer :textfile
    def metadata_override_file_names; [@textfile] end
    def puts(str=nil) end
  end
  
  def setup
    @e= MockEngine.new
    @e.metadata= {}
  end
  
  #----------------------------------------------------------------
  
  def test_process_file_or_directory_name
    [
      ['aaa _ bbb', 'aaa / bbb'],
      ['aaa_ bbb', 'aaa: bbb'],
      ['Why not_', 'Why not?'],
      ["abc ''qwe'' hehe", 'abc "qwe" hehe'],
      ["_Part 2_ why _ why not_", '_Part 2: why / why not?'],
    ].each {|test,expected|
      assert_equal expected, @e.send(:process_file_or_directory_name,test)
    }
  end
  
  def test_read_metadata_overrides
    ['utf8','utf8n','utf16le','utf16be'].each {|charset|
      @e.textfile= "#{test_data_dir}/autotag-#{charset}.txt"
      
      @e.metadata.clear
      @e.send :read_metadata_overrides, :artist
      assert_hashes_equal({:artist => 'メガドン'}, @e.metadata)
      
      @e.metadata.clear
      @e.send :read_metadata_overrides, :album
      assert_hashes_equal({
        :artist => 'メガドン',
        :album => '灰とダイヤモンド',
        :albumtype => 'Ahh',
        1 => '真夏の扉 (GLAY VERSION)',
        2 => '彼女の"Modern..."',
        4 => 'ひどくありふれたホワイトノイズをくれ',
        5 => 'Rain (GLAY VERSION)',
        8 => '千ノナイフガ胸ヲ刺ス',
        10 => 'if ～灰とダイヤモンド～',
        12 => charset,
      }, @e.metadata)
    }
  end
  
end