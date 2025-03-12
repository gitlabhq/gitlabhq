# frozen_string_literal: true

require 'time'

module GraphQL
  module Types
    # This scalar takes `Time`s and transmits them as strings,
    # using ISO 8601 format.
    #
    # Use it for fields or arguments as follows:
    #
    #     field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    #
    #     argument :deliver_at, GraphQL::Types::ISO8601DateTime, null: false
    #
    # Alternatively, use this built-in scalar as inspiration for your
    # own DateTime type.
    class ISO8601DateTime < GraphQL::Schema::Scalar
      description "An ISO 8601-encoded datetime"
      specified_by_url "https://tools.ietf.org/html/rfc3339"

      # It's not compatible with Rails' default,
      # i.e. ActiveSupport::JSON::Encoder.time_precision (3 by default)
      DEFAULT_TIME_PRECISION = 0

      # @return [Integer]
      def self.time_precision
        @time_precision || DEFAULT_TIME_PRECISION
      end

      # @param [Integer] value
      def self.time_precision=(value)
        @time_precision = value
      end

      # @param value [Time,Date,DateTime,String]
      # @return [String]
      def self.coerce_result(value, _ctx)
        case value
        when Date
          return value.to_time.iso8601(time_precision)
        when ::String
          return Time.parse(value).iso8601(time_precision)
        else
          # Time, DateTime or compatible is given:
          return value.iso8601(time_precision)
        end
      rescue StandardError => error
        raise GraphQL::Error, "An incompatible object (#{value.class}) was given to #{self}. Make sure that only Times, Dates, DateTimes, and well-formatted Strings are used with this type. (#{error.message})"
      end

      # @param str_value [String]
      # @return [Time]
      def self.coerce_input(str_value, _ctx)
        Time.iso8601(str_value)
      rescue ArgumentError, TypeError
        begin
          dt = Date.iso8601(str_value).to_time
          # For compatibility, continue accepting dates given without times
          # But without this, it would zero out given any time part of `str_value` (hours and/or minutes)
          if dt.iso8601.start_with?(str_value)
            dt
          elsif str_value.length == 8 && str_value.match?(/\A\d{8}\Z/)
            # Allow dates that are missing the "-". eg. "20220404"
            dt
          else
            nil
          end
        rescue ArgumentError, TypeError
          # Invalid input
          nil
        end
      end
    end
  end
end
