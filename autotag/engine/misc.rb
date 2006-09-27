module Autotag
  class Engine
    module Misc
      
      def advanced_glob(type, match_patterns, ignore_patterns)
        files= Dir.glob('*', File::FNM_DOTMATCH) - ['.','..']
        case type
        when :dir then files.delete_if {|d| not File.stat(d).directory?}
        when :file then files.delete_if {|d| not File.stat(d).file?}
        else raise
        end
        matches= []
        files_utf= {}
        files.each{|f| files_utf[f]= filename2utf8(f)}
        files_utf.each{|f,f_utf8|
          ignore= false
          ignore_patterns.each{|p| ignore ||= !(f_utf8 !~ p) }
          match_patterns.each{|p|
            if f_utf8 =~ p
              matches<< [f,f_utf8,p]
              break
            end
          } unless ignore
        }
        matches
      end
      
      def delete_temp_file
        File.delete(temp_filename) if File.exists?(temp_filename)
      end
      
      def each_matching(type, match_patterns, ignore_patterns, &block)
        advanced_glob(type, match_patterns, ignore_patterns).each {|f,f_utf8,p|
          with_metadata{ block.call f, p}
        }
      end
      
      def filename2utf8(filename)
        # TODO All filenames are considered shift-jis
        @iconv ||= Iconv.new('utf-8','shift-jis')
        @iconv.iconv(filename)
      end
      
      def in_dir(dir)
        Dir.chdir(dir) {
          delete_temp_file
          yield
        }
      end
      
      @@temp_filename= 'autotag - if autotag is not running you can safely delete this file.tmp'.freeze
      def temp_filename
        @@temp_filename
      end
      
      def with_metadata
        mbackup= @metadata.deep_clone
        yield
        @metadata= mbackup.deep_clone
      end
      
    end # module Misc
  end # class Engine
end # module Autotag
