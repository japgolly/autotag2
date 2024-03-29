# encoding: utf-8
require_relative 'test_helper'
require 'integration_test_support'

class FullTest < Autotag::TestCase
  include Autotag::IntegrationTestSupport

  def test_full
    engine_test_on('full_test',true){
      UnicodeIO::chdir('The Woteva Band/2003 - Yes I Like It') {UnicodeIO::rename '01 - Novae.mp3', '01 - Novaë.mp3', true}
      @e= new_engine_instance
      @e.ui.instance_eval 'alias :quiet_mode :old_quiet_mode' if $0 =~ %r{/ruby/RemoteTestRunner.rb$}
      @e.run
      assert_runtime_options

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
      testdir_acdc_1970_why

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
      #   * filenames with non-sjis chars (used to fail before UnicodeIO)
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
      assert_file "#{dir}/01 - Novaë.mp3", 4890, 'FF FB B2 00'.h, '00 00 47 00'.h, {
          :track => 'Novaë',
          :track_number => '1',
          :replaygain_album_peak => '3.168573',
        }.merge(album), mp3_tags

      #########################################################################
      # The Woteva Band/2005 - Rain
      # Tests:
      #   * processes cd/disc directories (numbered cds/discs)
      #   * sets :total_discs correctly
      #   * detects disc_title correctly
      testdir_the_woteva_band_2005_Rain

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
      testdir_waterfall_men_albums_2006_flac_attack false

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


      #########################################################################
      # VA/2000 - Best Of Me
      # Tests:
      #   * v/a albums (stock standard)
      #   * v/a albums (when filename doesn't match artist/title pattern but override info does)
      #   * v/a hardcoded artist tag
      #   * v/a name splitting: -- takes precedence over - in artist/track separation
      album= {
          :album_artist => 'Various Artists',
          :album => 'Best Of Me',
          :year => '2000',
          :total_tracks => '6',
          :replaygain_track_gain => '+17.43 dB',
          :replaygain_track_peak => '0.119293',
          :album_type => 'Compilation',
      }
      dir= 'VA/2000 - Best Of Me'
      assert_file_metadata "#{dir}/01 - John - 2 -- Stuff.mp3", {:track_number=>'1', :artist=>'Stuff', :track=>'John - 2'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/04 - The Crazy People - Big Red Apples.mp3", {:track_number=>'4', :artist=>'Big Red Apples', :track=>'The Crazy People'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/06 - Happy.mp3", {:track_number=>'6', :artist=>'The Jam Cans', :track=>'Happy?'}.merge(album), mp3_tags

      #########################################################################
      # VA/Soundtracks/2009 - Soundtrack to Hell
      # Tests:
      #   * v/a albums albumtypes
      #   * v/a albums (when filename doesn't match artist/title pattern but override info does)
      #   * v/a hardcoded artist tag
      #   * v/a name splitting: -- takes precedence over - in artist/track separation
      #   * v/a name splitting: // takes precedence over - in artist/track separation
      #   * v/a track with no artist
      album= {
          :album_artist => 'Various Artists',
          :album => 'Soundtrack to Hell',
          :year => '2009',
          :total_tracks => '7',
          :replaygain_track_gain => '+17.43 dB',
          :replaygain_track_peak => '0.119293',
          :album_type => 'Soundtrack',
      }
      dir= 'VA/Soundtracks/2009 - Soundtrack to Hell'
      assert_file_metadata "#{dir}/001. Ze Title -- Artist - 2.mp3", {:track_number=>'1', :artist=>'Artist - 2', :track=>'Ze Title'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/002. The Crazy People - Big Red Apples.mp3", {:track_number=>'2', :artist=>'Big Red Apples', :track=>'The Crazy People'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/003. Really.mp3", {:track_number=>'3', :artist=>'Dudes', :track=>'No - Really?'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/007. No artist.mp3", {:track_number=>'7', :track=>'No artist'}.merge(album), mp3_tags # No artist


      #########################################################################
      # OTHER
      testdir_waterfall_men_albums_2007_wowness
      testdir_waterfall_men_singles_1989_disco_stu true, true
      assert_equal full_test_useless_files.sort, @e.ui.instance_variable_get(:@all_files).values[0].sort
      full_test_useless_files.each {|f| assert_file_unchanged f}

    } # engine_test_on
  end

  def test_with_force
    engine_test_on('full_test',true){
      @e= new_engine_instance '-f'
      @e.run
      assert_runtime_options :force
      assert_equal 0, @e.ui.instance_variable_get(:@uptodate_track_count)
      assert_equal 0, @e.ui.instance_variable_get(:@uptodate_track_size)
      refute_equal 0, @e.ui.instance_variable_get(:@updated_track_count)
      refute_equal 0, @e.ui.instance_variable_get(:@updated_track_size)
      (Dir.glob('**/*.mp3').map{|f|filename2utf8(f)} - full_test_useless_files).each {|f| assert_file_changed f}
      full_test_useless_files.each {|f| assert_file_unchanged f}
      testdir_waterfall_men_albums_2006_flac_attack true
    }
  end

  def test_with_pretend
    engine_test_on('full_test',true){
      @e= new_engine_instance '-p'
      @e.run
      assert_runtime_options :pretend
      refute_equal 0, @e.ui.instance_variable_get(:@uptodate_track_count)
      refute_equal 0, @e.ui.instance_variable_get(:@uptodate_track_size)
      refute_equal 0, @e.ui.instance_variable_get(:@updated_track_count)
      refute_equal 0, @e.ui.instance_variable_get(:@updated_track_size)
      (Dir.glob('**/*.mp3').map{|f|filename2utf8(f)} - full_test_useless_files).each {|f| assert_file_unchanged f}
      full_test_useless_files.each {|f| assert_file_unchanged f}
    }
  end

  def test_with_specific_root_dirs
    engine_test_on('.',true){
      cp_r 'full_test', 'offguts', :preserve => true
      cp_r 'full_test', 'testofthedamned', :preserve => true
      @e= new_engine_instance '-f','full_test','testofthedamned'
      @e.run
      assert_runtime_options :force
      useless_files= full_test_useless_files.map{|f|["full_test/#{f}","testofthedamned/#{f}"]}.flatten
      (Dir.glob('**/*.{mp3,flac}').map{|f|filename2utf8(f)} - useless_files).each {|f|
        if f =~ /full_test|testofthedamned/
          assert_file_changed f
        else
          assert_file_unchanged f
        end
      }
      useless_files.each {|f| assert_file_unchanged f}
    }
  end

  def test_with_specific_nonroot_dirs
    subtest= lambda do |test_acdc_1970_why, test_flac_attack, test_wowness, which_rain_cds, disco_stu_cds, *dirs|
      engine_test_on('full_test',true){
        @e= new_engine_instance '-f', *dirs
#        @e.ui.instance_eval 'alias :quiet_mode :old_quiet_mode' if $0 =~ %r{/ruby/RemoteTestRunner.rb$}
        @e.run
        changed_file_regex= /(?:^|[\\\/])(?:#{dirs.map{|d|Regexp.quote d}.join '|'})(?:[\\\/]|$)/
        (Dir.glob('**/*.{mp3,flac}').map{|f|filename2utf8(f)} - full_test_useless_files).each {|f|
          if f =~ changed_file_regex
            assert_file_changed f
          else
            assert_file_unchanged f
          end
        }
        full_test_useless_files.each {|f| assert_file_unchanged f}
        testdir_acdc_1970_why if test_acdc_1970_why
        testdir_waterfall_men_albums_2006_flac_attack true if test_flac_attack
        testdir_waterfall_men_albums_2007_wowness if test_wowness
        testdir_the_woteva_band_2005_Rain(*which_rain_cds) unless which_rain_cds.nil?
        testdir_waterfall_men_singles_1989_disco_stu(*disco_stu_cds) if disco_stu_cds
      }
    end

    # Artist
    subtest.call true, true, false, nil, nil, 'ACDC', 'Waterfall Men_'
    # Album type
    subtest.call false, true, true, nil, nil, 'Waterfall Men_/Albums'
    # Album
    subtest.call true, false, false, nil, nil, 'ACDC/1970 - Why_'
    subtest.call false, true, false, nil, nil, 'Waterfall Men_/Albums/2006 - Flac Attack'
    subtest.call false, false, false, [1,7], nil, 'The Woteva Band/2005 - Rain/cd 1', 'The Woteva Band/2005 - Rain/disc 7'
    subtest.call false, false, false, [], nil, 'The Woteva Band/2005 - Rain'
    subtest.call false, false, false, nil, [true,false], 'Waterfall Men_/Singles/1989 - Disco Stu/cd 1 - Title_ Boogie'
    subtest.call false, false, false, nil, [false,true], 'Waterfall Men_/Singles/1989 - Disco Stu/cd 2 - Buddy'
    subtest.call false, false, false, nil, [true,true], 'Waterfall Men_/Singles/1989 - Disco Stu'
    subtest.call false, false, false, nil, [true,true], 'Waterfall Men_/Singles'
    # Combination
    subtest.call true, true, true, [6], [true,true], 'ACDC/1970 - Why_', 'Waterfall Men_', 'The Woteva Band/2005 - Rain/CD 6'
    subtest.call true, false, false, [], [false,true], 'ACDC', 'The Woteva Band', 'Waterfall Men_/Singles/1989 - Disco Stu/cd 2 - Buddy'
  end

  def test_useless_files_with_specific_dirs
    engine_test_on('full_test',false){
      @e= new_engine_instance '-p', 'ACDC', 'The Woteva Band/1930 - Django', 'Waterfall Men_'
      @e.run
      acdc_useless_files= []
      acdc_useless_files+= [
        '1970 - Why_/50 - Windows only 1.Mp3',
        '1970 - Why_/51 - Windows only 2.mP3',
        '1970 - Why_/52 - Windows only 3.MP3',
      ] if Autotag::Utils::case_sensitive_filenames?
      acdc_useless_files+= [
        '1972 - へへ/crap/qwezxc.flac',
        '1972 - へへ/crap/qwezxc2.flac',
        '1972 - へへ/oops.mp3',
      ]
      assert_hashes_equal({
        File.expand_path("#{tmpdir}/ACDC") => acdc_useless_files,
        File.expand_path("#{tmpdir}/Waterfall Men_") => ['03 - bullshit.mp3'],
      }, @e.ui.instance_variable_get(:@all_files))
    }
  end

  #----------------------------------------------------------------
  private

  def mp3_tags
    {
        APEv2 => {:_footer => true},
        ID3v2 => {:_header => true, :_version => 4},
    }.deep_freeze
  end

  def flac_tags
    {Vorbis => {:_header => true, :_tool => Autotag::TITLE}}.deep_freeze
  end

  def full_test_useless_files
    x= [
      'autotag.txt',
      'ACDC/1972 - へへ/oops.mp3',
      'ACDC/1972 - へへ/crap/qwezxc.flac',
      'ACDC/1972 - へへ/crap/qwezxc2.flac',
      'Waterfall Men_/03 - bullshit.mp3',
    ]
    x+= [
      'ACDC/1970 - Why_/50 - Windows only 1.Mp3',
      'ACDC/1970 - Why_/51 - Windows only 2.mP3',
      'ACDC/1970 - Why_/52 - Windows only 3.MP3',
    ] if Autotag::Utils::case_sensitive_filenames?
    x
  end

  def testdir_acdc_1970_why
    album= {
        :artist => 'AC/DC',
        :album => 'Why?',
        :year => '1970',
        :total_tracks => '99',
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
    assert_file "#{dir}/99 - NADA....mp3", 2333, 'FF 64 58 69 6E'.h, '04 24 2B D6 0E'.h, {
        :track => 'NADA...',
        :track_number => '99',
      }.merge(album), mp3_tags
    # File extentions should be case-insensitive on windows and case-sensitive on everything else
    if Autotag::Utils::case_insensitive_filenames?
      assert_file_metadata "#{dir}/50 - Windows only 1.Mp3",{:track_number=>'50',:track=>'Windows only 1'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/51 - Windows only 2.mP3",{:track_number=>'51',:track=>'Windows only 2'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/52 - Windows only 3.MP3",{:track_number=>'52',:track=>'Windows only 3'}.merge(album), mp3_tags
    else
      assert_file_unchanged "#{dir}/50 - Windows only 1.Mp3", 2333
      assert_file_unchanged "#{dir}/51 - Windows only 2.mP3", 2333
      assert_file_unchanged "#{dir}/52 - Windows only 3.MP3", 2333
    end
  end

  def testdir_the_woteva_band_2005_Rain(*which)
    album= {
        :artist => 'The Woteva Band',
        :album => 'Rain',
        :year => '2005',
        :total_discs => '9',
    }
    dir= 'The Woteva Band/2005 - Rain'
    assert_file_metadata "#{dir}/cd 1/01 - Car.mp3",    {:disc => '1',:track_number => '1', :total_tracks => '1', :track => 'Car' }.merge(album), mp3_tags if which.empty? || which.include?(1)
    assert_file_metadata "#{dir}/Disc 2/21 - Cars.mp3", {:disc => '2',:track_number => '21',:total_tracks => '21',:track => 'Cars'}.merge(album), mp3_tags if which.empty? || which.include?(2)
    assert_file_metadata "#{dir}/CD 6/03 - Crap.mp3",   {:disc => '6',:track_number => '3', :total_tracks => '3', :track => 'Crap'}.merge(album), mp3_tags if which.empty? || which.include?(6)
    assert_file_metadata "#{dir}/disc 7/02 - Crap.mp3", {:disc => '7',:track_number => '2', :total_tracks => '3', :track => 'Crap'}.merge(album), mp3_tags if which.empty? || which.include?(7)
    assert_file_metadata "#{dir}/disc 7/03 - Baa.mp3",  {:disc => '7',:track_number => '3', :total_tracks => '3', :track => 'Baa' }.merge(album), mp3_tags if which.empty? || which.include?(7)
    assert_file_metadata "#{dir}/DISC 9/02 - Crap.mp3", {:disc => '9',:track_number => '2', :total_tracks => '2', :track => 'Crap'}.merge(album), mp3_tags if which.empty? || which.include?(9)
    assert_file_metadata "#{dir}/CD 3 - Mars/07 - Ha ha ha ha.mp3", {:disc => '3',:disc_title => 'Mars',:track_number => '7',:total_tracks => '7',:track => 'Ha ha ha ha'}.merge(album), mp3_tags if which.empty? || which.include?(9)
  end

  def testdir_waterfall_men_albums_2006_flac_attack(force)
    album= {
        :artist => 'Waterfall Men?',
        :album => 'Flac Attack',
        :year => '2006',
        :total_tracks => '4',
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
    if force
      assert_file "#{dir}/04 - Tagfull.flac", 1100, 'FF 4F 25 AE 08'.h, 'CF BC B2 96 53'.h, {
          :track => 'Tagfull',
          :track_number => '4',
          :_non_metadata_tags => ['00 00 00 22 04 80 04 80 00 00 0E 00 10 0A 0A C4 42 F0 00 7E 55 63 D4 1D D9 FD 7D E2 13 49 D4 46 2A 00 96 B1 78 34'.h],
        }.merge(album), flac_tags
    else
      assert_file_unchanged "#{dir}/04 - Tagfull.flac", 2310
    end
  end

  def testdir_waterfall_men_albums_2007_wowness
    album= {
        :artist => 'Waterfall Men?',
        :album => 'Wowness',
        :year => '2007',
        :total_tracks => '11',
    }
    dir= 'Waterfall Men_/Albums/2007 - Wowness'
    assert_file "#{dir}/02 - Vacant Wow.mp3", 1757, 'FF FB 91 64 00'.h, 'AA 0A AA BA AA'.h, {
        :track => 'Vacant Wow',
        :track_number => '2',
      }.merge(album), mp3_tags
    assert_file "#{dir}/11 - Wow Exposed.mp3", 2544, 'FF FB 90 44 06'.h, '55 55 24 31 55'.h, {
        :track => 'Wow Exposed',
        :track_number => '11',
      }.merge(album), mp3_tags
  end

  def testdir_waterfall_men_singles_1989_disco_stu(cd1,cd2)
    album= {
        :artist => 'Waterfall Men?',
        :album => 'Disco Stu',
        :album_type => 'Single',
        :year => '1989',
        :total_discs => '2',
    }
    dir= 'Waterfall Men_/Singles/1989 - Disco Stu'
    if cd1
      album.merge!(:disc=>'1',:disc_title=>'Title: Boogie',:total_tracks=>'2')
      assert_file_metadata "#{dir}/cd 1 - Title_ Boogie/01 - Walk With Me In Hell.mp3",{:track_number=>'1',:track=>'Walk With Me In Hell'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/cd 1 - Title_ Boogie/02 - Again We Rise.mp3",{:track_number=>'2',:track=>'Again We Rise'}.merge(album), mp3_tags
    else
      assert_file_unchanged "#{dir}/cd 1 - Title_ Boogie/01 - Walk With Me In Hell.mp3"
      assert_file_unchanged "#{dir}/cd 1 - Title_ Boogie/02 - Again We Rise.mp3"
    end
    if cd2
      album.merge!(:disc=>'2',:disc_title=>'Buddy',:total_tracks=>'3')
      assert_file_metadata "#{dir}/cd 2 - Buddy/01 - Future Breed Machine.mp3",{:track_number=>'1',:track=>'Future Breed Machine'}.merge(album), mp3_tags
      assert_file_metadata "#{dir}/cd 2 - Buddy/03 - Lonely Day.mp3",{:track_number=>'3',:track=>'Lonely Day'}.merge(album), mp3_tags
    else
      assert_file_unchanged "#{dir}/cd 2 - Buddy/01 - Future Breed Machine.mp3"
      assert_file_unchanged "#{dir}/cd 2 - Buddy/03 - Lonely Day.mp3"
    end
  end

end
