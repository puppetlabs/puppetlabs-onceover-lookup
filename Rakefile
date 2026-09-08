require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :full_tests

desc "Run unit tests"
task rspec_unit_tests: %i[syntax spec]

desc "Run full set of tests"
task full_tests: [:rspec_unit_tests]

def windows?
  # Ruby only sets File::ALT_SEPARATOR on Windows and the Ruby standard
  # library uses that to test what platform it's on.
  !!File::ALT_SEPARATOR
end

task :syntax do
  paths = ['lib', 'spec/onceover']
  require 'find'
  Find.find(*paths) do |path|
    next unless path =~ /\.rb$/

    if windows?
      sh "ruby -cw #{path} > NUL"
    else
      sh "ruby -cw #{path} > /dev/null"
    end
  end
end
