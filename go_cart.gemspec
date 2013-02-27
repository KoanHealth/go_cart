# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'go_cart/version'

Gem::Specification.new do |gem|
	gem.name = 'go_cart'
  gem.version = GoCart::VERSION
	gem.authors = ['Brad Smalling']
	gem.email = ['brad smalling @ koanhealth com']
	gem.homepage = 'https://github.com/KoanHealth/go_cart'
	gem.summary = 'Load flat-files into database tables.'
	gem.description = 'GoCart is a ruby library for flat-file field loading.'

	gem.files = `git ls-files`.split($/)
	gem.executables = ['go_cart.rb']
	gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
	gem.require_paths = ['lib']

	gem.add_dependency 'rake'
	gem.add_dependency 'colorize'
	gem.add_dependency 'activesupport'
	gem.add_dependency 'activerecord'
	gem.add_dependency 'activerecord-import'
	gem.add_dependency 'pg'

	gem.add_development_dependency 'rspec'
	gem.add_development_dependency 'simplecov'

end