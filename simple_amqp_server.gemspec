# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_amqp_server/version'

Gem::Specification.new do |spec|
  spec.name          = "simple-amqp-server"
  spec.version       = SimpleAmqpServer::VERSION
  spec.authors       = ["Howard Ding"]
  spec.email         = ["hding2@illinois.edu"]
  spec.summary       = %q{Simple way to make an AMQP server}
  spec.description   = %q{Follow some simple conventions to make a simple AMQP server.}
  spec.homepage      = "https://github.com/medusa-project/simple-amqp-server"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'bunny', '1.7.0'
  spec.add_runtime_dependency "logging"
  spec.add_runtime_dependency "uuid"
  spec.add_runtime_dependency "retryable"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
