# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::DocumentFromSchemaDefinition do
  let(:subject) { GraphQL::Language::DocumentFromSchemaDefinition }

  describe "#document" do
    let(:schema_idl) { <<-GRAPHQL
      type QueryType {
        foo: Foo
        u: Union
      }

      type Foo implements Bar {
        one: Type
        two(argument: InputType!): Site
        three(argument: InputType, other: String): CustomScalar
        four(argument: String = "string"): String
        five(argument: [String] = ["string", "string"]): String
        six(argument: String): Type
      }

      interface Bar {
        one: Type
        four(argument: String = "string"): String
      }

      type Type {
        a: String
      }

      input InputType {
        key: String!
        answer: Int = 42
      }

      type MutationType {
        a(input: InputType): String
      }

      # Scalar description
      scalar CustomScalar

      enum Site {
        DESKTOP
        MOBILE
      }

      union Union = Type | QueryType

      schema {
        query: QueryType
        mutation: MutationType
      }
    GRAPHQL
    }

    let(:schema) { GraphQL::Schema.from_definition(schema_idl) }

    let(:expected_document) { GraphQL.parse(expected_idl) }

    describe "when schemas have enums and directives" do
      let(:schema_idl) { <<-GRAPHQL
directive @locale(lang: LangEnum!) on FIELD

directive @secret(top: Boolean = false) on FIELD_DEFINITION

enum LangEnum {
  en
  ru
}

type Query {
  i: Int @secret
  ssn: String @secret(top: true)
}
      GRAPHQL
      }

      class DirectiveSchema < GraphQL::Schema
        class Secret < GraphQL::Schema::Directive
          argument :top, Boolean, required: false, default_value: false
          locations FIELD_DEFINITION
        end

        class Query < GraphQL::Schema::Object
          field :i, Int do
            directive Secret
          end

          field :ssn, String do
            directive Secret, top: true
          end
        end

        class Locale < GraphQL::Schema::Directive
          class LangEnum < GraphQL::Schema::Enum
            value "en"
            value "ru"
          end
          locations GraphQL::Schema::Directive::FIELD

          argument :lang, LangEnum
        end

        query(Query)
        directive(Locale)
      end

      it "dumps them into the string" do
        assert_equal schema_idl, DirectiveSchema.to_definition
      end
    end

    describe "when it has an enum_value with an adjacent custom directive" do
      let(:schema_idl) { <<-GRAPHQL
directive @customEnumValueDirective(fakeArgument: String!) on ENUM_VALUE

enum FakeEnum {
  VALUE1
  VALUE2 @customEnumValueDirective(fakeArgument: "Value1 is better...")
}

type Query {
  fakeQueryField: FakeEnum!
}
      GRAPHQL
      }

      class EnumValueDirectiveSchema < GraphQL::Schema
        class CustomEnumValueDirective < GraphQL::Schema::Directive
          locations GraphQL::Schema::Directive::ENUM_VALUE

          argument :fake_argument, String
        end

        class FakeEnum < GraphQL::Schema::Enum
          value "VALUE1"
          value "VALUE2" do
            directive CustomEnumValueDirective, fake_argument: "Value1 is better..."
          end
        end

        class Query < GraphQL::Schema::Object
          field :fake_query_field, FakeEnum, null: false
        end

        query(Query)
      end

      it "dumps the custom directive definition to the IDL" do
        assert_equal schema_idl, EnumValueDirectiveSchema.to_definition
      end
    end

    describe "when printing and schema respects root name conventions" do
      let(:schema_idl) { <<-GRAPHQL
        type Query {
          foo: Foo
          u: Union
        }

        type Foo implements Bar {
          one: Type
          two(argument: InputType!): Site
          three(argument: InputType, other: String): CustomScalar
          four(argument: String = "string"): String
          five(argument: [String] = ["string", "string"]): String
          six(argument: String): Type
        }

        interface Bar {
          one: Type
          four(argument: String = "string"): String
        }

        type Type {
          a: String
        }

        input InputType {
          key: String!
          answer: Int = 42
        }

        type Mutation {
          a(input: InputType): String
        }

        # Scalar description
        scalar CustomScalar

        enum Site {
          DESKTOP
          MOBILE
        }

        union Union = Type | Query

        schema {
          query: Query
          mutation: Mutation
        }
      GRAPHQL
      }

      let(:expected_idl) { <<-GRAPHQL
        type QueryType {
          foo: Foo
          u: Union
        }

        type Foo implements Bar {
          one: Type
          two(argument: InputType!): Site
          three(argument: InputType, other: String): CustomScalar
          four(argument: String = "string"): String
          five(argument: [String] = ["string", "string"]): String
          six(argument: String): Type
        }

        interface Bar {
          one: Type
          four(argument: String = "string"): String
        }

        type Type {
          a: String
        }

        input InputType {
          key: String!
          answer: Int = 42
        }

        type MutationType {
          a(input: InputType): String
        }

        # Scalar description
        scalar CustomScalar

        enum Site {
          DESKTOP
          MOBILE
        }

        union Union = Type | QueryType
      GRAPHQL
      }

      let(:document) {
        subject.new(
          schema
        ).document
      }

      it "returns the IDL without introspection, built ins and schema root" do
        assert equivalent_node?(expected_document, document)
      end
    end

    describe "with defaults" do
      let(:expected_idl) { <<-GRAPHQL
        type QueryType {
          foo: Foo
          u: Union
        }

        type Foo implements Bar {
          one: Type
          two(argument: InputType!): Site
          three(argument: InputType, other: String): CustomScalar
          four(argument: String = "string"): String
          five(argument: [String] = ["string", "string"]): String
          six(argument: String): Type
        }

        interface Bar {
          one: Type
          four(argument: String = "string"): String
        }

        type Type {
          a: String
        }

        input InputType {
          key: String!
          answer: Int = 42
        }

        type MutationType {
          a(input: InputType): String
        }

        # Scalar description
        scalar CustomScalar

        enum Site {
          DESKTOP
          MOBILE
        }

        union Union = Type | QueryType

        schema {
          query: QueryType
          mutation: MutationType
        }
      GRAPHQL
      }

      let(:document) {
        subject.new(
          schema
        ).document
      }

      it "returns the IDL without introspection, built ins and schema if it doesnt respect name conventions" do
        assert equivalent_node?(expected_document, document)
      end
    end

    describe "with a visibility check" do
      let(:expected_idl) { <<-GRAPHQL
        type QueryType {
          foo: Foo
          u: Union
        }

        type Foo implements Bar {
          three(argument: InputType, other: String): CustomScalar
          four(argument: String = "string"): String
          five(argument: [String] = ["string", "string"]): Site
        }

        interface Bar {
          one: Type
          four(argument: String = "string"): String
        }

        input InputType {
          key: String!
          answer: Int = 42
        }

        type MutationType {
          a(input: InputType): String
        }

        # Scalar description
        scalar CustomScalar

        enum Site {
          DESKTOP
          MOBILE
        }

        schema {
          query: QueryType
          mutation: MutationType
        }
      GRAPHQL
      }

      let(:schema) {
        Class.new(GraphQL::Schema.from_definition(schema_idl)) do
          def self.visible?(m, ctx)
            m.graphql_name != "Type"
          end
        end
      }

      let(:document) {
        doc_schema = Class.new(schema) do
          use GraphQL::Schema::Visibility
          def self.visible?(m, _ctx)
            m.respond_to?(:graphql_name) && m.graphql_name != "Type"
          end
        end

        subject.new(doc_schema).document
      }

      it "returns the IDL minus the filtered members" do
        assert equivalent_node?(expected_document, document)
      end
    end

    describe "with an only filter" do
      let(:expected_idl) { <<-GRAPHQL
        type QueryType {
          foo: Foo
          u: Union
        }

        type Foo implements Bar {
          three(argument: InputType, other: String): CustomScalar
          four(argument: String = "string"): String
          five(argument: [String] = ["string", "string"]): Site
        }

        interface Bar {
          one: Type
          four(argument: String = "string"): String
        }

        input InputType {
          key: String!
          answer: Int = 42
        }

        type MutationType {
          a(input: InputType): String
        }

        enum Site {
          DESKTOP
          MOBILE
        }

        schema {
          query: QueryType
          mutation: MutationType
        }
      GRAPHQL
      }

      let(:schema) {
        Class.new(GraphQL::Schema.from_definition(schema_idl)) do
          def self.visible?(m, ctx)
            !(m.respond_to?(:kind) && m.kind.scalar? && m.name == "CustomScalar")
          end
        end
      }

      let(:document) {
        doc_schema = Class.new(schema) do
          def self.visible?(m, _ctx)
            !(m.respond_to?(:kind) && m.kind.scalar? && m.name == "CustomScalar")
          end
        end

        subject.new(doc_schema).document
      }

      it "returns the IDL minus the filtered members" do
        assert equivalent_node?(expected_document, document)
      end
    end

    describe "when excluding built ins and introspection types" do
      let(:expected_idl) { <<-GRAPHQL
        type QueryType {
          foo: Foo
          u: Union
        }

        type Foo implements Bar {
          one: Type
          two(argument: InputType!): Site
          three(argument: InputType, other: String): CustomScalar
          four(argument: String = "string"): String
          five(argument: [String] = ["string", "string"]): String
          six(argument: String): Type
        }

        interface Bar {
          one: Type
          four(argument: String = "string"): String
        }

        type Type {
          a: String
        }

        input InputType {
          key: String!
          answer: Int = 42
        }

        type MutationType {
          a(input: InputType): String
        }

        # Scalar description
        scalar CustomScalar

        enum Site {
          DESKTOP
          MOBILE
        }

        union Union = Type | QueryType

        schema {
          query: QueryType
          mutation: MutationType
        }
      GRAPHQL
      }

      let(:document) {
        subject.new(
          schema,
          always_include_schema: true
        ).document
      }

      it "returns the schema idl besides introspection types and built ins" do
        assert equivalent_node?(expected_document, document)
      end
    end

    describe "when printing excluding only introspection types" do
      let(:expected_idl) { <<-GRAPHQL
        # Represents `true` or `false` values.
        scalar Boolean

        # Represents textual data as UTF-8 character sequences. This type is most often
        # used by GraphQL to represent free-form human-readable text.
        scalar String

        type QueryType {
          foo: Foo
        }

        type Foo implements Bar {
          one: Type
          two(argument: InputType!): Type
          three(argument: InputType, other: String): CustomScalar
          four(argument: String = "string"): String
          five(argument: [String] = ["string", "string"]): String
          six(argument: String): Type
        }

        interface Bar {
          one: Type
          four(argument: String = "string"): String
        }

        type Type {
          a: String
        }

        input InputType {
          key: String!
          answer: Int = 42
        }

        # Represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1.
        scalar Int

        type MutationType {
          a(input: InputType): String
        }

        # Represents signed double-precision fractional values as specified by [IEEE
        # 754](https://en.wikipedia.org/wiki/IEEE_floating_point).
        scalar Float

        # Represents a unique identifier that is Base64 obfuscated. It is often used to
        # refetch an object or as key for a cache. The ID type appears in a JSON response
        # as a String; however, it is not intended to be human-readable. When expected as
        # an input type, any string (such as `"VXNlci0xMA=="`) or integer (such as `4`)
        # input value will be accepted as an ID.
        scalar ID

        # Scalar description
        scalar CustomScalar

        enum Site {
          DESKTOP
          MOBILE
        }

        union Union = Type | QueryType

        directive @skip(if: Boolean!) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

        directive @include(if: Boolean!) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

        # Marks an element of a GraphQL schema as no longer supported.
        directive @deprecated(reason: String = "No longer supported") on FIELD_DEFINITION | ENUM_VALUE

        schema {
          query: QueryType
          mutation: MutationType
        }
      GRAPHQL
      }

      let(:document) {
        subject.new(
          schema,
          include_built_in_scalars: true,
          include_built_in_directives: true,
        ).document
      }

      it "returns the schema IDL including only the built ins and not introspection types" do
        assert equivalent_node?(expected_document, document)
      end
    end

    describe "when printing the full schema" do
      let(:expected_idl) { <<-GRAPHQL
        # Represents `true` or `false` values.
        scalar Boolean

        # Represents textual data as UTF-8 character sequences. This type is most often
        # used by GraphQL to represent free-form human-readable text.
        scalar String

        # The fundamental unit of any GraphQL Schema is the type. There are many kinds of
        # types in GraphQL as represented by the `__TypeKind` enum.
        #
        # Depending on the kind of a type, certain fields describe information about that
        # type. Scalar types provide no information beyond a name and description, while
        # Enum types provide their values. Object and Interface types provide the fields
        # they describe. Abstract types, Union and Interface, provide the Object types
        # possible at runtime. List and NonNull types compose other types.
        type __Type {
          kind: __TypeKind!
          name: String
          description: String
          fields(includeDeprecated: Boolean = false): [__Field!]
          interfaces: [__Type!]
          possibleTypes: [__Type!]
          enumValues(includeDeprecated: Boolean = false): [__EnumValue!]
          inputFields: [__InputValue!]
          ofType: __Type
        }

        # An enum describing what kind of type a given `__Type` is.
        enum __TypeKind {
          # Indicates this type is a scalar.
          SCALAR

          # Indicates this type is an object. `fields` and `interfaces` are valid fields.
          OBJECT

          # Indicates this type is an interface. `fields` and `possibleTypes` are valid fields.
          INTERFACE

          # Indicates this type is a union. `possibleTypes` is a valid field.
          UNION

          # Indicates this type is an enum. `enumValues` is a valid field.
          ENUM

          # Indicates this type is an input object. `inputFields` is a valid field.
          INPUT_OBJECT

          # Indicates this type is a list. `ofType` is a valid field.
          LIST

          # Indicates this type is a non-null. `ofType` is a valid field.
          NON_NULL
        }

        # Object and Interface types are described by a list of Fields, each of which has
        # a name, potentially a list of arguments, and a return type.
        type __Field {
          name: String!
          description: String
          args: [__InputValue!]!
          type: __Type!
          isDeprecated: Boolean!
          deprecationReason: String
        }

        # Arguments provided to Fields or Directives and the input fields of an
        # InputObject are represented as Input Values which describe their type and
        # optionally a default value.
        type __InputValue {
          name: String!
          description: String
          type: __Type!

          # A GraphQL-formatted string representing the default value for this input value.
          defaultValue: String
        }

        # One possible value for a given Enum. Enum values are unique values, not a
        # placeholder for a string or numeric value. However an Enum value is returned in
        # a JSON response as a string.
        type __EnumValue {
          name: String!
          description: String
          isDeprecated: Boolean!
          deprecationReason: String
        }

        type QueryType {
          foo: Foo
        }

        type Foo implements Bar {
          one: Type
          two(argument: InputType!): Type
          three(argument: InputType, other: String): Int
          four(argument: String = "string"): String
          five(argument: [String] = ["string", "string"]): String
          six(argument: String): Type
        }

        interface Bar {
          one: Type
          four(argument: String = "string"): String
        }

        type Type {
          a: String
        }

        input InputType {
          key: String!
          answer: Int = 42
        }

        # Represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1.
        scalar Int

        type MutationType {
          a(input: InputType): String
        }

        # A GraphQL Schema defines the capabilities of a GraphQL server. It exposes all
        # available types and directives on the server, as well as the entry points for
        # query, mutation, and subscription operations.
        type __Schema {
          # A list of all types supported by this server.
          types: [__Type!]!

          # The type that query operations will be rooted at.
          queryType: __Type!

          # If this server supports mutation, the type that mutation operations will be rooted at.
          mutationType: __Type

          # If this server support subscription, the type that subscription operations will be rooted at.
          subscriptionType: __Type

          # A list of all directives supported by this server.
          directives: [__Directive!]!
        }

        # A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document.
        #
        # In some cases, you need to provide options to alter GraphQL's execution behavior
        # in ways field arguments will not suffice, such as conditionally including or
        # skipping a field. Directives provide this by describing additional information
        # to the executor.
        type __Directive {
          name: String!
          description: String
          locations: [__DirectiveLocation!]!
          args: [__InputValue!]!
          onOperation: Boolean!
          onFragment: Boolean!
          onField: Boolean!
        }

        # A Directive can be adjacent to many parts of the GraphQL language, a
        # __DirectiveLocation describes one such possible adjacencies.
        enum __DirectiveLocation {
          # Location adjacent to a query operation.
          QUERY

          # Location adjacent to a mutation operation.
          MUTATION

          # Location adjacent to a subscription operation.
          SUBSCRIPTION

          # Location adjacent to a field.
          FIELD

          # Location adjacent to a fragment definition.
          FRAGMENT_DEFINITION

          # Location adjacent to a fragment spread.
          FRAGMENT_SPREAD

          # Location adjacent to an inline fragment.
          INLINE_FRAGMENT

          # Location adjacent to a schema definition.
          SCHEMA

          # Location adjacent to a scalar definition.
          SCALAR

          # Location adjacent to an object type definition.
          OBJECT

          # Location adjacent to a field definition.
          FIELD_DEFINITION

          # Location adjacent to an argument definition.
          ARGUMENT_DEFINITION

          # Location adjacent to an interface definition.
          INTERFACE

          # Location adjacent to a union definition.
          UNION

          # Location adjacent to an enum definition.
          ENUM

          # Location adjacent to an enum value definition.
          ENUM_VALUE

          # Location adjacent to an input object type definition.
          INPUT_OBJECT

          # Location adjacent to an input object field definition.
          INPUT_FIELD_DEFINITION
        }

        # Represents signed double-precision fractional values as specified by [IEEE
        # 754](https://en.wikipedia.org/wiki/IEEE_floating_point).
        scalar Float

        # Represents a unique identifier that is Base64 obfuscated. It is often used to
        # refetch an object or as key for a cache. The ID type appears in a JSON response
        # as a String; however, it is not intended to be human-readable. When expected as
        # an input type, any string (such as `"VXNlci0xMA=="`) or integer (such as `4`)
        # input value will be accepted as an ID.
        scalar ID

        # Scalar description
        scalar CustomScalar

        enum Site {
          DESKTOP
          MOBILE
        }

        union Union = Type | QueryType

        directive @skip(if: Boolean!) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

        directive @include(if: Boolean!) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

        # Marks an element of a GraphQL schema as no longer supported.
        directive @deprecated(reason: String = "No longer supported") on FIELD_DEFINITION | ENUM_VALUE

        schema {
          query: QueryType
          mutation: MutationType
        }
      GRAPHQL
      }

      let(:document) {
        subject.new(
          schema,
          include_introspection_types: true,
          include_built_in_directives: true,
          include_built_in_scalars: true,
          always_include_schema: true,
        ).document
      }

      it "returns the full document AST from the given schema including built ins and introspection" do
        assert equivalent_node?(expected_document, document)
      end
    end
  end

  private

  def equivalent_node?(expected, node)
    return false unless expected.is_a?(node.class)

    if expected.respond_to?(:children) && expected.respond_to?(:scalars)
      children_equal = expected.children.all? do |expected_child|
        node.children.find { |child| equivalent_node?(expected_child, child) }
      end

      scalars_equal = expected.children.all? do |expected_child|
        node.children.find { |child| equivalent_node?(expected_child, child) }
      end

      children_equal && scalars_equal
    else
      expected == node
    end
  end

  describe "custom SDL directives" do
    class CustomSDLDirectiveSchema < GraphQL::Schema
      class CustomThing < GraphQL::Schema::Directive
        locations(FIELD_DEFINITION)
        argument :stuff, String
      end

      directive CustomThing

      class Query < GraphQL::Schema::Object
        field :f, Int, directives: { CustomThing => { stuff: "ok" } }
      end
      query(Query)
    end

    it "prints them out" do
      expected_str = <<~GRAPHQL
        directive @customThing(stuff: String!) on FIELD_DEFINITION

        type Query {
          f: Int @customThing(stuff: "ok")
        }
      GRAPHQL
      assert_equal expected_str, CustomSDLDirectiveSchema.to_definition
    end
  end
end
