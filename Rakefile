# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "pgmodelgen"
  gem.homepage = "http://github.com/bjornblomqvist/pgmodelgen"
  gem.license = "LGPL"
  gem.summary = %Q{Rake task that generates/updates activerecord models based on current schema in the postgresql DB}
  gem.description = %Q{Rake task that generates/updates activerecord models based on current schema in the postgresql DB}
  gem.email = "darwin@bits2life.com"
  gem.authors = ["Bjorn Blomqvist"]
  gem.files = FileList['lib/**/*.rb','lib/**/*.rake'].to_a
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "pgmodelgen #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
