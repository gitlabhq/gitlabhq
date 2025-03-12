# frozen_string_literal: true
module GraphQL
  class Schema
    module AlwaysVisible
      def self.use(schema, **opts)
        schema.extend(self)
      end

      def visible?(_member, _context)
        true
      end
    end
  end
end
