# frozen_string_literal: true

require_relative '../factory'

module Tooling
  module Graphql
    module Docs
      module Schema
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
