require_relative 'lib/arango/version.rb'

Gem::Specification.new do |s|
  s.name        = 'arango-driver'
  s.version     = Arango::VERSION
  s.authors     = ['Stefano Martin', 'Jan Biedermann', 'Klaus Kämpf']
  s.email       = ['kkaempf@suse.de']
  s.homepage    = 'https://github.com/kkaempf/arango-driver'
  s.license     = 'MIT'
  s.summary     = 'A simple ruby client for ArangoDB >= 3.8'
  s.description = "Ruby driver for ArangoDB's HTTP API"
  s.require_paths = ['lib']
  s.files         = `git ls-files -- {lib,LICENSE,README.md}`.split("\n") + %w[arango_opal.js]
  s.add_dependency 'activesupport', '~> 6.0'
  s.add_dependency 'escape_utils', '~> 1.2'
  s.add_dependency 'isomorfeus-redux', '~> 4.0'
  s.add_dependency 'oj', '~> 3.10'
  s.add_dependency 'opal', '~> 1.0'
  s.add_dependency 'typhoeus', '~> 1.4'
  s.add_dependency 'method_source', '~> 1'
  s.add_dependency 'parser', '~> 3.0'
  s.add_dependency 'unparser', '~> 0.6'
  s.add_dependency 'uri_template', '~> 0.7'
  s.add_dependency 'zeitwerk', '~> 2.4'
  s.add_development_dependency 'benchmark-ips', '~> 2.9'
  s.add_development_dependency 'opal-webpack-loader', '~> 0.9'
  s.add_development_dependency 'rake', '~> 13'
  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'simplecov', '~> 0.17'
  s.add_development_dependency 'yard', '~> 0.9'
end
