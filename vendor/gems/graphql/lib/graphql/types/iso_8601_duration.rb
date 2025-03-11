# frozen_string_literal: true
module GraphQL
  module Types
    # This scalar takes `Duration`s and transmits them as strings,
    # using ISO 8601 format. ActiveSupport >= 5.0 must be loaded to use
    # this scalar.
    #
    # Use it for fields or arguments as follows:
    #
    #     field :age, GraphQL::Types::ISO8601Duration, null: false
    #
    #     argument :interval, GraphQL::Types::ISO8601Duration, null: false
    #
    # Alternatively, use this built-in scalar as inspiration for your
    # own Duration type.
    class ISO8601Duration < GraphQL::Schema::Scalar
      description "An ISO 8601-encoded duration"

      # @return [Integer, nil]
      def self.seconds_precision
        # ActiveSupport::Duration precision defaults to whatever input was given
        @seconds_precision
      end

      # @param [Integer, nil] value
      def self.seconds_precision=(value)
        @seconds_precision = value
      end

      # @param value [ActiveSupport::Duration, String]
      # @return [String]
      # @raise [GraphQL::Error] if ActiveSupport::Duration is not defined or if an incompatible object is passed
      def self.coerce_result(value, _ctx)
        unless defined?(ActiveSupport::Duration)
          raise GraphQL::Error, "ActiveSupport >= 5.0 must be loaded to use the built-in ISO8601Duration type."
        end

        begin
          case value
          when ActiveSupport::Duration
            value.iso8601(precision: seconds_precision)
          when ::String
            ActiveSupport::Duration.parse(value).iso8601(precision: seconds_precision)
          else
            # Try calling as ActiveSupport::Duration compatible as a fallback
            value.iso8601(precision: seconds_precision)
          end
        rescue StandardError => error
          raise GraphQL::Error, "An incompatible object (#{value.class}) was given to #{self}. Make sure that only ActiveSupport::Durations and well-formatted Strings are used with this type. (#{error.message})"
        end
      end

      # @param value [String, ActiveSupport::Duration]
      # @return [ActiveSupport::Duration, nil]
      # @raise [GraphQL::Error] if ActiveSupport::Duration is not defined
      # @raise [GraphQL::DurationEncodingError] if duration cannot be parsed
      def self.coerce_input(value, ctx)
        unless defined?(ActiveSupport::Duration)
          raise GraphQL::Error, "ActiveSupport >= 5.0 must be loaded to use the built-in ISO8601Duration type."
        end

        begin
          if value.is_a?(ActiveSupport::Duration)
            value
          elsif value.nil?
            nil
          else
            ActiveSupport::Duration.parse(value)
          end
        rescue ArgumentError, TypeError
          err = GraphQL::DurationEncodingError.new(value)
          ctx.schema.type_error(err, ctx)
        end
      end
    end
  end
end
