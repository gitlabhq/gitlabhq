# frozen_string_literal: true

module Graphql
  module ResolverFactories
    def new_resolver(resolved_value = 'Resolved value', method: :resolve)
      case method
      when :resolve
        simple_resolver(resolved_value)
      when :find_object
        find_object_resolver(resolved_value)
      else
        raise "Cannot build a resolver for #{method}"
      end
    end

    private

    def simple_resolver(resolved_value = 'Resolved value')
      Class.new(Resolvers::BaseResolver) do
        define_method :resolve do |**_args|
          resolved_value
        end
      end
    end

    def find_object_resolver(resolved_value = 'Found object')
      Class.new(Resolvers::BaseResolver) do
        include ::Gitlab::Graphql::Authorize::AuthorizeResource

        def resolve(**args)
          authorized_find!(**args)
        end

        define_method :find_object do |**_args|
          resolved_value
        end
      end
    end
  end
end
