# encoding: utf-8
require 'optparse'
require 'autotag/unicode_io'
require 'autotag/utils'

module Autotag
  class Engine
    module CommandLineOptions

      def parse_commandline!(args)
        @runtime_options= {
          :debug => nil,
          :force => false,
          :pretend => false,
          :quiet => false,
        }

        charset= Utils.get_system_charset(:console)
        args= Iconv.iconv('utf-8',charset,*args) if charset

        OptionParser.new do |opts|
          opts.banner= "Usage: #{File.basename $0} [options] [dirs]"

          opts.on('-DOUTPUT', '--debug=OUTPUT', {'f' => :file, '1' => :stdout, '2' => :stderr}, 'Generate detailed debug information.', 'OUTPUT can be: {file, stdout, stderr} or {f,1,2} for short.') {|v|
            @runtime_options[:debug]= v
          }
          opts.on('-f', '--force', 'Force updates to already up-to-date files.') {|v|
            @runtime_options[:force] = v
          }
          opts.on('-h', '--help', 'Displays this screen.') {
            die! opts
          }
          opts.on('-p', '--pretend', 'Only pretend to update files. No changes to any files will be made.') {|v|
            @runtime_options[:pretend] = v
          }
          opts.on('-q', '--quiet', 'Do not display any output.') {|v|
            @runtime_options[:quiet] = v
          }
        end.parse!(args)

        unless args.empty?
          @specified_dirs= args.uniq
          @specified_dirs.each {|d| die! "'#{d}' is not a valid directory." unless UnicodeIO.directory?(d)}
        end

      end

      private

      def die!(msg)
        outstr= $stdout
        outstr.puts Autotag::TITLE_AND_VERSION
        outstr.puts Autotag::COPYRIGHT
        outstr.puts "\n"
        outstr.puts msg
        exit 1
      end

    end # module CommandLineOptions
  end # class Engine
end # module Autotag
