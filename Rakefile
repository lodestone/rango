require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new :rspec

task :default => :rspec

task :build_package do
  #Dir.chdir('opal_modules')
  #system('yarn run build')
  #Dir.chdir('..')
  system('gem build arango-driver.gemspec')
end