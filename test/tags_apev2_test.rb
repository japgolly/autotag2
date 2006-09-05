require 'test_helper'

class APEv2Test < Autotag::TestCase
  
  def test_tag_detection
    assert tag_call(tag_class,:tag_exists?,"apev2/apev2.mp3")
    assert !tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.2_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.3_header.mp3")
    assert !tag_call(tag_class,:tag_exists?,"ip3v2/ip3v2.4_header.mp3")
  end
  
  def test_read
    AudioFile.open("#{test_data_dir}/apev2/apev2.mp3") do |af|
      metadata= tag_class.new(af).read
      assert_hashes_equal({
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
    end
  end
  
  private
  
  def tag_class
    Tags::APEv2
  end
end