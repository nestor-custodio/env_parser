
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "env_loader/version"

Gem::Specification.new do |spec|
  spec.name          = "env_loader"
  spec.version       = EnvLoader::VERSION
  spec.authors       = ["Nestor Custodio"]
  spec.email         = ["sakimorix@gmail.com"]

  spec.summary       = %q{A tool for painless parsing and validation of environment variables.}
  spec.homepage      = "https://github.com/nestor-custodio/env_loader"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
