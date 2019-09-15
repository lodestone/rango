require 'oj'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new :rspec

task :default => [:build_opal_modules, :rspec, :print_coverage]

task :build_opal_modules do
  Dir.chdir('opal_modules')
  if File.exist?('yarn.lock')
    system('env -i PATH=$PATH yarn upgrade')
  else
    system('env -i PATH=$PATH yarn install')
  end
  system('env -i PATH=$PATH bundle update')
  system('env -i PATH=$PATH yarn run build')
  Dir.chdir('..')
end

task :build_package => 'build_opal_modules' do
  system('gem build arango-driver.gemspec')
end

task :print_coverage do
  data = Oj.load(File.read('coverage/.last_run.json'), mode: :strict)
  puts "Coverage: #{data['result']['covered_percent']}%"
end
