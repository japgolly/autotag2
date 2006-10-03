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
      @e= new_engine_instance
      @e.instance_eval 'def process_root(*); end'
      @e.run
      assert_equal tmpdir, @e.instance_variable_get(:@root_dir)
      
      # Start
      mp3_tags= {
        APEv2 => {:_footer => true},
        ID3v2 => {:_header => true, :_version => 4},
      }.deep_freeze
      flac_tags= {Vorbis => {:_tool => Autotag::TITLE}}
      @e= new_engine_instance
      @e.instance_variable_get(:@ui).instance_eval 'def puts(*a) Kernel.puts(*a) end; alias :put :old_put' if $0 =~ %r{/ruby/RemoteTestRunner.rb$}
      @e.run
      
      #########################################################################
      # ACDC/1970 - Why_
      # Tests:
      #   * artist level overrides
      #   * unicode files names
      #   * filename2human conversions
      #   * replaygain data preserved
      #   * total tracks
      #   * single and double digit track nubers
      #   * double digit total_tracks
      album= {
          :artist => 'AC/DC',
          :album => 'Why?',
          :year => '1970',
          :total_tracks => '12',
      }
      dir= 'ACDC/1970 - Why_'
      assert_file "#{dir}/01 - Asd_ qwe.mp3", 6198, 'FF F3 84 64 00'.h, '00 41 4D 45'.h, {
          :track => 'Asd: qwe',
          :track_number => '1',
          :replaygain_album_gain => '-11.45 dB',
          :replaygain_album_peak => '1.209251',
          :replaygain_track_gain => '-11.87 dB',
          :replaygain_track_peak => '1.152004',
        }.merge(album), mp3_tags
      assert_file "#{dir}/02 - 全角文字もOKだよ.mp3", 7476, 'FF FB C0 04 00'.h, 'AA AA 45 AA AA'.h, {
          :track => '全角文字もOKだよ',
          :track_number => '2',
        }.merge(album), mp3_tags
      assert_file "#{dir}/04 - Me _ You... Why_.mp3", 5029, 'FF F3 84 64 31'.h, '00 00 41 4D 45'.h, {
          :track => 'Me / You... Why?',
          :track_number => '4',
        }.merge(album), mp3_tags
      assert_file "#{dir}/12 - NADA....mp3", 2333, 'FF 64 58 69 6E'.h, '04 24 2B D6 0E'.h, {
          :track => 'NADA...',
          :track_number => '12',
        }.merge(album), mp3_tags
      
      #########################################################################
      # ACDC/1972 - へへ
      # Tests:
      #   * album level overrides
      #   * unicode dir names
      #   * single digit total_tracks
      album= {
          :artist => 'AC-DC',
          :album => 'へへ',
          :year => '1972',
          :total_tracks => '7',
      }
      dir= 'ACDC/1972 - へへ'
      assert_file "#{dir}/01 - Asd_ qwe.mp3", 2269, 'FE F3 84 64 01'.h, '00 03 FC 00 41'.h, {
          :track => ':Working?!?!',
          :track_number => '1',
          :replaygain_track_gain => '+17.43 dB',
          :replaygain_track_peak => '0.119293',
        }.merge(album), mp3_tags
      assert_file "#{dir}/02 - Breaking Away.mp3", 773, 'FF FA B0 0C 75'.h, '28 1B FF FF F3'.h, {
          :track => 'よし！',
          :track_number => '2',
          :replaygain_track_gain => '-8.770000 dB',
          :replaygain_track_peak => '1.130801',
        }.merge(album), mp3_tags
      assert_file "#{dir}/07 - NADA....mp3", 480, 'FF F3 24 64 0B'.h, '04 24 2B D6 0E'.h, {
          :track => 'Nada.',
          :track_number => '7',
        }.merge(album), mp3_tags
      
      #########################################################################
      # The Woteva Band/2003 - Yes I Like It
      # Tests:
      #   * only files needing tag updates are updated
      album= {
          :artist => 'The Woteva Band',
          :album => 'Yes I Like It',
          :year => '2003',
          :total_tracks => '8',
      }
      dir= 'The Woteva Band/2003 - Yes I Like It'
      assert_file "#{dir}/03 - Endless Sacrifice.mp3", 4892, 'FF FB B2 00'.h, '00 00 47 00'.h, {
          :track => 'Endless Sacrifice',
          :track_number => '3',
          :replaygain_album_gain => '-8.80 dB',
          :replaygain_album_peak => '1.168573',
          :replaygain_track_gain => '-3.80 dB',
          :replaygain_track_peak => '0.672035',
        }.merge(album), mp3_tags
      assert_file_unchanged "#{dir}/07 - Another Endless Sacrifice.mp3", 5756
      assert_file_unchanged "#{dir}/08 - Endless Sacrifice.mp3", 5759
      
      #########################################################################
      # The Woteva Band/2005 - Rain
      # Tests:
      #   * processes cd/disc directories (numbered cds/discs)
      #   * sets :total_discs correctly
      #   * detects disc_title correctly
      album= {
          :artist => 'The Woteva Band',
          :album => 'Rain',
          :year => '2005',
          :total_discs => '9',
      }
      dir= 'The Woteva Band/2005 - Rain'
      assert_file_metadata "#{dir}/cd 1/01 - Car.mp3",    {:disc => '1',:track_number => '1', :total_tracks => '1', :track => 'Car' }.merge(album), mp3_tags
      assert_file_metadata "#{dir}/Disc 2/21 - Cars.mp3", {:disc => '2',:track_number => '21',:total_tracks => '21',:track => 'Cars'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/CD 6/03 - Crap.mp3",   {:disc => '6',:track_number => '3', :total_tracks => '3', :track => 'Crap'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/disc 7/02 - Crap.mp3", {:disc => '7',:track_number => '2', :total_tracks => '3', :track => 'Crap'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/disc 7/03 - Baa.mp3",  {:disc => '7',:track_number => '3', :total_tracks => '3', :track => 'Baa' }.merge(album), mp3_tags
      assert_file_metadata "#{dir}/DISC 9/02 - Crap.mp3", {:disc => '9',:track_number => '2', :total_tracks => '2', :track => 'Crap'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/CD 3 - Mars/07 - Ha ha ha ha.mp3", {:disc => '3',:disc_title => 'Mars',:track_number => '7',:total_tracks => '7',:track => 'Ha ha ha ha'}.merge(album), mp3_tags
      
      #########################################################################
      # The Woteva Band/1930 - Django
      # Tests:
      #   * processes cd/disc directories (lettered cds/discs)
      #   * doesn't set :total_discs
      album= {
          :artist => 'The Woteva Band',
          :album => 'Django',
          :year => '1930',
          :track => 'Random',
          :track_number => '1',
          :total_tracks => '1',
      }
      dir= 'The Woteva Band/1930 - Django'
      assert_file_metadata "#{dir}/Disc A - Paris 1937/01 - Random.mp3",{:disc => 'A',:disc_title=> 'Paris 1937'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/Disc B - London 1939-40/01 - Random.mp3",{:disc => 'B',:disc_title=> 'London 1939-40'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/Disc C/01 - Random.mp3",{:disc => 'C'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/Disc D - Paris 1946-48/01 - Random.mp3",{:disc => 'D',:disc_title=> 'Paris 1946-48'}.merge(album), mp3_tags
      
      #########################################################################
      # Waterfall Men_/Albums/2006 - Flac Attack
      # Tests:
      #   * flac files tagged correctly
      #   * works with flac files and do and do not have vorbis comments already
      #   * album type directories parsed and album types work
      album= {
          :artist => 'Waterfall Men?',
          :album => 'Flac Attack',
          :year => '2006',
          :total_tracks => '3',
      }
      dir= 'Waterfall Men_/Albums/2006 - Flac Attack'
      assert_file "#{dir}/01 - Whatever.flac", 3534, 'FF F8 73 A3 B2'.h, '00 10 32 40 1A'.h, {
          :track => 'Whatever',
          :track_number => '1',
          :replaygain_album_gain => '+12.41 dB',
          :replaygain_album_peak => '4.023410',
          :replaygain_track_gain => '-13.23 dB',
          :replaygain_track_peak => '0.123417',
          :_non_metadata_tags => ['00 00 00 22 04 80 04 80 00 00 0E 00 10 0A 0A C4 42 F0 00 7E 36 24 D4 1D D9 FD 7D E2 13 49 D4 46 2A 00 96 B1 78 34'.h],
        }.merge(album), flac_tags
      assert_file "#{dir}/02 - Cry Baby.flac", 3532, 'FF 0F 33 24 25'.h, 'A8 3F 04 40 1A'.h, {
          :track => 'Cry Baby',
          :track_number => '2',
          :_non_metadata_tags => ['00 00 00 22 04 80 04 80 00 00 0E 00 10 0A 0A C4 42 F0 00 7E 55 24 D4 1D D9 FD 7D E2 13 49 D4 46 2A 00 96 B1 78 34'.h],
        }.merge(album), flac_tags
      assert_file "#{dir}/03 - Tagless.flac", 1100, 'FF 4F 25 AE 08'.h, 'CF BC B2 96 53'.h, {
          :track => 'Tagless',
          :track_number => '3',
          # The leading '00' in the below hex is the key to testing that last_tag bit is cleared for :_non_metadata_tags
          # It is actually '80' in the original file.
          :_non_metadata_tags => ['00 00 00 22 04 80 04 80 00 00 0E 00 10 0A 0A C4 42 F0 00 7E 55 63 D4 1D D9 FD 7D E2 13 49 D4 46 2A 00 96 B1 78 34'.h],
        }.merge(album), flac_tags
      
      #########################################################################
      # Waterfall Men_/Singles/2001 - Crazy_
      # Tests:
      #   * album type directories parsed and album types work
      #   * difficult id3v2 tags are handled correctly
      album= {
          :artist => 'Waterfall Men?',
          :album => 'Crazy?',
          :year => '2001',
          :total_tracks => '1',
          :album_type => 'Single',
      }
      dir= 'Waterfall Men_/Singles/2001 - Crazy_'
      assert_file "#{dir}/01 - Periscope.mp3", 2325, 'FF FB AA 64 03'.h, '71 C5 CF 55 72'.h, {
          :track => 'Periscope',
          :track_number => '1',
          :replaygain_album_gain => '-5.30 dB',
          :replaygain_album_peak => '1.088453',
          :replaygain_track_gain => '-4.41 dB',
          :replaygain_track_peak => '1.056579',
        }.merge(album), mp3_tags
      
    } # engine_test_on
  end
  
  #----------------------------------------------------------------
  private
  
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
    AudioFile.open_file(utf82filename(file)) do |af|
      # read tags
      t= af.read_tags
      # check tags
      t.each_value {|m|
        assert !(m[:_header] && m[:_footer])
        m.delete :_padding
      }
      assert_hashes_equal expected_tags, t
      # yield
      yield(af) if block_given?
    end
  end
  
  def assert_file_unchanged(filename, size=nil)
    info= File.stat(utf82filename(filename))
    modified_sec_ago= Time.now - info.mtime
    assert modified_sec_ago > 1, "File wasn't supposed to be modified.\nFile: \"#{filename}\""
    assert_equal size, info.size if size
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
    Dir.chdir(dir) {
      orig_files= Dir.glob("**/*.*")
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
  end
  
  def new_engine_instance
    Engine.new
  end
  
  def remove_tmpdir
    rm_rf tmpdir
  end
  
  def tmpdir
    @@tmpdir ||= File.join(Dir::tmpdir, 'autotag_test_tmp_dir')
    @@tmpdir.dup
  end
  
end
