task :default => [:test]

task :test do
  ruby "test/all_tests.rb"
end

task :ci_test do
  require 'rubygems'
  gem 'ci_reporter'
  require 'ci/reporter/rake/test_unit'
  Rake::Task["ci:setup:testunit"].execute
  Rake::Task["test"].execute
end

