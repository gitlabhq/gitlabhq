# frozen_string_literal: true
require "graphql/backtrace/table"
require "graphql/backtrace/traced_error"
module GraphQL
  # Wrap unhandled errors with {TracedError}.
  #
  # {TracedError} provides a GraphQL backtrace with arguments and return values.
  # The underlying error is available as {TracedError#cause}.
  #
  # @example toggling backtrace annotation
  #   class MySchema < GraphQL::Schema
  #     if Rails.env.development? || Rails.env.test?
  #       use GraphQL::Backtrace
  #     end
  #   end
  #
  class Backtrace
    include Enumerable
    extend Forwardable

    def_delegators :to_a, :each, :[]

    def self.use(schema_defn)
      schema_defn.using_backtrace = true
    end

    def initialize(context, value: nil)
      @table = Table.new(context, value: value)
    end

    def inspect
      @table.to_table
    end

    alias :to_s :inspect

    def to_a
      @table.to_backtrace
    end
  end
end
