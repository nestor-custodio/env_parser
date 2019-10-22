
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'env_parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'env_parser'
  spec.version       = EnvParser::VERSION
  spec.authors       = ['Nestor Custodio']
  spec.email         = ['sakimorix@gmail.com']

  spec.summary       = 'A tool for painless parsing and validation of environment variables.'
  spec.homepage      = 'https://github.com/nestor-custodio/env_parser'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'yard'

  spec.add_dependency 'activesupport', '>= 5.0.0'
  spec.add_dependency 'chronic'
  spec.add_dependency 'chronic_duration'
end
