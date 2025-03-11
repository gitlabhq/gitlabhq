# frozen_string_literal: true
require "graphql/query/context"
module GraphQL
  class Query
    # This object can be `ctx` in places where there is no query
    class NullContext < Context
      include Singleton

      class NullQuery
        def after_lazy(value)
          yield(value)
        end
      end

      class NullSchema < GraphQL::Schema
      end

      extend Forwardable

      attr_reader :schema, :query, :warden, :dataloader
      def_delegators GraphQL::EmptyObjects::EMPTY_HASH, :[], :fetch, :dig, :key?, :to_h

      def initialize
        @query = NullQuery.new
        @dataloader = GraphQL::Dataloader::NullDataloader.new
        @schema = NullSchema
        @warden = Schema::Warden::NullWarden.new(context: self, schema: @schema)
        @types = @warden.visibility_profile
        freeze
      end
    end
  end
end
