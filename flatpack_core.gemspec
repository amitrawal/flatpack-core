# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flatpack/core/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Joe Stelmach"]
  gem.email         = ["joe@getperka.com"]
  gem.description   = %q{Write a gem description}
  gem.summary       = %q{Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "flatpack_core"
  gem.require_paths = ["lib"]
  gem.version       = Flatpack::Core::VERSION
  gem.add_dependency('json', '~> 1.7')
  gem.add_dependency('uuidtools', '~> 2.1')
  gem.add_dependency('activesupport', "= 2.3.8")
  gem.add_development_dependency "rspec", "~> 2.6"
end
