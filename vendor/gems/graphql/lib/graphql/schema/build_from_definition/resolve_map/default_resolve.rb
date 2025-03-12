# frozen_string_literal: true
module GraphQL
  class Schema
    module BuildFromDefinition
      class ResolveMap
        class DefaultResolve
          def initialize(field_map, field_name)
            @field_map = field_map
            @field_name = field_name
          end

          # Make some runtime checks about
          # how `obj` implements the `field_name`.
          #
          # Create a new resolve function according to that implementation, then:
          #   - update `field_map` with this implementation
          #   - call the implementation now (to satisfy this field execution)
          #
          # If `obj` doesn't implement `field_name`, raise an error.
          def call(obj, args, ctx)
            method_name = @field_name
            if !obj.respond_to?(method_name)
              raise KeyError, "Can't resolve field #{method_name} on #{obj.inspect}"
            else
              method_arity = obj.method(method_name).arity
              resolver = case method_arity
              when 0, -1
                # -1 Handles method_missing, eg openstruct
                ->(o, a, c) { o.public_send(method_name) }
              when 1
                ->(o, a, c) { o.public_send(method_name, a) }
              when 2
                ->(o, a, c) { o.public_send(method_name, a, c) }
              else
                raise "Unexpected resolve arity: #{method_arity}. Must be 0, 1, 2"
              end
              # Call the resolver directly next time
              @field_map[method_name] = resolver
              # Call through this time
              resolver.call(obj, args, ctx)
            end
          end
        end
      end
    end
  end
end
