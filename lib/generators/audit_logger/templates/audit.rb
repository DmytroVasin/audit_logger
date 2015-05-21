Audit.setup do |config|
  log_path_with_env = "#{Rails.root}/log/audit/#{Rails.env}"

  ::ERROR_LOG        = Audit::AuditLogger.new("#{log_path_with_env}_error.log")

  ::PRODUCT_LOG      = Audit::AuditLogger.new("#{log_path_with_env}_product.log", timestamp: true, pid: true, severity: true)
  ::CATEGORY_LOG     = Audit::AuditLogger.new("#{log_path_with_env}_category.log")
  ::DB_MIGRATION_LOG = Audit::AuditLogger.new("#{log_path_with_env}_db_migration.log")
end
