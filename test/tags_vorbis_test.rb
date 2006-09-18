require 'test_helper'

class VorbisTest < Autotag::TestCase
  
  def test_tag_detection
    assert tag_call(tag_class,:tag_exists?,"vorbis/flac.flac")
    assert !tag_call(tag_class,:tag_exists?,"apev2/apev2.mp3")
    assert !tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.2_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.3_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.4_header.mp3")
  end
  
  def test_read
    AudioFile.open_file("#{test_data_dir}/vorbis/flac.flac") do |af|
      metadata= tag_class.new(af).read
      assert_hashes_equal({
        :_header => true,
        :_tool => 'reference libFLAC 1.1.1 20041001',
        :artist => 'Slayer',
        :track => '全角文字',
        :album => 'Christ Illusion',
        :year => '2006',
        :genre => 'Metal',
        :track_number => '2',
        :total_tracks => '11',
        :disc => '1',
        :total_discs => '4',
        :album_type => 'Single',
        'BULLSHIT' => 'qwezxc',
        :replaygain_album_gain => '+12.41 dB',
        :replaygain_album_peak => '4.023410',
        :replaygain_track_gain => '-13.23 dB',
        :replaygain_track_peak => '0.123417',
      }, metadata)
      assert_equal 4146, af.size_of_header
      assert_equal 0, af.size_of_footer
      assert_equal 7680-4146, af.size
      assert_equal "\xFF\xF8\x39\x18\x00", af.read_all[0..4]
      assert_equal "\x00\x00\x00\x40\x1A", af.read_all[-5..-1]
    end
  end
  
  #----------------------------------------------------------------------------
  private
  
#  def sample_tag_content(header)
#    {
#      (header ? :_header : :_footer) => true,
#      :artist => 'エープ',
#      :track => 'ape example',
#      :album => 'hehe',
#      :year => '1998',
#      :genre => 'ジャンル',
#      :track_number => '2',
#      :total_tracks => '9',
#      :disc => '1',
#      :total_discs => '2',
#      :album_type => 'Album',
#      'Bullshit' => 'ahh',
#      :replaygain_album_gain => '-0.46 dB',
#      :replaygain_album_peak => '0.243525',
#      :replaygain_track_gain => '+1.31 dB',
#      :replaygain_track_peak => '0.023487',
#    }.deep_freeze
#  end
  
  def tag_class
    Tags::Vorbis
  end
end