# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Visibility::Profile do
  class ProfileSchema < GraphQL::Schema
    class Thing < GraphQL::Schema::Object
      field :name, String, method: :to_s
    end

    class Query < GraphQL::Schema::Object
      field :thing, Thing, fallback_value: :Something
      field :greeting, String
    end

    query(Query)

    use GraphQL::Schema::Visibility
  end
  it "only loads the types it needs" do
    query = GraphQL::Query.new(ProfileSchema, "{ thing { name } }", use_visibility_profile: true)
    assert_equal [], query.types.loaded_types

    res = query.result
    assert_equal "Something", res["data"]["thing"]["name"]
    assert_equal [], query.types.loaded_types.map(&:graphql_name).sort

    query = GraphQL::Query.new(ProfileSchema, "{ __schema { types { name }} }", use_visibility_profile: true)
    assert_equal [], query.types.loaded_types

    res = query.result
    assert_equal 12, res["data"]["__schema"]["types"].size
    loaded_type_names = query.types.loaded_types.map(&:graphql_name).reject { |n| n.start_with?("__") }.sort
    assert_equal ["Boolean", "Query", "String", "Thing"], loaded_type_names
  end


  describe "when multiple field implementations are all hidden" do
    class EnsureLoadedFixSchema < GraphQL::Schema
      class BaseField < GraphQL::Schema::Field
        def visible?(...)
          false
        end
      end
      class Query < GraphQL::Schema::Object
        field_class(BaseField)

        field :f1, String
        field :f1, String
      end

      query(Query)
      use GraphQL::Schema::Visibility
    end

    it "handles it without raising an error" do
      result = EnsureLoadedFixSchema.execute("{ f1 }")
      assert 1, result["errors"].size
    end
  end

  describe "using configured contexts" do
    class ProfileContextSchema < GraphQL::Schema
      class << self
        attr_accessor :modify_visibility_context
        attr_accessor :last_visibility_context
      end

      class Query < GraphQL::Schema::Object
        def self.visible?(ctx)
          ProfileContextSchema.last_visibility_context = JSON.dump(ctx)
          if ProfileContextSchema.modify_visibility_context
            ctx[:this] = :breaks
          end
          !!ctx[:internal]
        end

        field :inspect_context, String

        def inspect_context
          JSON.dump(context.to_h)
        end
      end

      query(Query)
      use GraphQL::Schema::Visibility, profiles: {
        internal: { internal: true },
        public: { public: true },
        public2: { public: true }, # This is for testing FrozenError below
      }
    end

    before do
      ProfileContextSchema.modify_visibility_context = false
      ProfileContextSchema.last_visibility_context = nil
    end

    it "uses the configured context for `visible?` calls, not the query context" do
      res = ProfileContextSchema.execute("{ inspectContext }", context: { visibility_profile: :internal })
      assert_equal '{"visibility_profile":"internal"}', res["data"]["inspectContext"]
      assert_equal '{"internal":true,"visibility_profile":"internal"}', ProfileContextSchema.last_visibility_context

      res = ProfileContextSchema.execute("{ inspectContext }", context: { internal: true, visibility_profile: :public })
      assert_equal ["Schema is not configured for queries"], res["errors"].map { |e| e["message"] }
      assert_equal '{"public":true,"visibility_profile":"public"}', ProfileContextSchema.last_visibility_context
    end

    it "freezes profile contexts" do
      ProfileContextSchema.modify_visibility_context = true
      assert_raises FrozenError do
        ProfileContextSchema.execute("{ inspectContext }", context: { visibility_profile: :public2 })
      end
      assert_equal '{"public":true,"visibility_profile":"public2"}', ProfileContextSchema.last_visibility_context
    end
  end
end
