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
  gem.add_dependency('json', '~> 1.7.3')
  gem.add_dependency('uuidtools', '~> 2.1.2')
  gem.add_dependency('i18n', '~> 0.6.0')
  gem.add_dependency('activesupport', "~> 3.0")
  gem.add_development_dependency "rspec", "~> 2.6"
end
