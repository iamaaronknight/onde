# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'onde/version'

Gem::Specification.new do |s|
  s.name                  = "onde"
  s.version               = Onde::VERSION
  s.authors               = ["Aaron Knight"]
  s.email                 = ["iamaaronknight@gmail.com"]
  s.homepage              = "https://github.com/iamaaronknight/onde"
  s.summary               = "A tool for managing file and directory paths in your code"
  s.description           = "Onde is a tool for managing file and directory paths in your code"
  s.files                 = `git ls-files app lib`.split("\n")
  s.platform              = Gem::Platform::RUBY
  s.require_paths         = ['lib']
  s.required_ruby_version = ">= 2.1.0"
  s.licenses              = ["MIT"]
end
