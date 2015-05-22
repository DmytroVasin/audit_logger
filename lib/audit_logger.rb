require 'audit_logger/version'
require 'audit_logger/railtie' if defined?(Rails)
require 'rails'

require 'audit_logger/audit_message_styles'

module AuditLogger
  class Audit < Logger
    APP_DIR_PATH = Rails.root.to_s

    include AuditLogger::AuditMessageStyles

    attr_reader :log_file_name,
                :al_timestamp,
                :al_pid,
                :al_severity,
                :al_shift_age,
                :al_shift_size,
                :al_thread

    def initialize(file_path=STDOUT, opts = {})
      @al_timestamp  = opts[:timestamp] || true
      @al_pid        = opts[:pid] || false
      @al_severity   = opts[:severity] || false
      @al_thread     = opts[:thread] || false
      @al_shift_age  = opts[:shift_age] || 0
      @al_shift_size = opts[:shift_size] || 2*1024*1024


      log_file = init_log_file(file_path)

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

    def init_log_file(path)
      if path == File::NULL || path == STDOUT
        @log_file_name = 'IO'
        path
      else
        FileUtils.mkdir_p(File.dirname(path)) # IN GEM INITIALIZE! "rails g audit:install" -> creates dirrectory!
        File.open(path, 'a').tap {|file|
          file.sync = true
          @log_file_name = File.basename(file.path)
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
      # return if e.respond_to?(:logged?) && e.logged?

      ERROR_LOG.audit("#{block_name} // #{log_file_name}") do
        begin
          write_exception_details(e)
          # def e.logged?
          #   true
          # end
        rescue Exception => e # catch ALL Exceptions, but not StandardError only
          error " Error during writing to log: #{e}" # do not raise the exception again regardless to RESCUE_FROM_EXCEPTIONS
        end
      end
    end

    def filter_call_stack_trace(e)
      e.backtrace.map { |trace_level|
        # File.basename(trace_level)
        trace_level.sub(Rails.root.to_s, '') if APP_DIR_PATH.in?(trace_level)
      }.compact
    end

    def write_exception_details(e)
      # record_errors = "ActiveRecord errors: #{e.record.errors.full_messages}" if e.is_a?(ActiveRecord::RecordInvalid) || e.is_a?(ActiveRecord::RecordNotSaved)
      # unless e.cause
        # error "#{e.class} #{e.to_s} #{record_errors}, Call stack: #{filter_call_stack_trace(e).join "\n"}"
      # else
      # binding.pry

      if e.cause
        ERROR_LOG.error "#{exception_message(e)} Cause exception:"
        write_exception_details(e.cause) if e.cause
      else
        #   # #{record_errors} if active_record...
        ERROR_LOG.error "#{exception_message(e)} Call stack:"
        call_stack_output_messages(filter_call_stack_trace(e))
      end
    end
  end
end
