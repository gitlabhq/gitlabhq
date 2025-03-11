# frozen_string_literal: true
module GraphQL
  class Backtrace
    # When {Backtrace} is enabled, raised errors are wrapped with {TracedError}.
    class TracedError < GraphQL::Error
      # @return [Array<String>] Printable backtrace of GraphQL error context
      attr_reader :graphql_backtrace

      # @return [GraphQL::Query::Context] The context at the field where the error was raised
      attr_reader :context

      MESSAGE_TEMPLATE = <<-MESSAGE
Unhandled error during GraphQL execution:

  %{cause_message}
    %{cause_backtrace}
    %{cause_backtrace_more}
Use #cause to access the original exception (including #cause.backtrace).

GraphQL Backtrace:
%{graphql_table}
MESSAGE

      # This many lines of the original Ruby backtrace
      # are included in the message
      CAUSE_BACKTRACE_PREVIEW_LENGTH = 10

      def initialize(err, current_ctx)
        @context = current_ctx
        backtrace = Backtrace.new(current_ctx, value: err)
        @graphql_backtrace = backtrace.to_a

        cause_backtrace_preview = err.backtrace.first(CAUSE_BACKTRACE_PREVIEW_LENGTH).join("\n    ")

        cause_backtrace_remainder_length = err.backtrace.length - CAUSE_BACKTRACE_PREVIEW_LENGTH
        cause_backtrace_more = if cause_backtrace_remainder_length < 0
          ""
        elsif cause_backtrace_remainder_length == 1
          "... and 1 more line\n"
        else
          "... and #{cause_backtrace_remainder_length} more lines\n"
        end

        message = MESSAGE_TEMPLATE % {
          cause_message: err.message,
          cause_backtrace: cause_backtrace_preview,
          cause_backtrace_more: cause_backtrace_more,
          graphql_table: backtrace.inspect,
        }
        super(message)
      end
    end
  end
end
