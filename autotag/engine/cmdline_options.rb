require 'optparse'

module Autotag
  class Engine
    module CommandLineOptions
      
      def parse_commandline!(args)
        @runtime_options= {
          :pretend => false,
          :force => false,
          :quiet => false,
        }
        
        OptionParser.new do |opts|
          opts.banner= "Usage: #{File.basename $0} [options] [dirs]"
          
          opts.on('-f', '--force', 'Force updates to already up-to-date files.') {|v|
            @runtime_options[:force] = v
          }
          opts.on('-h', '--help', 'Displays this screen.') {
            $stderr.puts opts
            exit 1
          }
          opts.on('-p', '--pretend', 'Only pretend to update files. No changes to any files will be made.') {|v|
            @runtime_options[:pretend] = v
          }
          opts.on('-q', '--quiet', 'Do not display any output.') {|v|
            @runtime_options[:quiet] = v
          }
        end.parse!(args)
        
        raise 'Dirs in ARGV isnt implemented yet.' unless args.empty?
      end
    
    end # module CommandLineOptions
  end # class Engine
end # module Autotag
