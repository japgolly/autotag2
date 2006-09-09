require 'test_helper'

class APEv2Test < Autotag::TestCase
  
  def test_tag_detection
    assert tag_call(tag_class,:tag_exists?,"apev2/apev2.mp3")
    assert !tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.2_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.3_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.4_header.mp3")
  end
  
  def test_read
    AudioFile.open_file("#{test_data_dir}/apev2/apev2.mp3") do |af|
      metadata= tag_class.new(af).read
      assert_hashes_equal({
        :_footer => true,
        :artist => 'エープ',
        :track => 'ape example',
        :album => 'hehe',
        :year => '1998',
        :genre => 'ジャンル',
        :track_number => '2',
        :total_tracks => '9',
        :disc => '1',
        :total_discs => '2',
        :album_type => 'Album',
        'Bullshit' => 'ahh',
      }, metadata)
      assert_equal 0, af.size_of_header
      assert_equal 287, af.size_of_footer
      assert_equal 3503-287, af.size
      assert_equal "\xFF\xF3\x84\x64\x00", af.read_all[0..4]
      assert_equal "\x00\x00\x41\x4D\x45", af.read_all[-5..-1]
    end
  end
  
  def test_write
    # Create
    content= sample_tag_content(false)
    t= tag_class.new(nil).set_metadata(content).create
    assert_kind_of String, t
    # Check flags
    assert_equal "\0\0\0\xA0", t[20..23]
    assert_equal "\0\0\0\x80", t[-12..-9]
    # Attempt to read back
    bullshit= 'qwelkjasdopiu34kjv98nrtbqrv0inv3q04'
    AudioFile.open_string(bullshit+t) do |af|
      metadata= tag_class.new(af).read
      assert !metadata.empty?, "Tag not found. create() must be generating invalid tags."
      assert_hashes_equal content, metadata
      assert_equal 0, af.size_of_header
      assert_equal t.size, af.size_of_footer
      assert_equal bullshit.size, af.size
      assert_equal bullshit, af.read_all
    end
  end
  
  #----------------------------------------------------------------------------
  private
  
  def sample_tag_content(header)
    {
      (header ? :_header : :_footer) => true,
      :artist => 'エープ',
      :track => 'ape example',
      :album => 'hehe',
      :year => '1998',
      :genre => 'ジャンル',
      :track_number => '2',
      :total_tracks => '9',
      :disc => '1',
      :total_discs => '2',
      :album_type => 'Album',
      'Bullshit' => 'ahh',
      :replaygain_album_gain => '-0.46 dB',
      :replaygain_album_peak => '0.243525',
      :replaygain_track_gain => '+1.31 dB',
      :replaygain_track_peak => '0.023487',
    }.deep_freeze
  end
  
  def tag_class
    Tags::APEv2
  end
end