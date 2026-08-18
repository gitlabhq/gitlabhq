# frozen_string_literal: true

module Tooling
  module Graphql
    module Docs
      module Schema
        module Deprecable
          def deprecated?
            deprecation.present? && deprecation.deprecated?
          end

          def experiment?
            deprecation.present? && deprecation.experiment?
          end

          def deprecation
            item.try(:deprecation)
          end
        end
      end
    end
  end
end
