require "#{File.dirname __FILE__}/base"

module Autotag::Tags
  class ID3v2 < Base
    
    def create
      apply_defaults(DEFAULTS)
      raise "Unsupported version: #{self[:_version].inspect}" unless self[:_version] == 4
      items= get_items_without_params
      MERGED_VALUES.each {|a,b| merge_values_with_slash! items, a, b }
      
      padding= "\0" * self[:_padding]
      body= create_body(items)
      header= create_header(body.size + padding.size)
      header + body + padding
    end
    
    def read
      bof_read if bof_tag_exists?
      metadata
    end
    
    def tag_exists?
      bof_tag_exists?
    end
    
    #--------------------------------------------------------------------------
    private
    
    def create_header(tag_size)
      x= "ID3"                            # header
      x<< [self[:_version], 0].pack('cc') # version
      x<< "\0"                            # flags
      x<< create_int(tag_size)            # size
    end
    
    def create_body(items)
      x= ''
      items.keys.sort.each {|k| x<< create_item(k,items[k])}
      x
    end
    
    def create_item(k,v)
      # Prepare
      id= sym2tag(k)
      unless id
        v= "#{sym2tag k, true}\0#{v}"
        id= tagxxx
      end
      v= "_#{v}\0"
      v[0]= contains_unicode?(v) ? 3 : 0
      
      # Create item
      x= id.dup                # id
      x<< create_int(v.length) # size
      x<< "\0\0"               # flags
      x<< v                    # value
    end
    
    def create_int(l)
      x= '1234'
      x[3]= (l&127)
      x[2]= ((l>>7)&127)
      x[1]= ((l>>14)&127)
      x[0]= ((l>>21)&127)
      x
    end
    
    def merge_values_with_slash!(items,key1,key2)
      if items.has_key?(key2)
        items[key1]= "#{items[key1] || 0}/#{items.delete key2}"
      end
    end
    
    def sym2tag(sym,extended_tag=false)
      unless extended_tag
        x= SYM2TAG[sym]
        x ? x[self[:_version]-2] : nil
      else
        SYM2TAGXXX[sym] || sym.to_s
      end
    end
    
    #--------------------------------------------------------------------------
    
    def bof_tag_exists?
      @af.seek_to_start
      fin.read(3) == 'ID3'
    end
    
    def bof_read
      @af.seek_to_start
      self[:_header]= true
      header= @af.read_and_ignore_header(10)
      self[:_version]= (header[4]==0 ? header[3] : "#{header[3]}.#{header[4]}".to_f)
      #TODO: Doesn't support extended headers
      size= read_int(header[6..9])

      if self[:_version] >= 3
        pos=0
        
        # Read tag
        while(1)
          frame= {:id => fin.read(4)}
          frame[:size]= read_int
          frame[:flags]= fin.read(2)
          pos += 10
          break if frame[:id] == "\0\0\0\0" || pos > size
          pos += frame[:size]
          frame[:value]= read_string(fin.read(frame[:size]))
          if frame[:id] == tagxxx
            if frame[:value] =~ /^(.+?)\0(.+)$/
              self[tag2sym($1,true)]= $2
            else
              self[frame[:id]]= frame[:value]
            end
          else
            self[tag2sym(frame[:id])]= frame[:value]
          end
        end
        
        # Post-process
        MERGED_VALUES.each {|a,b| split_slash_divided_values! a, b }
        
      end # if self[:_version] >= 3
      
      # Done
      @af.ignore_header size
    end
    
    def read_int(x=nil)
      x ||= fin.read(4)
      (x[3]&127) | ((x[2]&127) << 7) | ((x[1]&127) << 14) | ((x[0]&127) << 21)
    end
    
    def read_string(x)
      encoding= x[0]
      x= x[1..-1]
      x= case encoding
        when 0
          # ISO-8859-1 [ISO-8859-1]. Terminated with $00.
          x.to_s
        when 1
          # UTF-16 [UTF-16] encoded Unicode [UNICODE] with BOM. All strings in the same frame SHALL have the same byteorder. Terminated with $00 00.
          # Unicode strings must begin with the Unicode BOM ($FF FE or $FE FF) to identify the byte order.
          big_endian= (x[0..1]=="\xFE\xFF")
          convert_utf16 x[2..-1].to_s, big_endian
        when 2
          # UTF-16BE [UTF-16] encoded Unicode [UNICODE] without BOM. Terminated with $00 00.
          # UNTESTED
          convert_utf16 x, true
        when 3
          # UTF-8 [UTF-8] encoded Unicode [UNICODE]. Terminated with $00.
          x.to_s
        else
          raise "Invalid encoding flag: '#{encoding}'"
        end
      x.gsub! %r{\x00$}, ''
      x
    end
    
    def split_slash_divided_values!(key1,key2)
      if self[key1] =~ %r{([^/]+)/([^/]+)}
        self[key1],self[key2]= $1,$2
      end
    end
    
    def tag2sym(tag,extended_tag=false)
      if extended_tag
        TAGXXX2SYM[tag] || tag
      else
        TAG2SYM[self[:_version]-2][tag] || tag
      end
    end
    
    def tagxxx
      TAGXXX[self[:_version]-2]
    end
    
    #--------------------------------------------------------------------------
    SYM2TAG= {
      :artist       => %w{2 TPE1 TPE1},
      :album        => %w{2 TALB TALB},
      :disc         => %w{2 TPOS TPOS},
      :genre        => %w{2 TCON TCON},
      :track        => %w{2 TIT2 TIT2},
      :track_number => %w{2 TRCK TRCK},
      :year         => %w{2 TYER TDRC},
    }.deep_freeze
    SYM2TAGXXX= {
      :album_type            => 'Albumtype',
      :replaygain_album_gain => 'replaygain_album_gain',
      :replaygain_album_peak => 'replaygain_album_peak',
      :replaygain_track_gain => 'replaygain_track_gain',
      :replaygain_track_peak => 'replaygain_track_peak',
    }.deep_freeze
    TAG2SYM= []
    SYM2TAG.each{|sym,tags|
      tags.each_index{|ver|
        TAG2SYM[ver] ||= {}
        TAG2SYM[ver][tags[ver]]= sym
      }
    }
    TAG2SYM.deep_freeze
    TAGXXX2SYM= SYM2TAGXXX.invert.deep_freeze
    TAGXXX= %w{TXX TXXX TXXX}.deep_freeze
    MERGED_VALUES= {
      :track_number => :total_tracks,
      :disc => :total_discs,
    }.deep_freeze
    
    DEFAULTS= {
      :padding => 1024,
      :version => 4,
    }.deep_freeze
  end
end