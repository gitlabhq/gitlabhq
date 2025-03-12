# frozen_string_literal: true
module GraphQL
  class Query
    class Context
      class ScopedContext
        def initialize(query_context)
          @query_context = query_context
          @scoped_contexts = nil
          @all_keys = nil
        end

        def merged_context
          if @scoped_contexts.nil?
            GraphQL::EmptyObjects::EMPTY_HASH
          else
            merged_ctx = {}
            each_present_path_ctx do |path_ctx|
              merged_ctx = path_ctx.merge(merged_ctx)
            end
            merged_ctx
          end
        end

        def merge!(hash, at: current_path)
          @all_keys ||= Set.new
          @all_keys.merge(hash.keys)
          ctx = @scoped_contexts ||= {}
          at.each do |path_part|
            ctx = ctx[path_part] ||= { parent: ctx }
          end
          this_scoped_ctx = ctx[:scoped_context] ||= {}
          this_scoped_ctx.merge!(hash)
        end

        def key?(key)
          if @all_keys && @all_keys.include?(key)
            each_present_path_ctx do |path_ctx|
              if path_ctx.key?(key)
                return true
              end
            end
          end
          false
        end

        def [](key)
          each_present_path_ctx do |path_ctx|
            if path_ctx.key?(key)
              return path_ctx[key]
            end
          end
          nil
        end

        def current_path
          @query_context.current_path || GraphQL::EmptyObjects::EMPTY_ARRAY
        end

        def dig(key, *other_keys)
          each_present_path_ctx do |path_ctx|
            if path_ctx.key?(key)
              found_value = path_ctx[key]
              if !other_keys.empty?
                return found_value.dig(*other_keys)
              else
                return found_value
              end
            end
          end
          nil
        end

        private

        # Start at the current location,
        # but look up the tree for previously-assigned scoped values
        def each_present_path_ctx
          ctx = @scoped_contexts
          if ctx.nil?
            # no-op
          else
            current_path.each do |path_part|
              if ctx.key?(path_part)
                ctx = ctx[path_part]
              else
                break
              end
            end

            while ctx
              if (scoped_ctx = ctx[:scoped_context])
                yield(scoped_ctx)
              end
              ctx = ctx[:parent]
            end
          end
        end
      end
    end
  end
end
