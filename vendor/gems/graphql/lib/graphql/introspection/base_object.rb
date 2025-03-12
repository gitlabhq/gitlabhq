# frozen_string_literal: true
module GraphQL
  module Introspection
    class BaseObject < GraphQL::Schema::Object
      introspection(true)

      def self.field(*args, **kwargs, &block)
        kwargs[:introspection] = true
        super(*args, **kwargs, &block)
      end
    end
  end
end
