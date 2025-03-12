# frozen_string_literal: true
require_relative 'orm_mutations_base'

module Graphql
  module Generators
    # TODO: What other options should be supported?
    #
    # @example Generate a `GraphQL::Schema::RelayClassicMutation` by name
    #     rails g graphql:mutation CreatePostMutation
    class MutationCreateGenerator < OrmMutationsBase

      desc "Scaffold a Relay Classic ORM create mutation for the given model class"
      source_root File.expand_path('../templates', __FILE__)

      private

      def operation_type
        "create"
      end
    end
  end
end
