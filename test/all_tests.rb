require 'test/unit/ui/console/testrunner'
Dir.glob('test/*_test.rb').each {|f| require f}

module Autotag
  class UnitTests
    
    def self.suite
      suite= Test::Unit::TestSuite.new('Autotag tests')
      Object.constants.sort.map{|c|eval c}.select{|c|c.is_a?(Class) && c.superclass == TestCase}.each {|c|
        puts "Loading #{c}"
        suite<< c.suite
      }
      puts "\n"
      suite
    end
    
  end
end

Test::Unit::UI::Console::TestRunner.run(Autotag::UnitTests)
