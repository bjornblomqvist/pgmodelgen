require 'pgmodelgen'
require 'rails'
module Pgmodelgen
  class Railtie < Rails::Railtie
    railtie_name :pgmodelgen

    rake_tasks do
      load "tasks/pgmodelgen.rake"
    end
  end
end