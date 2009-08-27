require 'Win32API'
require 'windows/handle'
require 'windows/directory'
require 'windows/file'

module Autotag
  module UnicodeIO
    include Autotag::Unicode
    include Windows::Directory
    include Windows::File
    extend self
    
    DeleteFileW        = Win32API.new('kernel32', 'DeleteFileW', 'P', 'I')
    FindFirstFileW     = Win32API.new('kernel32','FindFirstFileW','PP','I') # HANDLE FindFirstFileW(LPCWSTR lpFileName, LPWIN32_FIND_DATAW lpFindFileData);
    FindNextFileW      = Win32API.new('kernel32','FindNextFileW','IP','I') # BOOL FindNextFileW(HANDLE hFindFile, LPWIN32_FIND_DATAW lpFindFileData);
    FindClose          = Win32API.new('kernel32','FindClose','I','I') # BOOL FindClose(HANDLE hFindFile)
    GetFileAttributesW = Win32API.new('kernel32', 'GetFileAttributesW', 'P', 'L')
    MoveFileExW        = Win32API.new('kernel32', 'MoveFileExW', 'PPL', 'I') # BOOL WINAPI MoveFileExW( LPCWSTR source, LPCWSTR dest, DWORD flag )
    SetFilePointer     = Win32API.new('kernel32','SetFilePointer','LLPL','L') # DWORD SetFilePointer(HANDLE hFile, LONG lDistanceToMove, PLONG lpDistanceToMoveHigh, DWORD dwMoveMethod);
    FILE_ATTRIBUTE_DIRECTORY= 0x00000010
    MOVEFILE_COPY_ALLOWED = 0x00000002
    
    def chdir(dir)
      if block_given?
        old= pwd
        chdir(dir)
        yield
        chdir(old)
      else
        raise if SetCurrentDirectoryW.call(prepro_fn(dir)) == 0
      end
    end
    
    def delete(f)
      DeleteFileW.call(prepro_fn(f)) != 0
    end
    
    def directory?(f)
      v= GetFileAttributesW.call(prepro_fn(f))
      raise if v == INVALID_FILE_ATTRIBUTES
      (v & FILE_ATTRIBUTE_DIRECTORY) != 0
    end
    def file?(f)
      v= GetFileAttributesW.call(prepro_fn(f))
      raise if v == INVALID_FILE_ATTRIBUTES
      (v & FILE_ATTRIBUTE_DIRECTORY) == 0
    end
    
    def pwd
      buf= 0.chr * 1024
      GetCurrentDirectoryW(1024,buf)
      buf =~ Regexp.new('^((?:..)+?)\0\0',Regexp::MULTILINE,'N')
      to8($1).gsub('\\','/')
    end
    
    def rename(from,to,force=false)
      delete(to) if force
      raise if MoveFileExW.call(prepro_fn(from), prepro_fn(to), MOVEFILE_COPY_ALLOWED) == 0
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
        f= tolerant_utf8_to_filename(f).downcase.sub(/^.*\//,'')
        file_match_patterns.each{|p|
          match ||= ::File.fnmatch?(p,f,flags)
        }
        
        match
      }.sort
    end
  
    private
    
    def tolerant_utf8_to_filename(filename)
      unless @tolerant_utf8_to_filename
        filename_charset= Utils.get_system_charset(:filenames)
        @tu2f_iconv= Iconv.new(filename_charset,'utf-8') if filename_charset
        @tolerant_utf8_to_filename= true
      end
      
      return filename unless @tu2f_iconv
        
      result= ''
      begin
        result<< @tu2f_iconv.iconv(filename)
      rescue Iconv::IllegalSequence => e
        result<< e.success
        ch, filename = e.failed.split(//, 2)
        result<< '?'
        retry
      end
      result
    end
      
    def prepro_fn(f)
      to16(f.gsub('/','\\') + 0.chr)
    end
    
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
        buf= '0'*1024
        h= FindFirstFileW.call(to16("*\0"), buf)
        unless h == -1
          pat= Regexp.new('^.{44}((?:..)+?)\0\0',Regexp::MULTILINE,'N')
          begin
            buf =~ pat
            f= to8($1)
            unless f=='.' || f=='..'
              state[:files]<< (full_dir ? "#{full_dir}/" : '') + f
              glob_(recurse_levels,f,state,full_dir ? full_dir.dup : nil,recurse_dot_dirs) if allow_recurse && (buf[0..3].unpack('L')[0] & FILE_ATTRIBUTE_DIRECTORY) != 0 && (recurse_dot_dirs or f[0]!=46)
            end
            buf= '0'*1024
          end while FindNextFileW.call(h,buf) != 0
          raise if FindClose.call(h) == 0
        end
      end # chdir
      state[:depth] -= 1
    end
    
    public
    class UFile
      extend Unicode
      include Windows::Handle
      include Windows::File
      
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
