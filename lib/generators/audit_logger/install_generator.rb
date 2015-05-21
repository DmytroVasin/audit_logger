require 'rails/generators'

module AuditLogger
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    desc "Generates a model with the given NAME (if one does not exist) with devise configuration plus a migration file and devise routes."

    def copy_initializer
      copy_file "audit.rb", "config/initializers/audit.rb"
    end
  end
end
