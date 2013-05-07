# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "pgmodelgen"
  s.version = "0.4.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bjorn Blomqvist"]
  s.date = "2013-05-07"
  s.description = "Rake task that generates/updates activerecord models based on current schema in the postgresql DB"
  s.email = "darwin@bits2life.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    "lib/metadata_extractor.rb",
    "lib/pgmodelgen.rb",
    "lib/pgmodelgen/railtie.rb",
    "lib/tasks/pgmodelgen.rake"
  ]
  s.homepage = "http://github.com/bjornblomqvist/pgmodelgen"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Rake task that generates/updates activerecord models based on current schema in the postgresql DB"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
  end
end

