# frozen_string_literal: true
require_relative 'orm_mutations_base'

module Graphql
  module Generators
    # TODO: What other options should be supported?
    #
    # @example Generate a `GraphQL::Schema::RelayClassicMutation` by name
    #     rails g graphql:mutation DeletePostMutation
    class MutationDeleteGenerator < OrmMutationsBase

      desc "Scaffold a Relay Classic ORM delete mutation for the given model class"
      source_root File.expand_path('../templates', __FILE__)

      private

      def operation_type
        "delete"
      end
    end
  end
end
