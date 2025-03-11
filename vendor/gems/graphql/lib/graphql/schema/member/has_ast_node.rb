# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      module HasAstNode
        def self.extended(child_cls)
          super
          child_cls.ast_node = nil
        end

        def inherited(child_cls)
          super
          child_cls.ast_node = nil
        end

        # If this schema was parsed from a `.graphql` file (or other SDL),
        # this is the AST node that defined this part of the schema.
        def ast_node(new_ast_node = nil)
          if new_ast_node
            @ast_node = new_ast_node
          elsif defined?(@ast_node)
            @ast_node
          else
            nil
          end
        end

        attr_writer :ast_node
      end
    end
  end
end
