# encoding: utf-8
require 'autotag/engine/config'
require 'autotag/unicode_io'
require 'autotag/utils'
require 'iconv'

module Autotag
  class Engine
    module Misc
      include Config

      def advanced_glob(type, match_patterns, ignore_patterns, options={})
        file_extentions= options[:file_extentions]
        files= if file_extentions
            UnicodeIO.glob(0,nil,"*.{#{file_extentions}}")
          else
            UnicodeIO.glob(0,nil,options[:glob],File::FNM_DOTMATCH)
          end
        case type
        when :dir then files.delete_if {|d| not UnicodeIO.directory?(d)}
        when :file then files.delete_if {|d| not UnicodeIO.file?(d)}
        else raise
        end
        matches= []
        files.ci_sort.each{|f|
          ext= nil
          if file_extentions
            f =~ /^(.+)\.([^\.]+)$/u
            base,ext = $1,$2
          else
            base= f
          end
          if p= find_matching_pattern(f,match_patterns,ignore_patterns)
            matches<< [f,base,p,ext]
          end
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

      def find_highest_numeric_value(array_of_hashs, attr)
        num_array= array_of_hashs.map{|o|o[attr]}.reject{|x|x !~ /^\d+$/}
        return nil if num_array.empty?
        num_array.map{|x|x.to_i}.sort.last.to_s
      end

      def find_matching_pattern(str, match_patterns, ignore_patterns)
        ignore_patterns.each{|p| return nil if str =~ p}
        match_patterns.each{|p| return p if str =~ p}
        nil
      end

      def in_dir(dir)
        UnicodeIO.chdir(dir) {
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
