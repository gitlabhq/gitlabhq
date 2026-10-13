# frozen_string_literal: true

require_relative 'field'

module Tooling
  module Graphql
    module Docs
      module Schema
        # A query is a top-level entry point for reading data.
        #
        # @see https://graphql.org/learn/schema/#the-query-and-mutation-types
        class Query < Field
        end
      end
    end
  end
end
