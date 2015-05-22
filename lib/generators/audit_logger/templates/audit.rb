unless Rails.env.test?
  log_path_with_env = "#{Rails.root}/log/audit/#{Rails.env}"

  ::ERROR_LOG = Audit::AuditLogger.new("#{log_path_with_env}_error.log", timestamp: true, pid: true, severity: true, thread: true)

  # ::AUDIT_NULL   = Audit::AuditLogger.new(File::NULL)
  # ::AUDIT_STDOUT = Audit::AuditLogger.new(STDOUT)
  # ::PRODUCT_LOG  = AuditLogger::Audit.new("#{log_path_with_env}_product.log")
end
