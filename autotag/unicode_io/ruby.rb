puts '************ ruby ver *****************'

module Autotag
  module UnicodeIO
    include Autotag::Unicode
    extend self
    
    def chdir(dir,&block) Dir.chdir(dir,&block) end
    def delete(f) File.delete(f) end
    def directory?(f) File.directory?(f) end
    def file?(f) File.file?(f) end
    def pwd; Dir.pwd end
    
    def rename(from, to, force=false)
      delete(to) if force
      File.rename(from, to)
    end
    
    def glob(recurse_levels, dir=nil, file_match_pattern=nil, flags=0)
      dir= nil if dir == '.'
      file_match_pattern ||= '*'
      state= {
        :files => [],
        :depth => -1,
      }
      recurse_dot_dirs= (flags & File::FNM_DOTMATCH) != 0
      glob_(recurse_levels,dir,state,nil,recurse_dot_dirs)
      file_match_patterns= []
      
      asd= lambda {|f|
        matches= f.scan(/\{.+?\}/u)
        if matches.empty?
          file_match_patterns<< f.downcase
        else
          m= matches[0]
          m[1..-2].split(',').each {|v|
            newstr= f.sub(m,v)
            asd.call newstr
          }
          file_match_patterns.uniq!
        end
      }
      asd.call file_match_pattern

      state[:files].select{|f|
        match= false
        f= f.downcase.sub(/^.*\//,'')
        file_match_patterns.each{|p|
          match ||= ::File.fnmatch?(p,f,flags)
        }
        
        match
      }.sort
    end
  
    private
    
    def glob_(recurse_levels,dir,state,full_dir,recurse_dot_dirs)
      raise unless recurse_levels.is_a?Fixnum
      state[:depth] += 1
      allow_recurse= recurse_levels < 0 ? true : (state[:depth] < recurse_levels)
      chdir(dir || '.') do
        if dir
          if full_dir
            full_dir.concat "/#{dir}"
          else
            full_dir= dir.dup
          end
        end
        Dir['*'].each {|f|

#        buf= '0'*1024
#        h= FindFirstFileW.call(to16("*\0"), buf)
#        unless h == -1
#          pat= Regexp.new('^.{44}((?:..)+?)\0\0',Regexp::MULTILINE,'N')
#          begin
#            buf =~ pat
#            f= to8($1)
            unless f=='.' || f=='..'
              state[:files]<< (full_dir ? "#{full_dir}/" : '') + f
              bluth= File.directory?(f) # TODO rename bluth
              glob_(recurse_levels,f,state,full_dir ? full_dir.dup : nil,recurse_dot_dirs) if allow_recurse && bluth && (recurse_dot_dirs or f[0]!=46)
            end
#            buf= '0'*1024
#          end while FindNextFileW.call(h,buf) != 0
#          raise if FindClose.call(h) == 0
#        end
        }
      end # chdir
      state[:depth] -= 1
    end
    
    public
    class UFile
      extend Unicode
      
      def self.open(filename,mode)
        fn16= UnicodeIO.send(:prepro_fn,filename)
        h= case mode
        when :read, 'rb'
          CreateFileW.call(fn16, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, 0, 0)
        when :write, 'wb'
          CreateFileW.call(fn16, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)
        end
        raise "Open file operation failed. File='#{filename}'" if h == -1
        f= new(h)
        if block_given?
          yield f
          f.close
          nil
        else
          f
        end
      end
      
      def << (buf)
        b= '0000'
        raise unless WriteFile.call(@handle, buf, buf.size, b, 0)
      end
      
      def close
        CloseHandle @handle
        @handle= nil
      end
      
      def getc
        read(1)[0]
      end
      
      def read(size)
        r= ''
        while size>0
          bytes_read= '0000'
          raise if size > 200000000 # 200MB limit - anything higher means we have a bug
          buf= 0.chr * size
          raise unless ReadFile(@handle, buf, size, bytes_read, 0)
          bytes_read= bytes_read.unpack('L')[0]
          if bytes_read == 0
            return r
          else
            r<< buf[0..(bytes_read-1)]
            size -= bytes_read
          end
        end
        r
      end
      
      def seek(amount,whence=IO::SEEK_SET)
        method= case whence
          when IO::SEEK_END then 2
          when IO::SEEK_CUR then 1
          when IO::SEEK_SET then 0
          else raise
        end        
        raise if SetFilePointer.call(@handle, amount, 0, method) == 0xFFFFFFFF
      end
      
      def size
        h= '0000'
        l= GetFileSize(@handle,h)
        raise if l == INVALID_FILE_SIZE
        #h= h.unpack('L')[0]
        l# | (h << 32)
      end
      
      def stat
        self
      end
      
      def tell
        SetFilePointer.call(@handle, 0, 0, 1)
      end
      
      private
      
      def initialize(handle)
        @handle= handle
      end
    end # class UFile
    
  end
end
