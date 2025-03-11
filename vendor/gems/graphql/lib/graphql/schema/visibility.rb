# frozen_string_literal: true
require "graphql/schema/visibility/profile"
require "graphql/schema/visibility/migration"
require "graphql/schema/visibility/visit"

module GraphQL
  class Schema
    # Use this plugin to make some parts of your schema hidden from some viewers.
    #
    class Visibility
      # @param schema [Class<GraphQL::Schema>]
      # @param profiles [Hash<Symbol => Hash>] A hash of `name => context` pairs for preloading visibility profiles
      # @param preload [Boolean] if `true`, load the default schema profile and all named profiles immediately (defaults to `true` for `Rails.env.production?`)
      # @param migration_errors [Boolean] if `true`, raise an error when `Visibility` and `Warden` return different results
      def self.use(schema, dynamic: false, profiles: EmptyObjects::EMPTY_HASH, preload: (defined?(Rails) ? Rails.env.production? : nil), migration_errors: false)
        profiles&.each { |name, ctx|
          ctx[:visibility_profile] = name
          ctx.freeze
        }
        schema.visibility = self.new(schema, dynamic: dynamic, preload: preload, profiles: profiles, migration_errors: migration_errors)
        if preload
          schema.visibility.preload
        end
      end

      def initialize(schema, dynamic:, preload:, profiles:, migration_errors:)
        @schema = schema
        schema.use_visibility_profile = true
        schema.visibility_profile_class = if migration_errors
          Visibility::Migration
        else
          Visibility::Profile
        end
        @preload = preload
        @profiles = profiles
        @cached_profiles = {}
        @dynamic = dynamic
        @migration_errors = migration_errors
        # Top-level type caches:
        @visit = nil
        @interface_type_memberships = nil
        @directives = nil
        @types = nil
        @all_references = nil
        @loaded_all = false
      end

      def all_directives
        load_all
        @directives
      end

      def all_interface_type_memberships
        load_all
        @interface_type_memberships
      end

      def all_references
        load_all
        @all_references
      end

      def get_type(type_name)
        load_all
        @types[type_name]
      end

      def preload?
        @preload
      end

      def preload
        # Traverse the schema now (and in the *_configured hooks below)
        # To make sure things are loaded during boot
        @preloaded_types = Set.new
        types_to_visit = [
          @schema.query,
          @schema.mutation,
          @schema.subscription,
          *@schema.introspection_system.types.values,
          *@schema.introspection_system.entry_points.map { |ep| ep.type.unwrap },
          *@schema.orphan_types,
        ]
        # Root types may have been nil:
        types_to_visit.compact!
        ensure_all_loaded(types_to_visit)
        @profiles.each do |profile_name, example_ctx|
          prof = profile_for(example_ctx)
          prof.all_types # force loading
        end
      end

      # @api private
      def query_configured(query_type)
        if @preload
          ensure_all_loaded([query_type])
        end
      end

      # @api private
      def mutation_configured(mutation_type)
        if @preload
          ensure_all_loaded([mutation_type])
        end
      end

      # @api private
      def subscription_configured(subscription_type)
        if @preload
          ensure_all_loaded([subscription_type])
        end
      end

      # @api private
      def orphan_types_configured(orphan_types)
        if @preload
          ensure_all_loaded(orphan_types)
        end
      end

      # @api private
      def introspection_system_configured(introspection_system)
        if @preload
          introspection_types = [
            *@schema.introspection_system.types.values,
            *@schema.introspection_system.entry_points.map { |ep| ep.type.unwrap },
          ]
          ensure_all_loaded(introspection_types)
        end
      end

      # Make another Visibility for `schema` based on this one
      # @return [Visibility]
      # @api private
      def dup_for(other_schema)
        self.class.new(
          other_schema,
          dynamic: @dynamic,
          preload: @preload,
          profiles: @profiles,
          migration_errors: @migration_errors
        )
      end

      def migration_errors?
        @migration_errors
      end

      attr_reader :cached_profiles

      def profile_for(context, visibility_profile = context[:visibility_profile])
        if !@profiles.empty?
          if visibility_profile.nil?
            if @dynamic
              if context.is_a?(Query::NullContext)
                top_level_profile
              else
                @schema.visibility_profile_class.new(context: context, schema: @schema)
              end
            elsif !@profiles.empty?
              raise ArgumentError, "#{@schema} expects a visibility profile, but `visibility_profile:` wasn't passed. Provide a `visibility_profile:` value or add `dynamic: true` to your visibility configuration."
            end
          elsif !@profiles.include?(visibility_profile)
            raise ArgumentError, "`#{visibility_profile.inspect}` isn't allowed for `visibility_profile:` (must be one of #{@profiles.keys.map(&:inspect).join(", ")}). Or, add `#{visibility_profile.inspect}` to the list of profiles in the schema definition."
          else
            profile_ctx = @profiles[visibility_profile]
            @cached_profiles[visibility_profile] ||= @schema.visibility_profile_class.new(name: visibility_profile, context: profile_ctx, schema: @schema)
          end
        elsif context.is_a?(Query::NullContext)
          top_level_profile
        else
          @schema.visibility_profile_class.new(context: context, schema: @schema)
        end
      end

      attr_reader :top_level

      # @api private
      attr_reader :unfiltered_interface_type_memberships

      def top_level_profile(refresh: false)
        if refresh
          @top_level_profile = nil
        end
        @top_level_profile ||= @schema.visibility_profile_class.new(context: Query::NullContext.instance, schema: @schema)
      end

      private

      def ensure_all_loaded(types_to_visit)
        while (type = types_to_visit.shift)
          if type.kind.fields? && @preloaded_types.add?(type)
            type.all_field_definitions.each do |field_defn|
              field_defn.ensure_loaded
              types_to_visit << field_defn.type.unwrap
            end
          end
        end
        top_level_profile(refresh: true)
        nil
      end

      def load_all(types: nil)
        if @visit.nil?
          # Set up the visit system
          @interface_type_memberships = Hash.new { |h, interface_type| h[interface_type] = [] }.compare_by_identity
          @directives = []
          @types = {} # String => Module
          @all_references = Hash.new { |h, member| h[member] = Set.new.compare_by_identity }.compare_by_identity
          @unions_for_references = Set.new
          @visit = Visibility::Visit.new(@schema) do |member|
            if member.is_a?(Module)
              type_name = member.graphql_name
              if (prev_t = @types[type_name])
                if prev_t.is_a?(Array)
                  prev_t << member
                else
                  @types[type_name] = [member, prev_t]
                end
              else
                @types[member.graphql_name] = member
              end
              member.directives.each { |dir| @all_references[dir.class] << member }
              if member < GraphQL::Schema::Directive
                @directives << member
              elsif member.respond_to?(:interface_type_memberships)
                member.interface_type_memberships.each do |itm|
                  @all_references[itm.abstract_type] << member
                  # `itm.object_type` may not actually be `member` if this implementation
                  # is inherited from a superclass
                  @interface_type_memberships[itm.abstract_type] << [itm, member]
                end
              elsif member < GraphQL::Schema::Union
                @unions_for_references << member
              end
            elsif member.is_a?(GraphQL::Schema::Argument)
              member.validate_default_value
              @all_references[member.type.unwrap] << member
              if !(dirs = member.directives).empty?
                dir_owner = member.owner
                if dir_owner.respond_to?(:owner)
                  dir_owner = dir_owner.owner
                end
                dirs.each { |dir| @all_references[dir.class] << dir_owner }
              end
            elsif member.is_a?(GraphQL::Schema::Field)
              @all_references[member.type.unwrap] << member
              if !(dirs = member.directives).empty?
                dir_owner = member.owner
                dirs.each { |dir| @all_references[dir.class] << dir_owner }
              end
            elsif member.is_a?(GraphQL::Schema::EnumValue)
              if !(dirs = member.directives).empty?
                dir_owner = member.owner
                dirs.each { |dir| @all_references[dir.class] << dir_owner }
              end
            end
            true
          end

          @schema.root_types.each { |t| @all_references[t] << true }
          @schema.introspection_system.types.each_value { |t| @all_references[t] << true }
          @schema.directives.each_value { |dir_class| @all_references[dir_class] << true }

          @visit.visit_each(types: []) # visit default directives
        end

        if types
          @visit.visit_each(types: types, directives: [])
        elsif @loaded_all == false
          @loaded_all = true
          @visit.visit_each
        else
          # already loaded all
          return
        end

        # TODO: somehow don't iterate over all these,
        # only the ones that may have been modified
        @interface_type_memberships.each do |int_type, type_membership_pairs|
          referers = @all_references[int_type].select { |r| r.is_a?(GraphQL::Schema::Field) }
          if !referers.empty?
            type_membership_pairs.each do |(type_membership, impl_type)|
              # Add new items only:
              @all_references[impl_type] |= referers
            end
          end
        end

        @unions_for_references.each do |union_type|
          refs = @all_references[union_type]
          union_type.all_possible_types.each do |object_type|
            @all_references[object_type] |= refs # Add new items
          end
        end
      end
    end
  end
end
