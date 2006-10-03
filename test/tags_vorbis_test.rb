require 'test/test_helper'

class VorbisTest < Autotag::TestCase
  
  def test_tag_detection
    assert tag_call(tag_class,:tag_exists?,"tags/flac.flac")
    assert !tag_call(tag_class,:tag_exists?,"tags/apev2.mp3")
    assert !tag_call(tag_class,:tag_exists?,"tags/ip3v2.2_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"tags/ip3v2.3_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"tags/ip3v2.4_header.mp3")
  end
  
  def test_read
    AudioFile.open_file("#{test_data_dir}/tags/flac.flac") do |af|
      metadata= tag_class.new(af).read
      assert_valid_metadata(metadata)
      other_tags= metadata.delete(:_non_metadata_tags)
      assert_hashes_equal({
        :_header => true,
        :_padding => 3720,
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
      assert_equal ["\x00\x00\x00\x22\x04\x80\x04\x80\x00\x00\x0E\x00\x10\x0A\x0A\xC4\x42\xF0\x00\x7E\x36\x24\xD4\x1D\xD9\xFD\x7D\xE2\x13\x49\xD4\x46\x2A\x00\x96\xB1\x78\x34"], other_tags
      assert_af_data af, 4146, 0, 7680-4146, "\xFF\xF8\x39\x18\x00", "\x00\x00\x00\x40\x1A"
    end
  end
  
  def test_write
    # Create
    content= sample_tag_content.merge :_non_metadata_tags => ["\x00\x00\x00\x22\x04\x80\x04\x80\x00\x00\x0E\x00\x10\x0A\x0A\xC4\x42\xF0\x00\x7E\x36\x24\xD4\x1D\xD9\xFD\x7D\xE2\x13\x49\xD4\x46\x2A\x00\x96\xB1\x78\x34"]
    content.deep_freeze
    t= tag_class.new(nil).set_metadata(content).create
    assert_kind_of String, t
    # Attempt to read back
    bullshit= 'defkljhqar7q3v7370dkgh025'
    AudioFile.open_string(t+bullshit) do |af|
      metadata= tag_class.new(af).read
      assert !metadata.empty?, "Tag not found. create() must be generating invalid tags."
      assert_hashes_equal content, metadata
      assert_equal t.size, af.size_of_header
      assert_equal 0, af.size_of_footer
      assert_equal bullshit.size, af.size
      assert_equal bullshit, af.read_all
    end
  end
  
  #----------------------------------------------------------------------------
  private
  
  def sample_tag_content
    {
      :_header => true,
      :_padding => 1546,
      :_tool => 'woteva',
      :artist => 'まー',
      :track => 'flac example',
      :album => 'qweasd',
      :year => '1995',
      :genre => 'ジジジ',
      :track_number => '4',
      :total_tracks => '5',
      :disc => '2',
      :total_discs => '3',
      :album_type => 'Yyy',
      'Bullshit' => 'qweasd',
      :replaygain_album_gain => '+1.46 dB',
      :replaygain_album_peak => '0.343525',
      :replaygain_track_gain => '-2.31 dB',
      :replaygain_track_peak => '0.043487',
    }.deep_freeze
  end
  
  def tag_class
    Tags::Vorbis
  end
end