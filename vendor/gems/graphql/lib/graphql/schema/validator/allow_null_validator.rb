# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this to specifically reject or permit `nil` values (given as `null` from GraphQL).
      #
      # @example require a non-null value for an argument if it is provided
      #   argument :name, String, required: false, validates: { allow_null: false }
      class AllowNullValidator < Validator
        MESSAGE = "%{validated} can't be null"
        def initialize(allow_null_positional, allow_null: nil, message: MESSAGE, **default_options)
          @message = message
          super(**default_options)
          @allow_null = allow_null.nil? ? allow_null_positional : allow_null
        end

        def validate(_object, _context, value)
          if value.nil? && !@allow_null
            @message
          end
        end
      end
    end
  end
end
