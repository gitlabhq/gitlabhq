# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Printer do
  class PrinterTestSchema < GraphQL::Schema
    module Node
      include GraphQL::Schema::Interface
      field :id, ID, null: false
    end

    class HiddenDirective < GraphQL::Schema::Directive
      def self.visible?(ctx); false; end
      locations(GraphQL::Schema::Directive::ENUM_VALUE)
    end

    class Choice < GraphQL::Schema::Enum
      value "FOO", value: :foo
      value "BAR", value: :bar, directives: { HiddenDirective => {} }
      value "BAZ", deprecation_reason: <<-REASON
Use "BAR" instead.

It's the replacement for this value.
REASON
      value "WOZ", deprecation_reason: GraphQL::Schema::Directive::DEFAULT_DEPRECATION_REASON
    end

    class Sub < GraphQL::Schema::InputObject
      description "Test"
      argument :string, String, required: false, description: "Something"
      argument :int, Int, required: false, description: "Something", deprecation_reason: "Do something else"
    end

    class Varied < GraphQL::Schema::InputObject
      argument :id, ID, required: false
      argument :int, Int, required: false
      argument :float, Float, required: false
      argument :bool, Boolean, required: false
      argument :some_enum, Choice, required: false, default_value: :foo
      argument :sub, [Sub, null: true], required: false
    end

    class Comment < GraphQL::Schema::Object
      description "A blog comment"
      implements Node
      field :id, ID, null: false
    end

    class Post < GraphQL::Schema::Object
      description "A blog post"
      field :id, ID, null: false
      field :title, String, null: false
      field :body, String, null: false
      field :comments, [Comment]
      field :comments_count, Int, null: false, deprecation_reason: "Use \"comments\".", camelize: false
    end

    class Audio < GraphQL::Schema::Object
      field :id, ID, null: false
      field :name, String, null: false
      field :duration, Int, null: false
    end

    class Image < GraphQL::Schema::Object
      field :id, ID, null: false
      field :name, String, null: false
      field :width, Int, null: false
      field :height, Int, null: false
    end

    class Media < GraphQL::Schema::Union
      description "Media objects"
      possible_types Image, Audio
    end

    class MediaRating < GraphQL::Schema::Enum
      value :AWESOME
      value :MEH
      value :BOO_HISS
    end


    class NoFields < GraphQL::Schema::Object
      has_no_fields(true)
    end

    class NoArguments < GraphQL::Schema::InputObject
      has_no_arguments(true)
    end

    class Query < GraphQL::Schema::Object
      description "The query root of this schema"

      field :post, Post do
        argument :id, ID, description: "Post ID"
        argument :varied, Varied, required: false, default_value: { id: "123", int: 234, float: 2.3, some_enum: :foo, sub: [{ string: "str" }] }
        argument :varied_with_nulls, Varied, required: false, default_value: { id: nil, int: nil, float: nil, some_enum: nil, sub: nil }
        argument :deprecated_arg, String, required: false, deprecation_reason: "Use something else"
      end

      field :no_fields_type, NoFields do
        argument :no_arguments_input, NoArguments
      end

      field :example_media, Media
    end

    class CreatePost < GraphQL::Schema::RelayClassicMutation
      description "Create a blog post"
      argument :title, String
      argument :body, String
      field :post, Post
    end

    class Mutation < GraphQL::Schema::Object
      field :create_post, mutation: CreatePost
    end

    class Subscription < GraphQL::Schema::Object
      field :post, Post do
        argument :id, ID
      end
    end

    query(Query)
    mutation(Mutation)
    subscription(Subscription)
    extra_types [MediaRating]

    if !use_visibility_profile?
      use GraphQL::Schema::Warden
    end
  end

  let(:schema) { PrinterTestSchema }

  describe ".print_introspection_schema" do
    it "returns the schema as a string for the introspection types" do
      # From https://github.com/graphql/graphql-js/blob/6a0e00fe46951767287f2cc62e1a10b167b2eaa6/src/utilities/__tests__/schemaPrinter-test.js#L599
      expected = <<-GRAPHQL
schema {
  query: Root
}

"""
Marks an element of a GraphQL schema as no longer supported.
"""
directive @deprecated(
  """
  Explains why this element was deprecated, usually also including a suggestion
  for how to access supported similar data. Formatted in
  [Markdown](https://daringfireball.net/projects/markdown/).
  """
  reason: String = "No longer supported"
) on ARGUMENT_DEFINITION | ENUM_VALUE | FIELD_DEFINITION | INPUT_FIELD_DEFINITION

"""
Directs the executor to include this field or fragment only when the `if` argument is true.
"""
directive @include(
  """
  Included when true.
  """
  if: Boolean!
) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

"""
Requires that exactly one field must be supplied and that field must not be `null`.
"""
directive @oneOf on INPUT_OBJECT

"""
Directs the executor to skip this field or fragment when the `if` argument is true.
"""
directive @skip(
  """
  Skipped when true.
  """
  if: Boolean!
) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

"""
Exposes a URL that specifies the behavior of this scalar.
"""
directive @specifiedBy(
  """
  The URL that specifies the behavior of this scalar.
  """
  url: String!
) on SCALAR

"""
A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document.

In some cases, you need to provide options to alter GraphQL's execution behavior
in ways field arguments will not suffice, such as conditionally including or
skipping a field. Directives provide this by describing additional information
to the executor.
"""
type __Directive {
  args(includeDeprecated: Boolean = false): [__InputValue!]!
  description: String
  isRepeatable: Boolean
  locations: [__DirectiveLocation!]!
  name: String!
  onField: Boolean! @deprecated(reason: "Use `locations`.")
  onFragment: Boolean! @deprecated(reason: "Use `locations`.")
  onOperation: Boolean! @deprecated(reason: "Use `locations`.")
}

"""
A Directive can be adjacent to many parts of the GraphQL language, a
__DirectiveLocation describes one such possible adjacencies.
"""
enum __DirectiveLocation {
  """
  Location adjacent to an argument definition.
  """
  ARGUMENT_DEFINITION

  """
  Location adjacent to an enum definition.
  """
  ENUM

  """
  Location adjacent to an enum value definition.
  """
  ENUM_VALUE

  """
  Location adjacent to a field.
  """
  FIELD

  """
  Location adjacent to a field definition.
  """
  FIELD_DEFINITION

  """
  Location adjacent to a fragment definition.
  """
  FRAGMENT_DEFINITION

  """
  Location adjacent to a fragment spread.
  """
  FRAGMENT_SPREAD

  """
  Location adjacent to an inline fragment.
  """
  INLINE_FRAGMENT

  """
  Location adjacent to an input object field definition.
  """
  INPUT_FIELD_DEFINITION

  """
  Location adjacent to an input object type definition.
  """
  INPUT_OBJECT

  """
  Location adjacent to an interface definition.
  """
  INTERFACE

  """
  Location adjacent to a mutation operation.
  """
  MUTATION

  """
  Location adjacent to an object type definition.
  """
  OBJECT

  """
  Location adjacent to a query operation.
  """
  QUERY

  """
  Location adjacent to a scalar definition.
  """
  SCALAR

  """
  Location adjacent to a schema definition.
  """
  SCHEMA

  """
  Location adjacent to a subscription operation.
  """
  SUBSCRIPTION

  """
  Location adjacent to a union definition.
  """
  UNION

  """
  Location adjacent to a variable definition.
  """
  VARIABLE_DEFINITION
}

"""
One possible value for a given Enum. Enum values are unique values, not a
placeholder for a string or numeric value. However an Enum value is returned in
a JSON response as a string.
"""
type __EnumValue {
  deprecationReason: String
  description: String
  isDeprecated: Boolean!
  name: String!
}

"""
Object and Interface types are described by a list of Fields, each of which has
a name, potentially a list of arguments, and a return type.
"""
type __Field {
  args(includeDeprecated: Boolean = false): [__InputValue!]!
  deprecationReason: String
  description: String
  isDeprecated: Boolean!
  name: String!
  type: __Type!
}

"""
Arguments provided to Fields or Directives and the input fields of an
InputObject are represented as Input Values which describe their type and
optionally a default value.
"""
type __InputValue {
  """
  A GraphQL-formatted string representing the default value for this input value.
  """
  defaultValue: String
  deprecationReason: String
  description: String
  isDeprecated: Boolean!
  name: String!
  type: __Type!
}

"""
A GraphQL Schema defines the capabilities of a GraphQL server. It exposes all
available types and directives on the server, as well as the entry points for
query, mutation, and subscription operations.
"""
type __Schema {
  description: String

  """
  A list of all directives supported by this server.
  """
  directives: [__Directive!]!

  """
  If this server supports mutation, the type that mutation operations will be rooted at.
  """
  mutationType: __Type

  """
  The type that query operations will be rooted at.
  """
  queryType: __Type!

  """
  If this server support subscription, the type that subscription operations will be rooted at.
  """
  subscriptionType: __Type

  """
  A list of all types supported by this server.
  """
  types: [__Type!]!
}

"""
The fundamental unit of any GraphQL Schema is the type. There are many kinds of
types in GraphQL as represented by the `__TypeKind` enum.

Depending on the kind of a type, certain fields describe information about that
type. Scalar types provide no information beyond a name and description, while
Enum types provide their values. Object and Interface types provide the fields
they describe. Abstract types, Union and Interface, provide the Object types
possible at runtime. List and NonNull types compose other types.
"""
type __Type {
  description: String
  enumValues(includeDeprecated: Boolean = false): [__EnumValue!]
  fields(includeDeprecated: Boolean = false): [__Field!]
  inputFields(includeDeprecated: Boolean = false): [__InputValue!]
  interfaces: [__Type!]
  isOneOf: Boolean!
  kind: __TypeKind!
  name: String
  ofType: __Type
  possibleTypes: [__Type!]
  specifiedByURL: String
}

"""
An enum describing what kind of type a given `__Type` is.
"""
enum __TypeKind {
  """
  Indicates this type is an enum. `enumValues` is a valid field.
  """
  ENUM

  """
  Indicates this type is an input object. `inputFields` is a valid field.
  """
  INPUT_OBJECT

  """
  Indicates this type is an interface. `fields` and `possibleTypes` are valid fields.
  """
  INTERFACE

  """
  Indicates this type is a list. `ofType` is a valid field.
  """
  LIST

  """
  Indicates this type is a non-null. `ofType` is a valid field.
  """
  NON_NULL

  """
  Indicates this type is an object. `fields` and `interfaces` are valid fields.
  """
  OBJECT

  """
  Indicates this type is a scalar.
  """
  SCALAR

  """
  Indicates this type is a union. `possibleTypes` is a valid field.
  """
  UNION
}
GRAPHQL
      assert_equal expected.chomp, GraphQL::Schema::Printer.print_introspection_schema
    end
  end

  describe ".print_schema" do
    it "includes schema definition when query root name doesn't match convention" do
      custom_query = Class.new(PrinterTestSchema::Query) { graphql_name "MyQueryRoot" }
      custom_schema = Class.new(PrinterTestSchema) { query(custom_query) }

      expected = <<SCHEMA
schema {
  query: MyQueryRoot
  mutation: Mutation
  subscription: Subscription
}
SCHEMA
      assert_match expected, GraphQL::Schema::Printer.print_schema(custom_schema)
    end

    it "includes schema definition when mutation root name doesn't match convention" do
      custom_mutation = Class.new(PrinterTestSchema::Mutation) { graphql_name "MyMutationRoot" }
      custom_schema = Class.new(PrinterTestSchema) { mutation(custom_mutation) }

      expected = <<SCHEMA
schema {
  query: Query
  mutation: MyMutationRoot
  subscription: Subscription
}
SCHEMA

      assert_match expected, GraphQL::Schema::Printer.print_schema(custom_schema)
    end

    it "includes schema definition when subscription root name doesn't match convention" do
      custom_subscription = Class.new(PrinterTestSchema::Subscription) { graphql_name "MySubscriptionRoot" }
      custom_schema = Class.new(PrinterTestSchema) { subscription(custom_subscription) }

      expected = <<GRAPHQL
schema {
  query: Query
  mutation: Mutation
  subscription: MySubscriptionRoot
}
GRAPHQL

      assert_match expected, GraphQL::Schema::Printer.print_schema(custom_schema)
    end

    it "returns the schema as a string for the defined types" do
      expected = <<GRAPHQL
type Audio {
  duration: Int!
  id: ID!
  name: String!
}

enum Choice {
  BAR
  BAZ @deprecated(reason: "Use \\\"BAR\\\" instead.\\n\\nIt's the replacement for this value.\\n")
  FOO
  WOZ @deprecated
}

"""
A blog comment
"""
type Comment implements Node {
  id: ID!
}

"""
Autogenerated input type of CreatePost
"""
input CreatePostInput {
  body: String!

  """
  A unique identifier for the client performing the mutation.
  """
  clientMutationId: String
  title: String!
}

"""
Autogenerated return type of CreatePost.
"""
type CreatePostPayload {
  """
  A unique identifier for the client performing the mutation.
  """
  clientMutationId: String
  post: Post
}

type Image {
  height: Int!
  id: ID!
  name: String!
  width: Int!
}

"""
Media objects
"""
union Media = Audio | Image

enum MediaRating {
  AWESOME
  BOO_HISS
  MEH
}

type Mutation {
  """
  Create a blog post
  """
  createPost(
    """
    Parameters for CreatePost
    """
    input: CreatePostInput!
  ): CreatePostPayload
}

input NoArguments

type NoFields

interface Node {
  id: ID!
}

"""
A blog post
"""
type Post {
  body: String!
  comments: [Comment!]
  comments_count: Int! @deprecated(reason: "Use \\\"comments\\\".")
  id: ID!
  title: String!
}

"""
The query root of this schema
"""
type Query {
  exampleMedia: Media
  noFieldsType(noArgumentsInput: NoArguments!): NoFields
  post(
    deprecatedArg: String @deprecated(reason: "Use something else")

    """
    Post ID
    """
    id: ID!
    varied: Varied = {id: "123", int: 234, float: 2.3, someEnum: FOO, sub: [{string: "str"}]}
    variedWithNulls: Varied = {id: null, int: null, float: null, someEnum: null, sub: null}
  ): Post
}

"""
Test
"""
input Sub {
  """
  Something
  """
  int: Int @deprecated(reason: "Do something else")

  """
  Something
  """
  string: String
}

type Subscription {
  post(id: ID!): Post
}

input Varied {
  bool: Boolean
  float: Float
  id: ID
  int: Int
  someEnum: Choice = FOO
  sub: [Sub]
}
GRAPHQL

      assert_equal expected, GraphQL::Schema::Printer.print_schema(schema)
    end

    it 'prints a schema without directives' do
      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'

        field :foobar, Integer, null: false

        def foobar
          152
        end
      end

      schema = Class.new(GraphQL::Schema) do
        query query_type
      end

      expected = "type Query {\n  foobar: Int!\n}\n"
      assert_equal expected, GraphQL::Schema::Printer.new(schema).print_schema
    end
  end

  it "applies an `only` filter" do
    expected = <<SCHEMA
enum MediaRating {
  AWESOME
  BOO_HISS
  MEH
}

"""
A blog post
"""
type Post {
  body: String!
  id: ID!
  title: String!
}

"""
The query root of this schema
"""
type Query {
  post(deprecatedArg: String @deprecated(reason: "Use something else")): Post
}
SCHEMA

    custom_filter_schema = Class.new(schema) do
      use GraphQL::Schema::Warden if ADD_WARDEN
      def self.visible?(member, ctx)
        case member
        when Module
          if !member.respond_to?(:kind)
            super
          else
            case member.kind.name
            when "SCALAR"
              true
            when "OBJECT", "UNION", "INTERFACE"
              ctx[:names].include?(member.graphql_name) || member.introspection?
            else
              member.introspection?
            end
          end
        when GraphQL::Schema::Argument
          member.graphql_name != "id"
        else
          if member.respond_to?(:deprecation_reason)
            member.deprecation_reason.nil?
          end
        end
      end
    end
    context = { names: ["Query", "Post"] }
    assert_equal expected, custom_filter_schema.to_definition(context: context)
  end

  it "applies an `except` filter" do
    expected = <<SCHEMA
type Audio {
  duration: Int!
  id: ID!
  name: String!
}

"""
A blog comment
"""
type Comment implements Node {
  id: ID!
}

"""
Autogenerated input type of CreatePost
"""
input CreatePostInput {
  body: String!

  """
  A unique identifier for the client performing the mutation.
  """
  clientMutationId: String
  title: String!
}

"""
Autogenerated return type of CreatePost.
"""
type CreatePostPayload {
  """
  A unique identifier for the client performing the mutation.
  """
  clientMutationId: String
  post: Post
}

"""
Media objects
"""
union Media = Audio

enum MediaRating {
  AWESOME
  BOO_HISS
  MEH
}

type Mutation {
  """
  Create a blog post
  """
  createPost(
    """
    Parameters for CreatePost
    """
    input: CreatePostInput!
  ): CreatePostPayload
}

input NoArguments

type NoFields

interface Node {
  id: ID!
}

"""
A blog post
"""
type Post {
  body: String!
  comments: [Comment!]
  id: ID!
  title: String!
}

"""
The query root of this schema
"""
type Query {
  exampleMedia: Media
  noFieldsType(noArgumentsInput: NoArguments!): NoFields
  post(
    """
    Post ID
    """
    id: ID!
  ): Post
}

type Subscription {
  post(id: ID!): Post
}
SCHEMA

    custom_filter_schema = Class.new(schema) do
      use GraphQL::Schema::Warden if ADD_WARDEN
      def self.visible?(member, ctx)
        super && (!(ctx[:names].include?(member.graphql_name) || (member.respond_to?(:deprecation_reason) && member.deprecation_reason)))
      end
    end

    context = { names: ["Varied", "Image", "Sub"] }
    assert_equal expected, custom_filter_schema.to_definition(context: context)
  end

  describe "#print_type" do
    it "returns the type schema as a string" do
      expected = <<SCHEMA
"""
A blog post
"""
type Post {
  body: String!
  comments: [Comment!]
  comments_count: Int! @deprecated(reason: "Use \\\"comments\\\".")
  id: ID!
  title: String!
}
SCHEMA
      assert_equal expected.chomp, GraphQL::Schema::Printer.new(schema).print_type(schema.types['Post'])
    end

    it "can print non-object types" do
      expected = <<SCHEMA
"""
Test
"""
input Sub {
  """
  Something
  """
  int: Int @deprecated(reason: "Do something else")

  """
  Something
  """
  string: String
}
SCHEMA
      assert_equal expected.chomp, GraphQL::Schema::Printer.new(schema).print_type(schema.types['Sub'])
    end

    class DefaultValueTestSchema < GraphQL::Schema
      BackingObject = Struct.new(:value)

      class SomeType < GraphQL::Schema::Scalar
        graphql_name "SomeType"
        def self.coerce_input(value, ctx)
          BackingObject.new(value)
        end

        def self.coerce_result(obj, ctx)
          obj.value
        end
      end

      class Query < GraphQL::Schema::Object
        description "The query root of this schema"
        field :example, SomeType do
          argument :input, SomeType, default_value: BackingObject.new("Howdy"), required: false
        end

        def example(input:)
          input
        end
      end
      query(Query)
    end

    it "can print arguments that use non-standard Ruby objects as default values" do
      expected = <<SCHEMA
"""
The query root of this schema
"""
type Query {
  example(input: SomeType = "Howdy"): SomeType
}
SCHEMA

      assert_equal expected.chomp, GraphQL::Schema::Printer.new(DefaultValueTestSchema).print_type(DefaultValueTestSchema::Query)
    end
  end

  describe "#print_directive" do
    it "prints the deprecation reason in a single line escaped string including line breaks" do
      expected = <<SCHEMA.chomp
enum Choice {
  BAR
  BAZ @deprecated(reason: "Use \\\"BAR\\\" instead.\\n\\nIt's the replacement for this value.\\n")
  FOO
  WOZ @deprecated
}
SCHEMA

      assert_includes GraphQL::Schema::Printer.new(schema).print_schema, expected
    end
  end

  it "prints schemas from class" do
    class TestPrintSchema < GraphQL::Schema
      class OddlyNamedQuery < GraphQL::Schema::Object
        field :int, Int, null: false
      end

      query(OddlyNamedQuery)
    end


    str = GraphQL::Schema::Printer.print_schema TestPrintSchema
    assert_equal "schema {\n  query: OddlyNamedQuery\n}\n\ntype OddlyNamedQuery {\n  int: Int!\n}\n", str
  end

  it "prints directives parsed from IDL" do
    input = <<-GRAPHQL
directive @a(a: Letter) on ENUM_VALUE

directive @b(b: BInput) on ENUM_VALUE

directive @customDirective on FIELD_DEFINITION

directive @directiveWithDeprecatedArg(deprecatedArg: Boolean @deprecated(reason: "Don't use me!")) on OBJECT

directive @intDir(a: Int!) on INPUT_FIELD_DEFINITION

directive @someDirective on OBJECT

input BInput {
  b: Letter
}

input I {
  i1: Int @intDir(a: 1)
}

enum Letter {
  A
  B
}

type Query @someDirective {
  e(i: I): Thing
  i: Int! @customDirective
}

enum Thing {
  A @a(a: A)
  B @b(b: {b: B})
}
    GRAPHQL

    schema = GraphQL::Schema.from_definition(input)
    assert_equal input, GraphQL::Schema::Printer.print_schema(schema)
  end

  describe "when Union is used in extra_types" do
    it "can be included" do
      obj_1 = Class.new(GraphQL::Schema::Object) { graphql_name("Obj1"); field(:f1, String)}
      obj_2 = Class.new(GraphQL::Schema::Object) { graphql_name("Obj2"); field(:f2, obj_1) }
      union_type = Class.new(GraphQL::Schema::Union) do
        graphql_name "Union1"
        possible_types(obj_1, obj_2)
      end

      assert_equal "union Union1 = Obj1 | Obj2\n", Class.new(GraphQL::Schema) { extra_types(union_type) }.to_definition

      expected_defn = <<~GRAPHQL
        type Obj1 {
          f1: String
        }

        type Obj2 {
          f2: Obj1
        }

        union Union1 = Obj1 | Obj2
      GRAPHQL
      assert_equal expected_defn, Class.new(GraphQL::Schema) { extra_types(union_type, obj_1, obj_2) }.to_definition
    end
  end
end
