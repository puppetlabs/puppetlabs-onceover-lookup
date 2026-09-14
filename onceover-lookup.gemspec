# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "onceover/lookup/version"

Gem::Specification.new do |spec|
  spec.name          = "onceover-lookup"
  spec.version       = Onceover::Lookup::VERSION
  spec.authors       = ["Declarative Systems"]
  spec.email         = ["sales@declarativesystems.com"]
  spec.license       = "Apache-2.0"

  spec.summary       = %q{lookup plugin for onceover}
  spec.homepage      = "https://github.com/declarativesystems/onceover-lookup"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new('>= 3.2')

  spec.add_dependency 'onceover', '~> 3'
  spec.add_dependency 'rake', '~> 13.3'
  spec.add_dependency 'rspec', '~> 3.13'
end
