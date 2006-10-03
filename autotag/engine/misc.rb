require 'autotag/engine/config'

module Autotag
  class Engine
    module Misc
      include Config
      
      def advanced_glob(type, match_patterns, ignore_patterns, options={})
        file_extentions= options[:file_extentions]
        files= if file_extentions
            Dir.glob("*.{#{file_extentions}}")
          else
            Dir.glob(options[:glob] || '*', File::FNM_DOTMATCH) - ['.','..']
          end
        case type
        when :dir then files.delete_if {|d| not File.directory?(d)}
        when :file then files.delete_if {|d| not File.file?(d)}
        else raise
        end
        matches= []
        files_utf= {}
        files.each{|f| files_utf[f]= filename2utf8(f)}
        files_utf.keys.ci_sort.each{|f|
          f_utf8= files_utf[f]
          ext= nil
          if file_extentions
            f_utf8 =~ /^(.+)\.([^\.]+)$/
            f_utf8,ext = $1,$2
          end
          ignore= false
          ignore_patterns.each{|p| ignore ||= !(f_utf8 !~ p) }
          match_patterns.each{|p|
            if f_utf8 =~ p
              matches<< [f,f_utf8,p,ext]
              break
            end
          } unless ignore
        }
        matches
      end
      
      def delete_temp_file
        File.delete(temp_filename) if File.exists?(temp_filename)
      end
      
      def each_matching(type, match_patterns, ignore_patterns, options={}, &block)
        advanced_glob(type, match_patterns, ignore_patterns, options).each {|f,f_utf8,p,ext|
          with_metadata{ block.call f, p}
        }
      end
      
      def filename2utf8(filename)
        @iconv ||= Iconv.new('utf-8',filename_charset)
        @iconv.iconv(filename)
      end
      
      def find_highest_numeric_value(array_of_hashs, attr)
        num_array= array_of_hashs.map{|o|o[attr]}.reject{|x|x !~ /^\d+$/}
        return nil if num_array.empty?
        num_array.map{|x|x.to_i}.sort.last.to_s
      end
      
      def in_dir(dir)
        Dir.chdir(dir) {
          delete_temp_file
          yield
        }
      end
      
      # Turns the results of advanced_glob() to a hash like this:
      # {
      #   '01 - Hello.mp3' => {:track => 'Hello', :track_number => '1', :_format => 'mp3'},
      #   '02 - Happy.mp3' => {:track => 'Happy', :track_number => '2', :_format => 'mp3'},
      # }
      def map_advanced_glob_results(aglob_results, remove_leading_zeros_from)
        r= {}
        aglob_results.each {|f,fu,p,ext|
          raise unless fu =~ p
          o= yield($~)
          o[:_format]= ext
          remove_leading_zeros! o[remove_leading_zeros_from] if remove_leading_zeros_from
          r[f]= o
        }
        r
      end
      
      def remove_leading_zeros!(str)
        str.gsub!(/^0+(?=.)/,'')
      end
      
      def temp_filename
        TEMP_FILENAME
      end
      
      def with_metadata
        mbackup= @metadata.deep_clone
        yield
        @metadata= mbackup.deep_clone
      end
      
      TEMP_FILENAME= 'autotag - if autotag is not running you can safely delete this file.tmp'.freeze
      
    end # module Misc
  end # class Engine
end # module Autotag
