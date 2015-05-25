unless Rails.env.test?
  log_path_with_env = "#{Rails.root}/log/audit/#{Rails.env}"

  ::ERROR_LOG = AuditLogger::Audit.new("#{log_path_with_env}_error.log", timestamp: true, pid: true, severity: true, thread: true)

  # ::AUDIT_NULL   = AuditLogger::Audit.new(File::NULL)
  # ::AUDIT_STDOUT = AuditLogger::Audit.new(STDOUT)
  # ::PRODUCT_LOG  = AuditLogger::Audit.new("#{log_path_with_env}_product.log")
end
