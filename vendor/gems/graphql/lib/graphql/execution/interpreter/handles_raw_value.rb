# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # Wrapper for raw values
      class RawValue
        def initialize(obj = nil)
          @object = obj
        end

        def resolve
          @object
        end
      end
    end
  end
end
