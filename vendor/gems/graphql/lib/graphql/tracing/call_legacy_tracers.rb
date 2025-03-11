# frozen_string_literal: true

module GraphQL
  module Tracing
    # This trace class calls legacy-style tracer with payload hashes.
    # New-style `trace_with` modules significantly reduce the overhead of tracing,
    # but that advantage is lost when legacy-style tracers are also used (since the payload hashes are still constructed).
    module CallLegacyTracers
      def lex(query_string:)
        (@multiplex || @query).trace("lex", { query_string: query_string }) { super }
      end

      def parse(query_string:)
        (@multiplex || @query).trace("parse", { query_string: query_string }) { super }
      end

      def validate(query:, validate:)
        query.trace("validate", { validate: validate, query: query }) { super }
      end

      def analyze_multiplex(multiplex:)
        multiplex.trace("analyze_multiplex", { multiplex: multiplex }) { super }
      end

      def analyze_query(query:)
        query.trace("analyze_query", { query: query }) { super }
      end

      def execute_multiplex(multiplex:)
        multiplex.trace("execute_multiplex", { multiplex: multiplex }) { super }
      end

      def execute_query(query:)
        query.trace("execute_query", { query: query }) { super }
      end

      def execute_query_lazy(query:, multiplex:)
        multiplex.trace("execute_query_lazy", { multiplex: multiplex, query: query }) { super }
      end

      def execute_field(field:, query:, ast_node:, arguments:, object:)
        query.trace("execute_field", { field: field, query: query, ast_node: ast_node, arguments: arguments, object: object, owner: field.owner, path: query.context[:current_path] }) { super }
      end

      def execute_field_lazy(field:, query:, ast_node:, arguments:, object:)
        query.trace("execute_field_lazy", { field: field, query: query, ast_node: ast_node, arguments: arguments, object: object, owner: field.owner, path: query.context[:current_path] }) { super }
      end

      def authorized(query:, type:, object:)
        query.trace("authorized", { context: query.context, type: type, object: object, path: query.context[:current_path] }) { super }
      end

      def authorized_lazy(query:, type:, object:)
        query.trace("authorized_lazy", { context: query.context, type: type, object: object, path: query.context[:current_path] }) { super }
      end

      def resolve_type(query:, type:, object:)
        query.trace("resolve_type", { context: query.context, type: type, object: object, path: query.context[:current_path] }) { super }
      end

      def resolve_type_lazy(query:, type:, object:)
        query.trace("resolve_type_lazy", { context: query.context, type: type, object: object, path: query.context[:current_path] }) { super }
      end
    end
  end
end
