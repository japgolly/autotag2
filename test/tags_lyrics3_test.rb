require 'test_helper'

class Lyrics3Test < Autotag::TestCase
  
  def test_tag_detection
    assert tag_call(tag_class,:tag_exists?,"tags/lyrics3v1.mp3")
    assert tag_call(tag_class,:tag_exists?,"tags/lyrics3v2.mp3")
    assert !tag_call(tag_class,:tag_exists?,"tags/ip3v2.2_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"tags/ip3v2.3_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"tags/ip3v2.4_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"tags/apev2.mp3")
  end
  
  def test_read_v1
    AudioFile.open_file("#{test_data_dir}/tags/lyrics3v1.mp3") do |af|
      metadata= tag_class.new(af).read
      assert_hashes_equal({
        :_version => 1,
        :_tag => 'LYRICSBEGININD0000200EAL00052 Absolute Power Metasdal-The Definitive Collection 5CD CRC00008339F2EE9000097LYRICSEND',
      }, metadata)
      assert_equal 0, af.size_of_header
      assert_equal 115, af.size_of_footer
      assert_equal 765, af.size
      assert_equal "\xFF\xFA\xB0\x0C\x75", af.read_all[0..4]
      assert_equal "\x28\x1B\xFF\xFF\xF3", af.read_all[-5..-1]
    end
  end
  
  def test_read_v2
    AudioFile.open_file("#{test_data_dir}/tags/lyrics3v2.mp3") do |af|
      metadata= tag_class.new(af).read
      assert_hashes_equal({
        :_version => 2,
        :_tag => 'LYRICSBEGININD0000200EAL00052 Absolute Power Metal-The Definitive Collection 5CD CRC00008339F2EE9000097LYRICS200',
      }, metadata)
      assert_equal 0, af.size_of_header
      assert_equal 112, af.size_of_footer
      assert_equal 774, af.size
      assert_equal "\xFF\xFA\xB0\x03\x0C", af.read_all[0..4]
      assert_equal "\x2A\xA0\xFF\xFF\xF3", af.read_all[-5..-1]
    end
  end
  
  def test_write
    assert_raises(CreateNotSupported) {tag_class.new(nil).set_metadata({}).create}
  end
  
  #----------------------------------------------------------------------------
  private
  
  def tag_class
    Tags::Lyrics3
  end
end