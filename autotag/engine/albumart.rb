# encoding: utf-8
module Autotag
  module AlbumArt
    
    def load_all_albumart
      # Load cover album art
      albumart_filename= Dir.glob('{front,folder,cover}.jpg').first
      load_albumart(:front_cover, albumart_filename) if albumart_filename
    end
    
    #--------------------------------------------------------------------------
    private
    
    def load_albumart(picture_type, filename)
      # Add to metadata
      @metadata[:albumart]||= {}
      md= @metadata[:albumart][picture_type]= {}
      
      # Load image
      md[:mimetype]= get_mime_type(filename)
      md[:image]= File.open(filename,'rb') {|io| io.read}
    end

    def get_mime_type(filename)
      return 'image/jpeg' if filename =~ /\.jpe?g$/i
      #return 'image/gif' if filename =~ /\.gif$/i
      raise "Unable to determine mime type for #{filename.inspect}."
    end    
    
  end
end
