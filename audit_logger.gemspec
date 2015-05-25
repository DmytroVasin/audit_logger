# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'audit_logger/version'

Gem::Specification.new do |spec|
  spec.name          = "audit_logger"
  spec.version       = AuditLogger::VERSION
  spec.authors       = ["Vasin Dmitriy"]
  spec.email         = ["vasindima779@gmail.com"]

  spec.summary       = "Audit logger for Rails apps."
  spec.description   = "Logger which creates additional files for a more orderly logging information in Rails apps."
  spec.homepage      = "https://github.com/DmytroVasin/audit_logger"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'rails', ">= #{AuditLogger::RAILS_VERSION}"
  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'railties', ">= #{AuditLogger::RAILS_VERSION}"
end
