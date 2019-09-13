require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new :rspec

task :default => :rspec

task :build_opal_modules do
  Dir.chdir('opal_modules')
  if File.exist?('yarn.lock')
    system('yarn upgrade')
  else
    system('yarn install')
  end
  system('bundle update')
  system('yarn run build')
  Dir.chdir('..')
end

task :build_package => 'build_opal_modules' do
  system('gem build arango-driver.gemspec')
end