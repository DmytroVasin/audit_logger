require 'rails/generators'

module AuditLogger
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    desc 'Generates a file with initial setup of logger instans'

    def copy_initializer
      copy_file 'audit.rb', 'config/initializers/audit.rb'
    end
  end
end
