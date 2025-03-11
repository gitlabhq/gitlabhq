# frozen_string_literal: true
module GraphQL
  # If a field's resolve function returns a {ExecutionError},
  # the error will be inserted into the response's `"errors"` key
  # and the field will resolve to `nil`.
  class ExecutionError < GraphQL::Error
    # @return [GraphQL::Language::Nodes::Field] the field where the error occurred
    attr_accessor :ast_node

    # @return [String] an array describing the JSON-path into the execution
    # response which corresponds to this error.
    attr_accessor :path

    # @return [Hash] Optional data for error objects
    # @deprecated Use `extensions` instead of `options`. The GraphQL spec
    # recommends that any custom entries in an error be under the
    # `extensions` key.
    attr_accessor :options

    # @return [Hash] Optional custom data for error objects which will be added
    # under the `extensions` key.
    attr_accessor :extensions

    def initialize(message, ast_node: nil, options: nil, extensions: nil)
      @ast_node = ast_node
      @options = options
      @extensions = extensions
      super(message)
    end

    # @return [Hash] An entry for the response's "errors" key
    def to_h
      hash = {
        "message" => message,
      }
      if ast_node
        hash["locations"] = [
          {
            "line" => ast_node.line,
            "column" => ast_node.col,
          }
        ]
      end
      if path
        hash["path"] = path
      end
      if options
        hash.merge!(options)
      end
      if extensions
        hash["extensions"] = extensions.each_with_object({}) { |(key, value), ext|
          ext[key.to_s] = value
        }
      end
      hash
    end
  end
end
