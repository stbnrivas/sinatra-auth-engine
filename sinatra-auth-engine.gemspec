# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
#require 'sinatra/auth/engine/version'

Gem::Specification.new do |spec|
  spec.name          = "sinatra-auth-engine"
  spec.version       = '0.1.0'
  spec.authors       = ["stbnrivas"]
  spec.email         = ["stbnrivas@gmail.com\n"]

  spec.summary       = %q{authentication engine for sinatra using sequel database toolkit}
  spec.description   = %q{features like: authenticable model, roles authentication support, multiples tokens to authenticate, block by exceed max attempted login failed, token authenticate valid until, clean migration to add or remove this gem }
  spec.homepage      = "http://github.com/stbnrivas/sinatra-auth-engine"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.9.1"
  spec.add_development_dependency "minitest-debugger", "~> 1.0.3"
  spec.add_development_dependency "bcrypt", "~> 3.1.11"
  spec.add_development_dependency "sinatra", "~> 1.4.7"
  spec.add_development_dependency "sequel", "~> 4.39.0"
end
