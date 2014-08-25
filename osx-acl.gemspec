# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'osx/acl/version'

Gem::Specification.new do |spec|
  spec.name          = "osx-acl"
  spec.version       = Osx::Acl::VERSION
  spec.authors       = ["Kyle Crawford"]
  spec.email         = ["kcrwfrd@gmail.com"]
  spec.summary       = %q{OS X ACL reading and manipulation}
  spec.description   = %q{OS X ACL reading and munipluation using ffi and C acl API}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
