# frozen_string_literal: true
require_relative "./base_cop"

module GraphQL
  module Rubocop
    module GraphQL
      # Identify (and auto-correct) any argument configuration which duplicates
      # the default `required: true` property.
      #
      # `required: true` is default because required arguments can always be converted
      # to optional arguments (`required: false`) without a breaking change. (The opposite change, from `required: false`
      # to `required: true`, change.)
      #
      # @example
      #   # Both of these define `id: ID!` in GraphQL:
      #
      #   # bad
      #   argument :id, ID, required: true
      #
      #   # good
      #   argument :id, ID
      #
      class DefaultRequiredTrue < BaseCop
        MSG = "`required: true` is the default and can be removed."

        def_node_matcher :argument_config_with_required_true?, <<-Pattern
        (
          send {nil? _} :argument ... (hash <$(pair (sym :required) (true)) ...>)
        )
        Pattern

        def on_send(node)
          argument_config_with_required_true?(node) do |required_config|
            add_offense(required_config) do |corrector|
              cleaned_node_source = source_without_keyword_argument(node, required_config)
              corrector.replace(node, cleaned_node_source)
            end
          end
        end
      end
    end
  end
end
