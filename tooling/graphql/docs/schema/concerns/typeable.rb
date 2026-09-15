# frozen_string_literal: true

require_relative '../scalar'
require_relative '../enum'
require_relative '../input_object'
require_relative '../temp_undocumented'

module Tooling
  module Graphql
    module Docs
      module Schema
        module Typeable
          attr_reader :type, :type_signature

          def initialize(typeable)
            super

            base_type = typeable.type.unwrap

            @type = if base_type.kind.scalar?
                      Scalar.new(base_type)
                    elsif base_type.kind.enum?
                      Enum.new(base_type)
                    elsif base_type.kind.input_object?
                      InputObject.new(base_type, with_arguments: false)
                    else
                      TempUndocumented.new(base_type)
                    end

            @type_signature = typeable.type.to_type_signature
          end
        end
      end
    end
  end
end
