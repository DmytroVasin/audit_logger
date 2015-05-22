module AuditLogger
  module AuditMessageStyles
    private

    def format_message(severity, timestamp, progname, msg)
      "[#{date_info(timestamp)}#{severity_info(severity)}#{pid_info}#{thread_info}#{msg} ]\n"
    end

    def message_block(block_name, opening:)
      intro_message = opening ? " <start_of>: " : " </end_of>: "
      info(intro_message + block_name)
    end

    def pid_info
      " pid: #{$$} |" if al_pid
    end

    def severity_info(severity)
      " #{severity} |" if al_severity
    end

    def date_info(timestamp)
      " #{timestamp.to_formatted_s(:db)} |" if al_timestamp
    end

    def exception_message(e)
      " #{e.class}: #{e.to_s}."
    end

    def call_stack_output_messages(messages)
      messages.each do |message|
        ERROR_LOG.error " -> ..#{message}"
      end
    end

    def thread_info
      " thread: #{Thread.current.object_id} |" if al_thread
    end
  end
end
