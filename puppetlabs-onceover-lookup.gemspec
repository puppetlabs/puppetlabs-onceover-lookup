# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "puppetlabs-onceover/lookup/version"

Gem::Specification.new do |spec|
  spec.name          = "puppetlabs-onceover-lookup"
  spec.version       = PuppetlabsOnceover::Lookup::VERSION
  spec.authors       = ["Puppet, Inc."]
  spec.email         = ["modules-team@puppet.com"]
  spec.license       = "Apache-2.0"

  spec.summary       = %q{lookup plugin for puppetlabs-onceover}
  spec.homepage      = "https://github.com/puppetlabs/puppetlabs-onceover-lookup"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new('>= 3.2')

  spec.add_dependency 'puppetlabs-onceover', '~> 5.0', '>= 5.0.4'
  spec.add_dependency 'rake', '~> 13.3'
  spec.add_dependency 'rspec', '~> 3.13'
end
