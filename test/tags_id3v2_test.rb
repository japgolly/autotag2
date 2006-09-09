require 'test_helper'

class ID3v2Test < Autotag::TestCase
  
  def test_tag_detection
    assert tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.2_header.mp3")
    assert tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.3_header.mp3")
    assert tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.4_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"apev2/apev2.mp3")
  end
  
  def test_read_22h
    AudioFile.open_file("#{test_data_dir}/ip3v2/ip3v2.2_header.mp3") do |af|
      metadata= tag_class.new(af).read
      assert_hashes_equal({
        :_header => true,
        :_version => 2,
#        :artist => 'Cemetery Of Scream',
#        :track => 'Where Next?',
#        :album => 'The Event Horizon',
#        :year => '2005',
#        :genre => 'Metal',
#        :track_number => '10',
#        :total_tracks => '11',
#        :disc => '4',
#        :total_discs => '7',
#        'TEN' => 'iTunes v6.0.5.20',
      }, metadata)
      assert_equal 2201, af.size_of_header
      assert_equal 0, af.size_of_footer
      assert_equal 5976-2201, af.size
      assert_equal "\xFF\xFB\xB2\x00\x00", af.read_all[0..4]
      assert_equal "\x1D\x44\x83\x7A\xC2", af.read_all[-5..-1]
    end
  end
  
  def test_read_23h
    AudioFile.open_file("#{test_data_dir}/ip3v2/ip3v2.3_header.mp3") do |af|
      metadata= tag_class.new(af).read
      assert_hashes_equal({
        :_header => true,
        :_version => 3,
        :artist => '一石二鳥',
        :track => 'Vacant',
        :album => 'Score: 20th Anniversary World Tour',
        :year => '2006',
        :genre => '(92)Progressive Rock',
        :track_number => '2',
        :total_tracks => '4',
        :disc => '2',
        :total_discs => '3',
        :album_type => 'qweasd',
        'Ripping tool' => 'EAC',
      }, metadata)
      assert_equal 2411, af.size_of_header
      assert_equal 0, af.size_of_footer
      assert_equal 5446-2411, af.size
      assert_equal "\xFF\xFB\x90\x64\x00", af.read_all[0..4]
      assert_equal "\x54\x4C\x22\x39\xA7", af.read_all[-5..-1]
    end
  end
  
  def test_read_24h
    AudioFile.open_file("#{test_data_dir}/ip3v2/ip3v2.4_header.mp3") do |af|
      metadata= tag_class.new(af).read
      assert_hashes_equal({
        :_header => true,
        :_version => 4,
        :artist => 'monkey',
        :track => 'id3v2 example',
        :album => 'ＩＤ３',
        :year => '1996',
        :genre => 'bad',
        :track_number => '3',
        :total_tracks => '8',
        :disc => '2',
        :total_discs => '3',
        :album_type => 'Single',
        'Bullshit' => 'awer',
      }, metadata)
      assert_equal 2236, af.size_of_header
      assert_equal 0, af.size_of_footer
      assert_equal 5452-2236, af.size
      assert_equal "\xFF\xF3\x84\x64\x00", af.read_all[0..4]
      assert_equal "\x00\x00\x41\x4D\x45", af.read_all[-5..-1]
    end
  end
  
  def test_write22
    assert_raises(RuntimeError) {tag_class.new(nil).set_metadata(sample_tag_content(true,2)).create}
    assert_raises(RuntimeError) {tag_class.new(nil).set_metadata(sample_tag_content(false,2)).create}
  end
  
  def test_write23
    assert_raises(RuntimeError) {tag_class.new(nil).set_metadata(sample_tag_content(true,3)).create}
    assert_raises(RuntimeError) {tag_class.new(nil).set_metadata(sample_tag_content(false,3)).create}
  end
  
  def test_write24h
    # Create
    content= sample_tag_content true, 4
    t= tag_class.new(nil).set_metadata(content).create
    assert_kind_of String, t
    # Attempt to read back
    bullshit= 'dfanakp98ghakrjghap8ghagh'*3
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
  
  def sample_tag_content(header,version)
    {
      (header ? :_header : :_footer) => true,
      :_version => version,
      :artist => 'ＩＤ３!!',
      :track => 'id3 example',
      :album => 'haehe',
      :year => '1988',
      :genre => 'ル',
      :track_number => '4',
      :total_tracks => '1',
      :disc => '2',
      :total_discs => '2',
      :album_type => 'Single',
      'Bullshit' => 'werysdaf',
      :replaygain_album_gain => '+3.41 dB',
      :replaygain_album_peak => '0.291903',
      :replaygain_track_gain => '-8.21 dB',
      :replaygain_track_peak => '0.154808',
    }.deep_freeze
  end
  
  def tag_class
    Tags::ID3v2
  end
end