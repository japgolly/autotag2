# encoding: utf-8
require 'test/test_helper'
require 'test/integration_test_support'

class AlbumArtTest < Autotag::TestCase
  include Autotag::IntegrationTestSupport
  
  def test_adding_to_existing_tags
    engine_test_on('albumart_test', true) {
      dir= 'Protest The Hero/2008 - Fortress'
      @e= new_engine_instance(dir)
      @e.run
      albumart= {:front_cover => {:mimetype => 'image/jpeg', :image => get_file_contents("#{dir}/front.jpg")}}
      album= {
          :artist => 'Protest The Hero',
          :album => 'Fortress',
          :year => '2008',
          :total_tracks => '10',
      }
      assert_file "#{dir}/07. Wretch.mp3", 2039, 'FF FB 98 64 00'.h, '19 24 B6 AB F1'.h, {
        :track => 'Wretch',
        :track_number => '7',
        :replaygain_album_gain => '-8.87 dB',
        :replaygain_album_peak => '1.088699',
        :replaygain_track_gain => '-9.14 dB',
        :replaygain_track_peak => '1.072732',
      }.merge(album), mp3_tags(albumart)
      assert_file_unchanged "#{dir}/08. Wretch.mp3"
      assert_file "#{dir}/09. Goddess Bound.mp3", 6150, 'FF FB 90 44 00'.h, '13 71 AF 8F 8A'.h, {
        :track => 'Goddess Bound',
        :track_number => '9',
        :replaygain_album_gain => '-8.87 dB',
        :replaygain_album_peak => '1.088699',
        :replaygain_track_gain => '-8.41 dB',
        :replaygain_track_peak => '1.067128',
      }.merge(album), mp3_tags(albumart)
      assert_file "#{dir}/10. Goddess Gagged.mp3", 6286, 'FF FB 90 64 00'.h, '98 4B CF CF F9'.h, {
        :track => 'Goddess Gagged',
        :track_number => '10',
        :replaygain_album_gain => '-8.87 dB',
        :replaygain_album_peak => '1.088699',
        :replaygain_track_gain => '-7.64 dB',
        :replaygain_track_peak => '1.042752',
      }.merge(album), mp3_tags(albumart)
      assert_equal 1, @e.ui.instance_variable_get(:@uptodate_track_count)
      assert_equal 3, @e.ui.instance_variable_get(:@updated_track_count)
    }
  end
  
  
  #----------------------------------------------------------------
  private
  
  def mp3_tags(albumart)
    {
      APEv2 => {:_footer => true},
      ID3v2 => {:_header => true, :_version => 4, :albumart => albumart},
    }
  end
  
end
