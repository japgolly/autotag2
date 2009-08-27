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
        f= new(File.open(filename,mode))
        if block_given?
          begin
            yield f
          ensure
            f.close
          end
          nil
        else
          f
        end
      end
      
      def <<(buf) @f<< buf end
      def close; @f.close end
      def getc; @f.getc end
      def read(size) @f.read(size) end
      def seek(amount,whence=IO::SEEK_SET) @f.seek(amount,whence) end
      def size; @f.stat.size end
      def stat; @f.stat end
      def tell; @f.tell end
      
      private
      
      def initialize(f)
        @f= f
      end
    end # class UFile
    
  end
end
