require_relative 'lib/arango/version.rb'

Gem::Specification.new do |s|
  s.name        = 'arango'
  s.version	    = '3.0.0'
  s.authors     = ['Stefano Martin', 'Jan Biedermann']
  s.email       = ['stefano@seluxit.com', 'jan@kursator.de']
  s.homepage    = 'https://github.com/isomorfeus/arango'
  s.license     = 'MIT'
  s.summary     = 'A simple ruby client for ArangoDB >= 3.5'
  s.description = "Ruby driver for ArangoDB's HTTP API"
  s.require_paths = ['lib']
  s.files         = `git ls-files -- {lib,LICENSE,README.md}`.split("\n")
  s.add_dependency 'activesupport', '~> 5.2'
  s.add_dependency 'connection_pool', '~> 2.2.2', '>=  2.2.2'
  s.add_dependency 'oj', '>= 3.9.0'
  s.add_dependency 'typhoeus', '~> 1.3.1'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rspec', '~> 3.8.0'
end
