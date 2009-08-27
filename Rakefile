require 'rake'
require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs<< "test"
  t.test_files= FileList['test/*_test.rb']
  t.verbose= true
end


task :ci_test do
  require 'rubygems'
  gem 'ci_reporter'
  require 'ci/reporter/rake/test_unit'
  Rake::Task["ci:setup:testunit"].execute
  Rake::Task["test"].execute
end

