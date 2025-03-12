# frozen_string_literal: true
# A stub for the NewRelic agent, so we can make assertions about how it is used
if defined?(NewRelic)
  raise "Expected NewRelic to be undefined, so that we could define a stub for it."
end

module NewRelic
  TRANSACTION_NAMES = []
  EXECUTION_SCOPES = []
  # Reset state between tests
  def self.clear_all
    TRANSACTION_NAMES.clear
    EXECUTION_SCOPES.clear
  end

  module Agent
    def self.set_transaction_name(name)
      TRANSACTION_NAMES << name
    end

    module Tracer
      def self.start_transaction_or_segment(partial_name:, category:)
        EXECUTION_SCOPES << partial_name
        Finisher.new(partial_name)
      end

      class Finisher
        def initialize(name)
          @partial_name = name
        end

        def name
          "Controller/#{@partial_name}"
        end

        def finish
          EXECUTION_SCOPES << "FINISH #{@partial_name}"
          nil
        end
      end
    end

    module MethodTracerHelpers
      def self.trace_execution_scoped(trace_name)
        EXECUTION_SCOPES << trace_name
        yield
      end
    end
  end
end
