# frozen_string_literal: true
module GraphQL
  class Schema
    class Visibility
      # You can use this to see how {GraphQL::Schema::Warden} and {GraphQL::Schema::Visibility::Profile}
      # handle `.visible?` differently in your schema.
      #
      # It runs the same method on both implementations and raises an error when the results diverge.
      #
      # To fix the error, modify your schema so that both implementations return the same thing.
      # Or, open an issue on GitHub to discuss the difference.
      #
      # This plugin adds overhead to runtime and may cause unexpected crashes -- **don't** use it in production!
      #
      # This plugin adds two keys to `context` when running:
      #
      # - `visibility_migration_running: true`
      # - For the {Schema::Warden} which it instantiates, it adds `visibility_migration_warden_running: true`.
      #
      # Use those keys to modify your `visible?` behavior as needed.
      #
      # Also, in a pinch, you can set `skip_visibility_migration_error: true` in context to turn off this behavior per-query.
      # (In that case, it uses {Profile} directly.)
      #
      # @example Adding this plugin
      #
      #   use GraphQL::Schema::Visibility, migration_errors: true
      #
      class Migration < GraphQL::Schema::Visibility::Profile
        class RuntimeTypesMismatchError < GraphQL::Error
          def initialize(method_called, warden_result, profile_result, method_args)
            super(<<~ERR)
              Mismatch in types for `##{method_called}(#{method_args.map(&:inspect).join(", ")})`:

              #{compare_results(warden_result, profile_result)}

              Update your `.visible?` implementation to make these implementations return the same value.

              See: https://graphql-ruby.org/authorization/visibility_migration.html
            ERR
          end

          private
          def compare_results(warden_result, profile_result)
            if warden_result.is_a?(Array) && profile_result.is_a?(Array)
              all_results = warden_result | profile_result
              all_results.sort_by!(&:graphql_name)

              entries_text = all_results.map { |entry| "#{entry.graphql_name} (#{entry})"}
              width = entries_text.map(&:size).max
              yes = "    ✔   "
              no =  "        "
              res = "".dup
              res << "#{"Result".center(width)} Warden  Profile \n"
              all_results.each_with_index do |entry, idx|
                res << "#{entries_text[idx].ljust(width)}#{warden_result.include?(entry) ? yes : no}#{profile_result.include?(entry) ? yes : no}\n"
              end
              res << "\n"
            else
              "- Warden returned: #{humanize(warden_result)}\n\n- Visibility::Profile returned: #{humanize(profile_result)}"
            end
          end
          def humanize(val)
            case val
            when Array
              "#{val.size}: #{val.map { |v| humanize(v) }.sort.inspect}"
            when Module
              if val.respond_to?(:graphql_name)
                "#{val.graphql_name} (#{val.inspect})"
              else
                val.inspect
              end
            else
              val.inspect
            end
          end
        end

        def initialize(context:, schema:, name: nil)
          @name = name
          @skip_error = context[:skip_visibility_migration_error] || context.is_a?(Query::NullContext) || context.is_a?(Hash)
          @profile_types = GraphQL::Schema::Visibility::Profile.new(context: context, schema: schema)
          if !@skip_error
            context[:visibility_migration_running] = true
            warden_ctx_vals = context.to_h.dup
            warden_ctx_vals[:visibility_migration_warden_running] = true
            if schema.const_defined?(:WardenCompatSchema, false) # don't use a defn from a superclass
              warden_schema = schema.const_get(:WardenCompatSchema, false)
            else
              warden_schema = Class.new(schema)
              warden_schema.use_visibility_profile = false
              # TODO public API
              warden_schema.send(:add_type_and_traverse, [warden_schema.query, warden_schema.mutation, warden_schema.subscription].compact, root: true)
              warden_schema.send(:add_type_and_traverse, warden_schema.directives.values + warden_schema.orphan_types, root: false)
              schema.const_set(:WardenCompatSchema, warden_schema)
            end
            warden_ctx = GraphQL::Query::Context.new(query: context.query, values: warden_ctx_vals)
            warden_ctx.warden = GraphQL::Schema::Warden.new(schema: warden_schema, context: warden_ctx)
            warden_ctx.warden.skip_warning = true
            warden_ctx.types = @warden_types = warden_ctx.warden.visibility_profile
          end
        end

        def loaded_types
          @profile_types.loaded_types
        end

        PUBLIC_PROFILE_METHODS = [
          :enum_values,
          :interfaces,
          :all_types,
          :all_types_h,
          :fields,
          :loadable?,
          :loadable_possible_types,
          :type,
          :arguments,
          :argument,
          :directive_exists?,
          :directives,
          :field,
          :query_root,
          :mutation_root,
          :possible_types,
          :subscription_root,
          :reachable_type?,
          :visible_enum_value?,
        ]

        PUBLIC_PROFILE_METHODS.each do |profile_method|
          define_method(profile_method) do |*args|
            call_method_and_compare(profile_method, args)
          end
        end

        def call_method_and_compare(method, args)
          res_1 = @profile_types.public_send(method, *args)
          if @skip_error
            return res_1
          end

          res_2 = @warden_types.public_send(method, *args)
          normalized_res_1 = res_1.is_a?(Array) ? Set.new(res_1) : res_1
          normalized_res_2 = res_2.is_a?(Array) ? Set.new(res_2) : res_2
          if !equivalent_schema_members?(normalized_res_1, normalized_res_2)
            # Raise the errors with the orignally returned values:
            err = RuntimeTypesMismatchError.new(method, res_2, res_1, args)
            raise err
          else
            res_1
          end
        end

        def equivalent_schema_members?(member1, member2)
          if member1.class != member2.class
            return false
          end

          case member1
          when Set
            member1_array = member1.to_a.sort_by(&:graphql_name)
            member2_array = member2.to_a.sort_by(&:graphql_name)
            member1_array.each_with_index do |inner_member1, idx|
              inner_member2 = member2_array[idx]
              equivalent_schema_members?(inner_member1, inner_member2)
            end
          when GraphQL::Schema::Field
            member1.ensure_loaded
            member2.ensure_loaded
            if member1.introspection? && member2.introspection?
              member1.inspect == member2.inspect
            else
              member1 == member2
            end
          when Module
            if member1.introspection? && member2.introspection?
              member1.graphql_name == member2.graphql_name
            else
              member1 == member2
            end
          else
            member1 == member2
          end
        end
      end
    end
  end
end
