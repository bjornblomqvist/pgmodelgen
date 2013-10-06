require 'rubygems'
require 'pg'
require 'rspec'

RSpec.configure do |config|

  config.before(:suite) do
    DB_CONNECTION = PGconn.open(:dbname => 'pgmodelgen_test')
  end

  config.after(:suite) do
    DB_CONNECTION.close
  end

  config.before(:each) do
    DB_CONNECTION.exec("start transaction;")
  end

  config.after(:each) do
    DB_CONNECTION.exec("rollback;")
  end
end


require_relative '../lib/metadata_extractor'
