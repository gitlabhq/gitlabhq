# frozen_string_literal: true
module GraphQL
  module Language
    # Exposes {.generate}, which turns AST nodes back into query strings.
    module Generation
      extend self

      # Turn an AST node back into a string.
      #
      # @example Turning a document into a query
      #    document = GraphQL.parse(query_string)
      #    GraphQL::Language::Generation.generate(document)
      #    # => "{ ... }"
      #
      # @param node [GraphQL::Language::Nodes::AbstractNode] an AST node to recursively stringify
      # @param indent [String] Whitespace to add to each printed node
      # @param printer [GraphQL::Language::Printer] An optional custom printer for printing AST nodes. Defaults to GraphQL::Language::Printer
      # @return [String] Valid GraphQL for `node`
      def generate(node, indent: "", printer: GraphQL::Language::Printer.new)
        printer.print(node, indent: indent)
      end
    end
  end
end
