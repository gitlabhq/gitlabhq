# frozen_string_literal: true

module Graphql
  class Arguments
    delegate :blank?, :empty?, to: :to_h

    def initialize(values)
      @values = values
    end

    def to_h
      @values
    end

    def ==(other)
      to_h == other&.to_h
    end

    alias_method :eql, :==

    def to_s
      return '' if empty?

      @values.map do |name, value|
        value_str = as_graphql_literal(value)

        "#{GraphqlHelpers.fieldnamerize(name.to_s)}: #{value_str}"
      end.join(", ")
    end

    def as_graphql_literal(value)
      self.class.as_graphql_literal(value)
    end

    # Transform values to GraphQL literal arguments.
    # Use symbol for Enum values
    def self.as_graphql_literal(value)
      case value
      when ::Graphql::Arguments then "{#{value}}"
      when Array then "[#{value.map { |v| as_graphql_literal(v) }.join(',')}]"
      when Hash then "{#{new(value)}}"
      when Integer, Float, Symbol then value.to_s
      when String, GlobalID then "\"#{value.to_s.gsub(/"/, '\\"')}\""
      when Time, Date then "\"#{value.iso8601}\""
      when NilClass then 'null'
      when true then 'true'
      when false then 'false'
      else
        value.to_graphql_value
      end
    rescue NoMethodError
      raise ArgumentError, "Cannot represent #{value} (instance of #{value.class}) as GraphQL literal"
    end

    def merge(other)
      self.class.new(@values.merge(other.to_h))
    end

    def +(other)
      if blank?
        other
      elsif other.blank?
        self
      elsif other.is_a?(String)
        [to_s, other].compact.join(', ')
      else
        merge(other)
      end
    end
  end
end
