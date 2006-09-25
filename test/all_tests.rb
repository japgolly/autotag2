require 'test/unit/ui/console/testrunner'
Dir.glob('test/*_test.rb').each {|f| require f}

module Autotag
  class UnitTests
    
    def self.suite
      run_last= 'FullTest'
      suite= Test::Unit::TestSuite.new('Autotag')
      class_names= Object.constants.sort
      if class_names.include?(run_last)
        class_names.delete run_last
        class_names<< run_last
      end
      class_names.map{|c|eval c}.select{|c|c.is_a?(Class) && c.superclass == TestCase}.each {|c|
        puts "Loading #{c}"
        suite<< c.suite
      }
      puts "\n"
      suite
    end
    
  end
end

Test::Unit::UI::Console::TestRunner.run(Autotag::UnitTests)
