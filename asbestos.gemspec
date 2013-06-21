# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'asbestos/metadata'

Gem::Specification.new do |spec|
  spec.name          = "asbestos"
  spec.version       = Asbestos::VERSION
  spec.authors       = ["Michael Shapiro"]
  spec.email         = ["koudelka@ryoukai.org"]
  spec.description   = %q{Asbestos is a declarative DSL for building firewall rules (iptables, at this point)}
  spec.summary       = %q{Declarative firewall(iptables) DSL.}
  spec.homepage      = Asbestos::HOMEPAGE
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_dependency "system-getifaddrs", "~> 0.1.5"
end
