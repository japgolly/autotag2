require 'test/test_helper'
require 'autotag/engine'
require 'tmpdir'
require 'fileutils'

class FullTest < Autotag::TestCase
  include FileUtils
  include Autotag::Tags
  
  def test_full
    engine_test_on('full_test'){
    
      # Assert we are really running on the test directory
      assert_equal tmpdir, Dir.getwd
      @e= MockEngine.new
      @e.instance_eval 'def process_root(*); end'
      @e.run
      assert_equal tmpdir, @e.instance_variable_get(:@root_dir)
      
      # Start
      metadata_per_tag= {
        APEv2 => {:_footer => true},
        ID3v2 => {:_header => true, :_version => 4},
      }.deep_freeze
      @e= MockEngine.new
      @e.run
      
      #########################################################################
      # ACDC/1970 - Why_
      album= {
          :artist => 'AC/DC',
          :album => 'Why?',
          :year => '1970',
          :total_tracks => '12',
      }
      assert_file 'ACDC/1970 - Why_/01 - Asd_ qwe.mp3', 6198, 'FF F3 84 64 00'.h, '00 41 4D 45'.h, {
          :track => 'Asd: qwe',
          :track_number => '1',
          :replaygain_album_gain => '-11.45 dB',
          :replaygain_album_peak => '1.209251',
          :replaygain_track_gain => '-11.87 dB',
          :replaygain_track_peak => '1.152004',
        }.merge(album), metadata_per_tag
      assert_file 'ACDC/1970 - Why_/02 - 全角文字もOKだよ.mp3', 7476, 'FF FB C0 04 00'.h, 'AA AA 45 AA AA'.h, {
          :track => '全角文字もOKだよ',
          :track_number => '2',
        }.merge(album), metadata_per_tag
      assert_file 'ACDC/1970 - Why_/04 - Me _ You... Why_.mp3', 5029, 'FF F3 84 64 31'.h, '00 00 41 4D 45'.h, {
          :track => 'Me / You... Why?',
          :track_number => '4',
        }.merge(album), metadata_per_tag
      assert_file 'ACDC/1970 - Why_/12 - NADA....mp3', 2333, 'FF 64 58 69 6E'.h, '04 24 2B D6 0E'.h, {
          :track => 'NADA...',
          :track_number => '12',
        }.merge(album), metadata_per_tag
        
      #########################################################################
      # ACDC/1972 - へへ
      album= {
          :artist => 'AC-DC',
          :album => 'へへ',
          :year => '1972',
          :total_tracks => '7',
      }
      assert_file 'ACDC/1972 - へへ/01 - Asd_ qwe.mp3', 2269, 'FE F3 84 64 01'.h, '00 03 FC 00 41'.h, {
          :track => ':Working?!?!',
          :track_number => '1',
          :replaygain_track_gain => '+17.43 dB',
          :replaygain_track_peak => '0.119293',
        }.merge(album), metadata_per_tag
      assert_file 'ACDC/1972 - へへ/02 - Breaking Away.mp3', 773, 'FF FA B0 0C 75'.h, '28 1B FF FF F3'.h, {
          :track => 'よし！',
          :track_number => '2',
          :replaygain_track_gain => '-8.770000 dB',
          :replaygain_track_peak => '1.130801',
        }.merge(album), metadata_per_tag
      assert_file 'ACDC/1972 - へへ/07 - NADA....mp3', 480, 'FF F3 24 64 0B'.h, '04 24 2B D6 0E'.h, {
          :track => 'Nada.',
          :track_number => '7',
        }.merge(album), metadata_per_tag
      
      
    } # engine_test_on
  end
  
  #----------------------------------------------------------------
  private
  
  class MockEngine < Autotag::Engine
    def puts(str=nil) end
  end
  
  def assert_file(file, audio_size, start_of_audio, end_of_audio, metadata_base, metadata_per_tag)
    expected_tags= {}
    metadata_per_tag.each {|tag,data|
      expected_tags[tag]= metadata_base.merge(data)
    }
    # open file
    AudioFile.open_file(utf82filename(file)) do |af|
      # read tags
      t= af.read_tags
      # check tags
      t.each_value {|m| assert !(m[:_header] && m[:_footer])}
      assert_hashes_equal expected_tags, t
      # check data
      assert_af_data af, nil, nil, audio_size, start_of_audio, end_of_audio
    end
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
