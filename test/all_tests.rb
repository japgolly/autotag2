Dir.glob('test/*_test.rb').each {|f| require f}

module Autotag
  class UnitTests
    
    def self.suite
      suite= Test::Unit::TestSuite.new('Autotag')
      test_classes= Object.get_all_subclasses_of(TestCase)
      
      run_last= FullTest
      if test_classes.include?(run_last)
        test_classes.delete run_last
        test_classes<< run_last
      end
      
      test_classes.each {|c|
        puts "Loading #{c}"
        suite<< c.suite
      }
      puts "\n"
      suite
    end
    
  end
end

if __FILE__ == $0
  require 'test/unit/ui/console/testrunner'
  Test::Unit::UI::Console::TestRunner.run(Autotag::UnitTests)
end
