# frozen_string_literal: true

require_relative 'field'
require_relative 'argument'

module Tooling
  module Graphql
    module Docs
      module Schema
        # A mutation is a top-level entry point that changes data.
        #
        # A mutation receives its arguments through a single `input` argument and
        # returns a payload type. For documentation, the input object's arguments
        # become the mutation's arguments, and the payload's fields its return fields.
        #
        # @see https://graphql.org/learn/schema/#the-query-mutation-and-subscription-types
        class Mutation < Field
          INPUT_ARGUMENT_NAME = 'input'

          # Every mutation accepts and returns this, so it is documented once in
          # the page intro rather than on every mutation.
          CLIENT_MUTATION_ID = 'clientMutationId'

          attr_reader :input_object_name, :return_fields

          def initialize(mutation)
            super

            input_object = mutation.arguments.fetch(INPUT_ARGUMENT_NAME).type.unwrap
            @input_object_name = input_object.graphql_name

            @arguments = input_object.arguments.values
              .reject { |argument| argument.graphql_name == CLIENT_MUTATION_ID }
              .map { |argument| Argument.new(argument) }

            @return_fields = mutation.type.unwrap.fields.values
              .reject { |field| field.graphql_name == CLIENT_MUTATION_ID }
              .map { |field| Field.new(field) }
          end
        end
      end
    end
  end
end
