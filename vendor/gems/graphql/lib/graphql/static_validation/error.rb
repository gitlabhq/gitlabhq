# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Generates GraphQL-compliant validation message.
    class Error
      # Convenience for validators
      module ErrorHelper
        # Error `error_message` is located at `node`
        def error(error_message, nodes, context: nil, path: nil, extensions: {})
          path ||= context.path
          nodes = Array(nodes)
          GraphQL::StaticValidation::Error.new(error_message, nodes: nodes, path: path)
        end
      end

      attr_reader   :message
      attr_accessor :path

      def initialize(message, path: nil, nodes: [])
        @message = message
        @nodes = Array(nodes)
        @path = path
      end

      # A hash representation of this Message
      def to_h
        {
          "message" => message,
          "locations" => locations
        }.tap { |h| h["path"] = path unless path.nil? }
      end

      attr_reader :nodes

      private

      def locations
        nodes.map do |node|
          h = {"line" => node.line, "column" => node.col}
          h["filename"] = node.filename if node.filename
          h
        end
      end
    end
  end
end
