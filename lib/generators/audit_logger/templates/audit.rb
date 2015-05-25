unless Rails.env.test?
  ::ERROR_LOG = AuditLogger::Audit.new('error', timestamp: true, pid: true, severity: true, thread: true)

  # ::AUDIT_NULL   = AuditLogger::Audit.new(File::NULL)
  # ::AUDIT_STDOUT = AuditLogger::Audit.new(STDOUT)
  # ::PRODUCT_LOG  = AuditLogger::Audit.new('product')
end
