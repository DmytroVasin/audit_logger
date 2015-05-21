require 'audit_logger/version'
require 'audit_logger/railtie' if defined?(Rails)
require 'rails'

module AuditLogger
  # Your code goes here...
  def self.start
    puts '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  end
end
