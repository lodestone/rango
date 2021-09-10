require_relative 'lib/arango/version.rb'

Gem::Specification.new do |s|
  s.name        = 'arango-driver'
  s.version	    = Arango::VERSION
  s.authors     = ['Stefano Martin', 'Jan Biedermann']
  s.email       = ['jan@kursator.de']
  s.homepage    = 'https://github.com/isomorfeus/arango-driver'
  s.license     = 'MIT'
  s.summary     = 'A simple ruby client for ArangoDB >= 3.5'
  s.description = "Ruby driver for ArangoDB's HTTP API"
  s.require_paths = ['lib']
  s.files         = `git ls-files -- {lib,LICENSE,README.md}`.split("\n") + %w[arango_opal.js]
  s.add_dependency 'activesupport', ['>= 5.2', '< 6.1']
  s.add_dependency 'escape_utils', '~> 1.2.1'
  s.add_dependency 'isomorfeus-redux', '~> 4.0.22'
  s.add_dependency 'oj', '>= 3.10.0'
  s.add_dependency 'opal', '>= 1.0.0'
  s.add_dependency 'typhoeus', '~> 1.4.0'
  s.add_dependency 'method_source'
  s.add_dependency 'parser'
  s.add_dependency 'unparser'
  s.add_dependency 'uri_template', '~> 0.7.0'
  s.add_dependency 'zeitwerk', '~> 2.4.0'
  s.add_development_dependency 'benchmark-ips', '>= 0.9.11'
  s.add_development_dependency 'opal-webpack-loader', '>= 0.9.11'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.8.0'
  s.add_development_dependency 'simplecov', '~> 0.17.0'
  s.add_development_dependency 'yard', '~> 0.9.20'
end
