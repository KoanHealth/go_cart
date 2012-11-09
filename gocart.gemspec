# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'go_cart/version'

Gem::Specification.new do |gem|
	gem.name = 'GoCart'
  gem.version = GoCart::VERSION
	gem.authors = ["Brad Smalling"]
	gem.email = ["brad smalling @ koanhealth com"]
	gem.homepage = 'https://github.com/KoanHealth/gocart'
	gem.summary = 'GoCart is a ruby library for flat-file field loading.'

	gem.files = `git ls-files`.split($/)
	gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
	gem.require_paths = ["lib"]

	gem.add_dependency "rake"
	gem.add_dependency "activerecord"
	gem.add_dependency "activerecord-import"

	gem.add_development_dependency "rspec"

end