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
  paths = ['lib', 'spec/puppetlabs-onceover']
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

begin
  require 'rubygems'
  require 'github_changelog_generator/task'
rescue LoadError
  # Do nothing if no required gem installed
else
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.exclude_labels = %w[duplicate question invalid wontfix wont-fix skip-changelog github_actions]
    config.user = 'puppetlabs'
    config.project = 'puppetlabs-onceover-lookup'
    gem_version = Gem::Specification.load("#{config.project}.gemspec").version
    config.future_release = "v#{gem_version}"
  end
end
