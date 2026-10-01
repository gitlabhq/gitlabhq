# frozen_string_literal: true

module Tooling
  module Graphql
    module Docs
      module Schema
        # Mixed into schema items that have a GraphQL type (fields, arguments).
        # Exposes the wrapped `type` and its `type_signature`.
        module Typeable
          attr_reader :type, :type_signature

          def initialize(typeable)
            super

            @type = Factory.wrap(typeable.type.unwrap)
            @type_signature = typeable.type.to_type_signature
          end
        end
      end
    end
  end
end
