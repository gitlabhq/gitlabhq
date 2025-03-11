# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module HasPath
        # @return [String] A description of this member's place in the GraphQL schema
        def path
          path_str = if self.respond_to?(:graphql_name)
            self.graphql_name
          elsif self.class.respond_to?(:graphql_name)
            # Instances of resolvers
            self.class.graphql_name
          end

          if self.respond_to?(:owner) && owner.respond_to?(:path)
            path_str = "#{owner.path}.#{path_str}"
          end

          path_str
        end
      end
    end
  end
end
