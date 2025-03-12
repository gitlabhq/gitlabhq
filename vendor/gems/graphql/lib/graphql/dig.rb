# frozen_string_literal: true
module GraphQL
  module Dig
    # implemented using the old activesupport #dig instead of the ruby built-in
    # so we can use some of the magic in Schema::InputObject and Interpreter::Arguments
    # to handle stringified/symbolized keys.
    #
    # @param args [Array<[String, Symbol>] Retrieves the value object corresponding to the each key objects repeatedly
    # @return [Object]
    def dig(own_key, *rest_keys)
      val = self[own_key]
      if val.nil? || rest_keys.empty?
        val
      else
        val.dig(*rest_keys)
      end
    end
  end
end
