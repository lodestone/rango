# lib = File.expand_path('../lib', __FILE__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rake"

Gem::Specification.new do |s|
  s.name        = 'arangorb'
  s.version	    = '2.0.1'
  s.authors     = ['Stefano Martin']
  s.email       = ['stefano@seluxit.com']
  s.homepage    = 'https://github.com/StefanoMartin/ArangoRB'
  s.license     = 'MIT'
  s.summary     = 'A simple ruby client for ArangoDB'
  s.description = "Ruby driver for ArangoDB's HTTP API"
  s.platform	   = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.files         = FileList['lib/**/*', 'ArangoRB.gemspec', 'Gemfile', 'LICENSE', 'README.md'].to_a
  s.add_dependency 'httparty', '~> 0.14', '>= 0.14.0'
  s.add_dependency 'oj', '~> 3.6.11', '>=  3.6.11'
  s.add_dependency 'connection_pool', '~> 2.2.2', '>=  2.2.2'
end
