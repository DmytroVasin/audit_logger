module AuditLogger
  class Railtie < ::Rails::Railtie
    generators do
      load "generators/audit_logger/install_generator.rb"
    end
  end
end
