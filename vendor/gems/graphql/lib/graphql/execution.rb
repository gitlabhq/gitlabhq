# frozen_string_literal: true
require "graphql/execution/directive_checks"
require "graphql/execution/interpreter"
require "graphql/execution/lazy"
require "graphql/execution/lookahead"
require "graphql/execution/multiplex"
require "graphql/execution/errors"

module GraphQL
  module Execution
    # @api private
    class Skip < GraphQL::Error; end

    # Just a singleton for implementing {Query::Context#skip}
    # @api private
    SKIP = Skip.new
  end
end
