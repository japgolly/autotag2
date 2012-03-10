require 'rake'
require 'rake/testtask'

task :default => [:test]

desc "Run unit tests."
task :test do
  Rake::TestTask.new(:test) do |t|
    t.test_files= FileList['test/*_test.rb']
    t.verbose= true
  end
end

task :stats do
  ruby 'code_stats.rb'
end
