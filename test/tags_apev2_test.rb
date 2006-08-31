require 'test_helper'

class APEv2Test < Autotag::TestCase
  
  def test_apev2_tag_detection
    AudioFile.open("#{test_data_dir}/apev2/apev2.mp3") do |af|
      assert Tags::APEv2.new(af).tag_exists?
    end
  end
  
  def test_apev2_read
    AudioFile.open("#{test_data_dir}/apev2/apev2.mp3") do |af|
      metadata= Tags::APEv2.new(af).read
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
  
end