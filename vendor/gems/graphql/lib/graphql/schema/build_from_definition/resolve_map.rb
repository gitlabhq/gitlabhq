# frozen_string_literal: true
require "graphql/schema/build_from_definition/resolve_map/default_resolve"

module GraphQL
  class Schema
    module BuildFromDefinition
      # Wrap a user-provided hash of resolution behavior for easy access at runtime.
      #
      # Coerce scalar values by:
      # - Checking for a function in the map like `{ Date: { coerce_input: ->(val, ctx) { ... }, coerce_result: ->(val, ctx) { ... } } }`
      # - Falling back to a passthrough
      #
      # Interface/union resolution can be provided as a `resolve_type:` key.
      #
      # @api private
      class ResolveMap
        module NullScalarCoerce
          def self.call(val, _ctx)
            val
          end
        end

        def initialize(user_resolve_hash)
          @resolve_hash = Hash.new do |h, k|
            # For each type name, provide a new hash if one wasn't given:
            h[k] = Hash.new do |h2, k2|
              if k2 == "coerce_input" || k2 == "coerce_result"
                # This isn't an object field, it's a scalar coerce function.
                # Use a passthrough
                NullScalarCoerce
              else
                # For each field, provide a resolver that will
                # make runtime checks & replace itself
                h2[k2] = DefaultResolve.new(h2, k2)
              end
            end
          end
          @user_resolve_hash = user_resolve_hash
          # User-provided resolve functions take priority over the default:
          @user_resolve_hash.each do |type_name, fields|
            type_name_s = type_name.to_s
            case fields
            when Hash
              fields.each do |field_name, resolve_fn|
                @resolve_hash[type_name_s][field_name.to_s] = resolve_fn
              end
            when Proc
              # for example, "resolve_type"
              @resolve_hash[type_name_s] = fields
            else
              raise ArgumentError, "Unexpected resolve hash value for #{type_name.inspect}: #{fields.inspect} (#{fields.class})"
            end
          end

          # Check the normalized hash, not the user input:
          if @resolve_hash.key?("resolve_type")
            define_singleton_method :resolve_type do |type, obj, ctx|
              @resolve_hash.fetch("resolve_type").call(type, obj, ctx)
            end
          end
        end

        def call(type, field, obj, args, ctx)
          resolver = @resolve_hash[type.graphql_name][field.graphql_name]
          resolver.call(obj, args, ctx)
        end

        def coerce_input(type, value, ctx)
          @resolve_hash[type.graphql_name]["coerce_input"].call(value, ctx)
        end

        def coerce_result(type, value, ctx)
          @resolve_hash[type.graphql_name]["coerce_result"].call(value, ctx)
        end
      end
    end
  end
end
