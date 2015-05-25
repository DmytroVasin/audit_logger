require 'audit_logger/version'
require 'audit_logger/railtie' if defined?(Rails)
require 'rails'

require 'audit_logger/audit_message_styles'

module AuditLogger
  class Audit < Logger
    include AuditLogger::AuditMessageStyles

    attr_reader :log_file_name,
                :al_timestamp,
                :al_pid,
                :al_severity,
                :al_shift_age,
                :al_shift_size,
                :al_thread

    def initialize(file_name=STDOUT, opts = {})
      @al_timestamp  = opts[:timestamp] || true
      @al_pid        = opts[:pid] || false
      @al_severity   = opts[:severity] || false
      @al_thread     = opts[:thread] || false
      @al_shift_age  = opts[:shift_age] || 0
      @al_shift_size = opts[:shift_size] || 2*1024*1024


      log_file = init_log_file(file_name)

      super(log_file, al_shift_age, al_shift_size)
    end

    def audit_with_resque(block_name, log_exception_only: false, do_raise: false, &block)
      audit(block_name, log_exception_only: log_exception_only, do_raise: do_raise, &block)
    end

    def audit(block_name, log_exception_only: false, do_raise: true, &block)
      perform_with_audit(block_name, log_exception_only: log_exception_only, do_raise: do_raise, &block)
    end

    private

    def perform_with_audit(block_name, log_exception_only:, do_raise:, &block)
      begin
        wrap_with_message(block_name, before: !log_exception_only, after: !log_exception_only, &block)
      rescue Exception => e
        wrap_with_message(block_name, before: log_exception_only, after: true) do
          log_exception(block_name, e)
        end

        raise(e) if do_raise
      end
    end

    def init_log_file(file_name)
      if file_name == File::NULL || file_name == STDOUT
        @log_file_name = 'IO'
        file_name
      else
        @log_file_name = "#{file_name}.log"
        FileUtils.mkdir_p("#{default_audit_path}")

        File.open("#{default_audit_path}/#{log_file_name}", 'a').tap {|file|
          file.sync = true
        }
      end
    end

    def wrap_with_message(block_name, before:, after:, &block)
      message_block(block_name, opening: true) if before
      result = block.call if block_given?
      message_block(block_name, opening: false) if after

      result
    end

    def log_exception(block_name, e)
      error ' ERROR OCCURRED. See details in the Error Log.'

      ERROR_LOG.audit("#{block_name} // #{log_file_name}") do
        begin
          write_exception_details(e)
        rescue Exception => e
          error " Error during writing to log: #{e}"
        end
      end
    end

    def filter_call_stack_trace(e)
      e.backtrace.map { |trace_level|
        trace_level.sub(rails_root, '') if rails_root.in?(trace_level)
      }.compact
    end

    def write_exception_details(e)
      record_errors = "ActiveRecord errors: #{e.record.errors.messages}" if e.is_a?(ActiveRecord::RecordInvalid) || e.is_a?(ActiveRecord::RecordNotSaved)

      if e.cause
        ERROR_LOG.error "AR SAVE ERROR: #{record_errors}" if record_errors
        ERROR_LOG.error "#{exception_message(e)} Cause exception:"
        write_exception_details(e.cause)
      else
        ERROR_LOG.error "#{exception_message(e)} Call stack:"
        call_stack_output_messages(filter_call_stack_trace(e))
      end
    end

    def rails_root
      @rails_root ||= Rails.root.to_s
    end

    def default_audit_path
      "#{rails_root}/log/#{folder_name}/#{Rails.env}"
    end

    def folder_name
      'audit'
    end
  end
end
