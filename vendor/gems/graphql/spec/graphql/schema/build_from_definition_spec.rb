# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::BuildFromDefinition do
  # Build a schema from `definition` and assert that it
  # prints out the same string.
  # Then return the built schema.
  def assert_schema_and_compare_output(definition)
    built_schema = GraphQL::Schema.from_definition(definition)
    assert_equal definition, GraphQL::Schema::Printer.print_schema(built_schema)
    built_schema
  end

  describe '.build' do
    it 'can build a schema with a simple type' do
      schema = <<-SCHEMA
schema {
  query: HelloScalars
}

type HelloScalars {
  bool: Boolean
  float: Float
  id: ID
  int: Int
  str: String!
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'can build a schema with underscored names' do
      schema = <<-SCHEMA
type A_Type {
  f(argument_1: Int, argument_two: Int): Int
}

type Query {
  some_field: A_Type
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'can build a schema with default input object values' do
      schema = <<-SCHEMA
input InputObject {
  a: Int
}

type Query {
  a(input: InputObject = {a: 1}): String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'can build a schema with directives' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

directive @foo(arg: Int, nullDefault: Int = null) on FIELD

directive @greeting(pleasant: Boolean = true) on ARGUMENT_DEFINITION | ENUM | FIELD_DEFINITION | INPUT_OBJECT | INTERFACE | OBJECT | UNION

directive @greeting2 on INTERFACE

directive @hashed repeatable on FIELD_DEFINITION | INPUT_FIELD_DEFINITION

directive @language(is: String!) on ENUM_VALUE

type Hello implements Secret & Secret2 @greeting {
  goodbye(saying: Parting @greeting): Parting
  humbug: Int @greeting(pleasant: false)
  password: Phrase @hashed
  password2: String
  str(in: Input): String
}

input Input @greeting {
  value: String @hashed
}

enum Parting @greeting {
  AU_REVOIR @language(is: "fr")
  ZAI_JIAN @language(is: "zh")
}

union Phrase @greeting = Hello | Word

interface Secret implements Secret2 @greeting @greeting2 {
  password: String
  password2: String
}

interface Secret2 {
  password2: String
}

type Word {
  str: String
}
      SCHEMA

      parsed_schema = GraphQL::Schema.from_definition(schema)
      hello_type = parsed_schema.get_type("Hello")
      assert_equal ["deprecated", "foo", "greeting", "greeting2", "hashed", "include", "language", "oneOf", "skip", "specifiedBy"], parsed_schema.directives.keys.sort
      parsed_schema.directives.values.each do |dir_class|
        assert dir_class < GraphQL::Schema::Directive
      end

      assert_equal true, parsed_schema.directives["hashed"].repeatable?
      assert_equal false, parsed_schema.directives["deprecated"].repeatable?

      assert_equal 1, hello_type.directives.size
      assert_instance_of parsed_schema.directives["greeting"], hello_type.directives.first
      assert_equal({ pleasant: true }, hello_type.directives.first.arguments.keyword_arguments)

      humbug_directives = hello_type.get_field("humbug").directives
      assert_equal 1, humbug_directives.size
      assert_instance_of parsed_schema.directives["greeting"], humbug_directives.first
      assert_equal({ pleasant: false }, humbug_directives.first.arguments.keyword_arguments)

      au_revoir_directives = parsed_schema.get_type("Parting").values["AU_REVOIR"].directives
      assert_equal 1, au_revoir_directives.size
      assert_instance_of parsed_schema.directives["language"], au_revoir_directives.first
      assert_equal({ is: "fr" }, au_revoir_directives.first.arguments.keyword_arguments)

      secret_type = parsed_schema.get_type("Secret")
      assert_equal 2, secret_type.directives.size

      assert_schema_and_compare_output(schema)
    end

    it 'supports descriptions and definition_line' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

"""
This is a directive
"""
directive @foo(
  """
  It has an argument
  """
  arg: Int
) on FIELD

"""
With an enum
"""
enum Color {
  BLUE

  """
  Not a creative color
  """
  GREEN
  RED
}

"""
What a great type
"""
type Hello implements I {
  anEnum(s: S): Color

  """
  And a field to boot
  """
  str(i: Input): String
  u: U
}

"""
An interface
"""
interface I {
  str(i: Input): String
}

"""
And an Input
"""
input Input {
  s: String
}

"""
A scalar
"""
scalar S

"""
And a union
"""
union U = Hello
      SCHEMA

      assert_schema_and_compare_output(schema)

      # TODO: GraphQL::CParser doesn't support definition_line yet.
      built_schema = GraphQL::Schema.from_definition(schema, parser: GraphQL::Language::Parser)
      # The schema's are the same since there's no description
      assert_equal 1, built_schema.ast_node.line
      assert_equal 1, built_schema.ast_node.definition_line

      # These account for description:
      assert_equal 5, built_schema.directives["foo"].ast_node.line, "The ast_node.line points to the description"
      assert_equal 8, built_schema.directives["foo"].ast_node.definition_line, "The ast_node.definition_line points to the definition"

      arg = built_schema.directives["foo"].arguments["arg"]
      assert_equal 9, arg.ast_node.line
      assert_equal 12, arg.ast_node.definition_line

      enum_type = built_schema.types["Color"]
      assert_equal 15, enum_type.ast_node.line, "The ast_node.line points to the description"
      assert_equal 18, enum_type.ast_node.definition_line, "The ast_node.definition_line points to the definition"

      enum_value = enum_type.values["GREEN"]
      assert_equal 21, enum_value.ast_node.line
      assert_equal 24, enum_value.ast_node.definition_line

      obj_type = built_schema.types["Hello"]
      assert_equal 28, obj_type.ast_node.line, "The ast_node.line points to the description"
      assert_equal 31, obj_type.ast_node.definition_line, "The ast_node.definition_line points to the definition"

      field = obj_type.fields["str"]
      assert_equal 34, field.ast_node.line
      assert_equal 37, field.ast_node.definition_line

      assert_equal 41, built_schema.types["I"].ast_node.line
      assert_equal 44, built_schema.types["I"].ast_node.definition_line

      assert_equal 48, built_schema.types["Input"].ast_node.line
      assert_equal 51, built_schema.types["Input"].ast_node.definition_line

      assert_equal 55, built_schema.types["S"].ast_node.line
      assert_equal 58, built_schema.types["S"].ast_node.definition_line

      assert_equal 60, built_schema.types["U"].ast_node.line
      assert_equal 63, built_schema.types["U"].ast_node.definition_line
    end

    it 'handles empty type descriptions' do
      schema = <<-SCHEMA
"""
"""
type Query {
  f1: Int
}
      SCHEMA
      refute_nil GraphQL::Schema.from_definition(schema)
    end

    it 'maintains built-in directives' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello {
  str: String
}
      SCHEMA

      built_schema = GraphQL::Schema.from_definition(schema)
      assert_equal ['deprecated', 'include', 'oneOf', 'skip', 'specifiedBy'], built_schema.directives.keys.sort
    end

    it 'supports overriding built-in directives' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

directive @skip on FIELD
directive @include on FIELD
directive @deprecated on FIELD_DEFINITION

type Hello {
  str: String
}
      SCHEMA

      built_schema = GraphQL::Schema.from_definition(schema)

      refute built_schema.directives['skip'] == GraphQL::Schema::Directive::Skip
      refute built_schema.directives['include'] == GraphQL::Schema::Directive::Include
      refute built_schema.directives['deprecated'] == GraphQL::Schema::Directive::Deprecated
    end

    it 'supports adding directives while maintaining built-in directives' do
      schema = <<-SCHEMA
schema @custom(thing: true) {
  query: Hello
}

directive @foo(arg: Int) on FIELD
directive @custom(thing: Boolean) on SCHEMA

type Hello {
  str: String
}
      SCHEMA

      built_schema = GraphQL::Schema.from_definition(schema)

      assert built_schema.directives.keys.include?('skip')
      assert built_schema.directives.keys.include?('include')
      assert built_schema.directives.keys.include?('deprecated')
      assert built_schema.directives.keys.include?('foo')
    end

    it 'supports type modifiers' do
      schema = <<-SCHEMA
schema {
  query: HelloScalars
}

type HelloScalars {
  listOfNonNullStrs: [String!]
  listOfStrs: [String]
  nonNullListOfNonNullStrs: [String!]!
  nonNullListOfStrs: [String]!
  nonNullStr: String!
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports recursive type' do
      schema = <<-SCHEMA
schema {
  query: Recurse
}

type Recurse {
  recurse: Recurse
  str: String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports two types circular' do
      schema = <<-SCHEMA
schema {
  query: TypeOne
}

type TypeOne {
  str: String
  typeTwo: TypeTwo
}

type TypeTwo {
  str: String
  typeOne: TypeOne
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports single argument fields' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello {
  booleanToStr(bool: Boolean): String
  floatToStr(float: Float): String
  idToStr(id: ID): String
  str(int: Int): String
  strToStr(bool: String): String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'properly understands connections' do
      schema = <<-SCHEMA
schema {
  query: Type
}

type Organization {
  email: String
}

"""
The connection type for Organization.
"""
type OrganizationConnection {
  """
  A list of edges.
  """
  edges: [OrganizationEdge]

  """
  A list of nodes.
  """
  nodes: [Organization]

  """
  Information to aid in pagination.
  """
  pageInfo: PageInfo!

  """
  Identifies the total count of items in the connection.
  """
  totalCount: Int!
}

"""
An edge in a connection.
"""
type OrganizationEdge {
  """
  A cursor for use in pagination.
  """
  cursor: String!

  """
  The item at the end of the edge.
  """
  node: Organization
}

"""
Information about pagination in a connection.
"""
type PageInfo {
  """
  When paginating forwards, the cursor to continue.
  """
  endCursor: String

  """
  When paginating forwards, are there more items?
  """
  hasNextPage: Boolean!

  """
  When paginating backwards, are there more items?
  """
  hasPreviousPage: Boolean!

  """
  When paginating backwards, the cursor to continue.
  """
  startCursor: String
}

type Type {
  name: String
  organization(
    """
    The login of the organization to find.
    """
    login: String!
  ): Organization

  """
  A list of organizations the user belongs to.
  """
  organizations(
    """
    Returns the elements in the list that come after the specified cursor.
    """
    after: String

    """
    Returns the elements in the list that come before the specified cursor.
    """
    before: String

    """
    Returns the first _n_ elements from the list.
    """
    first: Int

    """
    Returns the last _n_ elements from the list.
    """
    last: Int
  ): OrganizationConnection!
}
      SCHEMA

      built_schema = assert_schema_and_compare_output(schema)
      obj = built_schema.types["Type"]
      refute obj.fields["organization"].connection?
      assert obj.fields["organizations"].connection?
    end

    it 'supports simple type with multiple arguments' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello {
  str(bool: Boolean, int: Int): String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports simple type with interface' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello implements WorldInterface {
  str: String
}

interface WorldInterface {
  str: String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it "supports interfaces that implement interfaces" do
      schema = <<-SCHEMA
interface Named implements Node {
  id: ID
  name: String
}

interface Node {
  id: ID
}

type Query {
  thing: Thing
}

type Thing implements Named & Node {
  id: ID
  name: String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it "only adds the interface to the type once" do
      schema = <<-SCHEMA
interface Named implements Node {
  id: ID
  name: String
}

interface Node {
  id: ID
}

type Query {
  thing: Thing
}

type Thing implements Named & Node & Timestamped {
  id: ID
  name: String
  timestamp: String
}

interface Timestamped implements Node {
  id: ID
  timestamp: String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports simple output enum' do
      schema = <<-SCHEMA
schema {
  query: OutputEnumRoot
}

enum Hello {
  WORLD
}

type OutputEnumRoot {
  hello: Hello
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports simple input enum' do
      schema = <<-SCHEMA
schema {
  query: InputEnumRoot
}

enum Hello {
  WORLD
}

type InputEnumRoot {
  str(hello: Hello): String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports multiple value enum' do
      schema = <<-SCHEMA
schema {
  query: OutputEnumRoot
}

enum Hello {
  RLD
  WO
}

type OutputEnumRoot {
  hello: Hello
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports simple union' do
      schema = <<-SCHEMA
schema {
  query: Root
}

union Hello = World

type Root {
  hello: Hello
}

type World {
  str: String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports multiple union' do
      schema = <<-SCHEMA
schema {
  query: Root
}

union Hello = WorldOne | WorldTwo

type Root {
  hello: Hello
}

type WorldOne {
  str: String
}

type WorldTwo {
  str: String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports redefining built-in scalars' do
      schema = <<-SCHEMA
schema {
  query: Root
}

scalar ID

type Root {
  builtInScalar: ID
}
      SCHEMA

      built_schema = assert_schema_and_compare_output(schema)
      id_scalar = built_schema.types["ID"]
      assert_equal true, id_scalar.valid_isolated_input?("123")
    end

    it 'supports custom scalar' do
      schema = <<-SCHEMA
schema {
  query: Root
}

scalar CustomScalar

type Root {
  customScalar: CustomScalar
}
      SCHEMA

      built_schema = assert_schema_and_compare_output(schema)
      custom_scalar = built_schema.types["CustomScalar"]
      assert_equal true, custom_scalar.valid_isolated_input?("anything")
      assert_equal true, custom_scalar.valid_isolated_input?(12345)
    end

    it 'supports input object' do
      schema = <<-SCHEMA
schema {
  query: Root
}

input Input {
  int: Int
  nullDefault: Int = null
}

type Root {
  field(in: Input): String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports simple argument field with default value' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

enum Color {
  BLUE
  RED
}

type Hello {
  hello(color: Color = RED): String
  nullable(color: Color = null): String
  str(int: Int = 2): String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports simple type with mutation' do
      schema = <<-SCHEMA
schema {
  query: HelloScalars
  mutation: Mutation
}

type HelloScalars {
  bool: Boolean
  int: Int
  str: String
}

type Mutation {
  addHelloScalars(bool: Boolean, int: Int, str: String): HelloScalars
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports simple type with mutation and default values' do
      schema = <<-SCHEMA
enum Color {
  BLUE
  RED
}

type Mutation {
  hello(color: Color = RED, int: Int, nullDefault: Int = null, str: String): String
}

type Query {
  str: String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports simple type with subscription' do
      schema = <<-SCHEMA
schema {
  query: HelloScalars
  subscription: Subscription
}

type HelloScalars {
  bool: Boolean
  int: Int
  str: String
}

type Subscription {
  subscribeHelloScalars(bool: Boolean, int: Int, str: String): HelloScalars
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports unreferenced type implementing referenced interface' do
      schema = <<-SCHEMA
type Concrete implements Iface {
  key: String
}

interface Iface {
  key: String
}

type Query {
  iface: Iface
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports unreferenced type implementing referenced union' do
      schema = <<-SCHEMA
type Concrete {
  key: String
}

type Query {
  union: Union
}

union Union = Concrete
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it 'supports @deprecated' do
      schema = <<-SCHEMA
directive @directiveWithDeprecatedArg(deprecatedArg: Boolean @deprecated(reason: "Don't use me!")) on OBJECT

enum MyEnum {
  OLD_VALUE @deprecated
  OTHER_VALUE @deprecated(reason: "Terrible reasons")
  VALUE
}

input MyInput {
  int: Int @deprecated(reason: "This is not the argument you're looking for")
  string: String
}

type Query {
  enum: MyEnum
  field1: String @deprecated
  field2: Int @deprecated(reason: "Because I said so")
  field3(deprecatedArg: MyInput @deprecated(reason: "Use something else")): String
}
      SCHEMA

      assert_schema_and_compare_output(schema)
    end

    it "tracks original AST node" do
      schema_definition = <<-GRAPHQL
schema @custom(thing: true) {
  query: Query
}

enum Enum {
  VALUE
}

type Query {
  field(argument: Enum): Interface
  deprecatedField(argument: Input): Union @deprecated(reason: "Test")
}

interface Interface {
  field(argument: String): String
}

union Union = Query

scalar Scalar

input Input {
  argument: String
}

directive @Directive (
  # Argument
  argument: String
) on SCHEMA

directive @custom(thing: Boolean) on SCHEMA

type Type implements Interface {
  field(argument: Scalar): Type
}
      GRAPHQL

      schema = GraphQL::Schema.from_definition(schema_definition)

      assert_equal [1, 1], schema.ast_node.position
      assert_equal [1, 8], schema.ast_node.directives.first.position
      assert_equal [5, 1], schema.types["Enum"].ast_node.position
      assert_equal [6, 3], schema.types["Enum"].values["VALUE"].ast_node.position
      assert_equal [9, 1], schema.types["Query"].ast_node.position
      assert_equal [10, 3], schema.types["Query"].fields["field"].ast_node.position
      assert_equal [10, 9], schema.types["Query"].fields["field"].arguments["argument"].ast_node.position
      assert_equal [11, 43], schema.types["Query"].fields["deprecatedField"].ast_node.directives[0].position
      assert_equal [11, 55], schema.types["Query"].fields["deprecatedField"].ast_node.directives[0].arguments[0].position
      assert_equal [14, 1], schema.types["Interface"].ast_node.position
      assert_equal [15, 3], schema.types["Interface"].fields["field"].ast_node.position
      assert_equal [15, 9], schema.types["Interface"].fields["field"].arguments["argument"].ast_node.position
      assert_equal [18, 1], schema.types["Union"].ast_node.position
      assert_equal [20, 1], schema.types["Scalar"].ast_node.position
      assert_equal [22, 1], schema.types["Input"].ast_node.position
      assert_equal [23, 3], schema.types["Input"].arguments["argument"].ast_node.position
      assert_equal [26, 1], schema.directives["Directive"].ast_node.position
      assert_equal [28, 3], schema.directives["Directive"].arguments["argument"].ast_node.position
      assert_equal [33, 22], schema.types["Type"].ast_node.interfaces[0].position
    end

    it 'can build a schema from a file path' do
      schema = <<-SCHEMA
schema {
  query: HelloScalars
}

type HelloScalars {
  bool: Boolean
  float: Float
  id: ID
  int: Int
  str: String!
}
      SCHEMA

      Tempfile.create(['test', '.graphql']) do |file|
        file.write(schema)
        file.close

        built_schema = GraphQL::Schema.from_definition(file.path)
        assert_equal schema, GraphQL::Schema::Printer.print_schema(built_schema)
      end
    end
  end

  describe 'Failures' do
    it 'Requires a schema definition or Query type' do
      schema = <<-SCHEMA
type Hello {
  bar: Bar
}
SCHEMA
      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Must provide schema definition with query type or a type named Query.', err.message
    end

    it 'Allows only a single schema definition' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

schema {
  query: Hello
}

type Hello {
  bar: Bar
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Must provide only one schema definition.', err.message
    end

    it 'Requires a query type' do
      schema = <<-SCHEMA
schema {
  mutation: Hello
}

type Hello {
  bar: Bar
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Must provide schema definition with query type or a type named Query.', err.message
    end

    it 'Unknown type referenced' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello {
  bar: Bar
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Type "Bar" not found in document.', err.message
    end

    it 'Unknown type in interface list' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello implements Bar {
  str: String
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Type "Bar" not found in document.', err.message
    end

    it 'Unknown type in union list' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

union TestUnion = Bar

type Hello { testUnion: TestUnion }
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Type "Bar" not found in document.', err.message
    end

    it 'Unknown query type' do
      schema = <<-SCHEMA
schema {
  query: Wat
}

type Hello {
  str: String
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Specified query type "Wat" not found in document.', err.message
    end

    it 'Unknown mutation type' do
      schema = <<-SCHEMA
schema {
  query: Hello
  mutation: Wat
}

type Hello {
  str: String
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Specified mutation type "Wat" not found in document.', err.message
    end

    it 'Unknown subscription type' do
      schema = <<-SCHEMA
schema {
  query: Hello
  mutation: Wat
  subscription: Awesome
}

type Hello {
  str: String
}

type Wat {
  str: String
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Specified subscription type "Awesome" not found in document.', err.message
    end

    it 'Does not consider operation names' do
      schema = <<-SCHEMA
schema {
  query: Foo
}

query Foo { field }
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Specified query type "Foo" not found in document.', err.message
    end

    it 'Does not consider fragment names' do
      schema = <<-SCHEMA
schema {
  query: Foo
}

fragment Foo on Type { field }
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Specified query type "Foo" not found in document.', err.message
    end
  end

  describe "executable schema with resolver maps" do
    class Something
      def capitalize(args)
        args[:word].upcase
      end
    end

    let(:definition) {
      <<-GRAPHQL
        scalar Date
        scalar UndefinedScalar
        type Something { capitalize(word:String!): String }
        type A { a: String }
        type B { b: String }
        union Thing = A | B
        type Query {
          hello: Something
          thing: Thing
          add_week(in: Date!): Date!
          undefined_scalar(str: String, int: Int): UndefinedScalar
        }
      GRAPHQL
    }

    let(:resolvers) {
      {
        Date: {
          coerce_input: ->(val, ctx) {
            Time.at(Float(val))
          },
          coerce_result: ->(val, ctx) {
            val.to_f
          }
        },
        resolve_type: ->(type, obj, ctx) {
          return ctx.schema.types['A']
        },
        Query: {
          add_week: ->(o,a,c) {
            raise "No Time" unless a[:in].is_a? Time
            a[:in]
          },
          hello: ->(o,a,c) {
            Something.new
          },
          thing: ->(o,a,c) {
            OpenStruct.new({a: "a"})
          },
          undefined_scalar: ->(o,a,c) {
            a.values.first
          }
        }
      }
    }

    let(:schema) { GraphQL::Schema.from_definition(definition, default_resolve: resolvers) }

    it "resolves unions"  do
      result = schema.execute("query { thing { ... on A { a } } }")
      assert_equal(result.to_json,'{"data":{"thing":{"a":"a"}}}')
    end

    it "resolves scalars" do
      result = schema.execute("query { add_week(in: 392277600.0) }")
      assert_equal(result.to_json,'{"data":{"add_week":392277600.0}}')
    end

    it "passes args from graphql to the object"  do
      result = schema.execute("query { hello { capitalize(word: \"hello\") }}")
      assert_equal(result.to_json,'{"data":{"hello":{"capitalize":"HELLO"}}}')
    end

    it "handles undefined scalar resolution with identity function" do
      result = schema.execute <<-GRAPHQL
        {
          str: undefined_scalar(str: "abc")
          int: undefined_scalar(int: 123)
        }
      GRAPHQL

      assert_equal({ "str" => "abc", "int" => 123 }, result["data"])
    end

    it "doesn't warn about method conflicts" do
      assert_output "", "" do
        GraphQL::Schema.from_definition "
        type Query {
          int(method: Int): Int
        }
        "
      end
    end
  end

  describe "executable schemas from string" do
    let(:schema_defn) {
      <<-GRAPHQL
        type Todo {text: String, from_context: String}
        type Query { all_todos: [Todo]}
        type Mutation { todo_add(text: String!): Todo}
      GRAPHQL
    }

    Todo = Struct.new(:text, :from_context)

    class RootResolver
      attr_accessor :todos

      def initialize
        @todos = [Todo.new("Pay the bills.")]
      end

      def all_todos
        @todos
      end

      def todo_add(args, ctx) # this is a method and accepting arguments
        todo = Todo.new(args[:text], ctx[:context_value])
        @todos << todo
        todo
      end
    end

    it "calls methods with args if args are defined" do
      schema = GraphQL::Schema.from_definition(schema_defn)
      root_values = RootResolver.new
      schema.execute("mutation { todoAdd: todo_add(text: \"Buy Milk\") { text } }", root_value: root_values, context: {context_value: "bar"})
      result = schema.execute("query { allTodos: all_todos { text, from_context } }", root_value: root_values)
      assert_equal(result.to_json, '{"data":{"allTodos":[{"text":"Pay the bills.","from_context":null},{"text":"Buy Milk","from_context":"bar"}]}}')
    end

    describe "hash of resolvers with defaults" do
      let(:todos) { [Todo.new("Pay the bills.")] }
      let(:schema) { GraphQL::Schema.from_definition(schema_defn, default_resolve: resolve_hash) }
      let(:resolve_hash) {
        h = base_hash
        h["Query"] ||= {}
        h["Query"]["all_todos"] = ->(obj, args, ctx) { obj }
        h["Mutation"] ||= {}
        h["Mutation"]["todo_add"] = ->(obj, args, ctx) {
          todo = Todo.new(args[:text], ctx[:context_value])
          obj << todo
          todo
        }
        h
      }

      let(:base_hash) {
        # Fallback is to resolve by sending the field name
        Hash.new { |h, k| h[k] = Hash.new { |h2, k2| ->(obj, args, ctx) { obj.public_send(k2) } } }
      }

      it "accepts a hash of resolve functions" do
        schema.execute("mutation { todoAdd: todo_add(text: \"Buy Milk\") { text } }", context: {context_value: "bar"}, root_value: todos)
        result = schema.execute("query { allTodos: all_todos { text, from_context } }", root_value: todos)
        assert_equal(result.to_json, '{"data":{"allTodos":[{"text":"Pay the bills.","from_context":null},{"text":"Buy Milk","from_context":"bar"}]}}')
      end
    end

    describe "custom resolve behavior" do
      class AppResolver
        def initialize
          @todos = [Todo.new("Pay the bills.")]
          @resolves = {
            "Query" => {
              "all_todos" => ->(obj, args, ctx) { @todos },
            },
            "Mutation" => {
              "todo_add" => ->(obj, args, ctx) {
                todo = Todo.new(args[:text], ctx[:context_value])
                @todos << todo
                todo
              },
            },
            "Todo" => {
              "text" => ->(obj, args, ctx) { obj.text },
              "from_context" => ->(obj, args, ctx) { obj.from_context },
            }
          }
        end

        def call(type, field, obj, args, ctx)
          @resolves
            .fetch(type.graphql_name)
            .fetch(field.graphql_name)
            .call(obj, args, ctx)
        end
      end

      it "accepts a default_resolve callable" do
        schema = GraphQL::Schema.from_definition(schema_defn, default_resolve: AppResolver.new)
        schema.execute("mutation { todoAdd: todo_add(text: \"Buy Milk\") { text } }", context: {context_value: "bar"})
        result = schema.execute("query { allTodos: all_todos { text, from_context } }")
        assert_equal('{"data":{"allTodos":[{"text":"Pay the bills.","from_context":null},{"text":"Buy Milk","from_context":"bar"}]}}', result.to_json)
      end
    end

    describe "custom parser behavior" do
      module BadParser
        ParseError = Class.new(StandardError)

        def self.parse(string)
          raise ParseError
        end
      end

      it 'accepts a parser callable' do
        assert_raises(BadParser::ParseError) do
          GraphQL::Schema.from_definition(schema_defn, parser: BadParser)
        end
      end
    end

    describe "relay behaviors" do
      let(:schema_defn) { <<-GRAPHQL
interface Node {
  id: ID!
}

type Query {
  node(id: ID!): Node
}

type Thing implements Node {
  id: ID!
  name: String!
  otherThings(after: String, first: Int): ThingConnection!
}

type ThingConnection {
  edges: [ThingEdge!]!
}

type ThingEdge {
  cursor: String!
  node: Thing!
}
      GRAPHQL
      }
      let(:query_string) {'
        {
          node(id: "taco") {
            ... on Thing {
              name
              otherThings {
                edges {
                  node {
                    name
                  }
                cursor
                }
              }
            }
          }
        }
      '}

      it "doesn't try to add them" do
        default_resolve = {
          "Query" => {
            "node" => ->(obj, args, ctx) {
              OpenStruct.new(
                name: "taco-thing",
                otherThings: OpenStruct.new(
                  edges: [
                    OpenStruct.new(cursor: "a", node: OpenStruct.new(name: "other-thing-a")),
                    OpenStruct.new(cursor: "b", node: OpenStruct.new(name: "other-thing-b")),
                  ]
                )
              )
            }
          },
          "resolve_type" => ->(type, obj, ctx) {
            ctx.query.get_type("Thing")
          }
        }
        schema = GraphQL::Schema.from_definition(schema_defn, default_resolve: default_resolve)
        result = schema.execute(query_string)

        expected_data = {
          "node" => {
            "name" => "taco-thing",
            "otherThings" => {
              "edges" => [
                {"node" => {"name" => "other-thing-a"}, "cursor" => "a"},
                {"node" => {"name" => "other-thing-b"}, "cursor" => "b"},
              ]
            }
          }
        }
        assert_equal expected_data, result["data"]
      end

      it "doesn't add arguments that aren't in the IDL" do
        schema = GraphQL::Schema.from_definition(schema_defn)
        assert_equal schema_defn, schema.to_definition
      end
    end
  end

  it "works when a directive argument uses a redefined scalar" do
    schema_str = <<-GRAPHQL
      schema {
        query: QueryRoot
      }

      directive @myDirective(id: ID) on MUTATION | QUERY

      scalar ID

      type QueryRoot {}
    GRAPHQL

    schema = GraphQL::Schema.from_definition(schema_str)
    assert_equal schema.directives["myDirective"].get_argument("id").type, schema.get_type("ID")
  end

  describe "orphan types" do
    it "only puts unreachable types in orphan types" do
      schema = GraphQL::Schema.from_definition <<-GRAPHQL
      type Query {
        node(id: ID!): Node
        t1: ReachableType
      }

      interface Node {
        id: ID!
      }

      type ReachableType implements Node {
        id: ID!
      }

      type ReachableThroughInterfaceType implements Node {
        id: ID!
      }

      type UnreachableType {
        id: ID!
      }
      GRAPHQL

      assert_equal [], schema.orphan_types.map(&:graphql_name)

      expected_definition = <<-GRAPHQL
interface Node {
  id: ID!
}

type Query {
  node(id: ID!): Node
  t1: ReachableType
}

type ReachableThroughInterfaceType implements Node {
  id: ID!
}

type ReachableType implements Node {
  id: ID!
}
      GRAPHQL

      assert_equal expected_definition, schema.to_definition, "UnreachableType is excluded"
    end
  end

  it "works with indirect interface implementation" do
    schema_string = <<~GRAPHQL
      type Query {
        entities: [Entity!]!
        person: Person
      }

      type Person implements NamedEntity {
        id: ID!
        name: String
        nationality: String
      }

      type Product implements NamedEntity {
        id: ID!
        name: String
        amount: Int
      }

      interface NamedEntity implements Entity {
        id: ID!
        name: String
      }

      type Payment implements Entity {
        id: ID!
        amount: Int
      }

      interface Entity {
        id: ID!
      }
    GRAPHQL

    schema = GraphQL::Schema.from_definition(schema_string)

    assert_equal ["amount", "id"], schema.types.fetch("Payment").fields.keys.sort
    assert_equal ["id", "name", "nationality"], schema.types.fetch("Person").fields.keys.sort
  end

  it "supports extending schemas with directives" do
    schema_sdl = <<~EOS
    extend schema
      @link(import: ["@key", "@shareable"], url: "https://specs.apollo.dev/federation/v2.0")

    directive @link(as: String, for: link__Purpose, import: [link__Import], url: String!) repeatable on SCHEMA

    type Query {
      something: Int
    }

    scalar link__Import

    enum link__Purpose {
      EXECUTION
      SECURITY
    }
    EOS

    schema = GraphQL::Schema.from_definition(schema_sdl)
    assert_equal ["link"], schema.schema_directives.map(&:graphql_name)
    assert_equal({ url: "https://specs.apollo.dev/federation/v2.0", import: ["@key", "@shareable"] },
      schema.schema_directives.first.arguments.to_h)

    assert_equal schema_sdl, schema.to_definition
  end


  it "supports extending schemas with directives" do
    schema_sdl = <<~EOS
      extend schema
        @link(url: "https://specs.apollo.dev/federation/v2.0",
              import: ["@key", "@shareable"])

      type Query {
        something: Int
      }
    EOS

    class LinkSchema < GraphQL::Schema
      class Import < GraphQL::Schema::Scalar
      end

      class Purpose < GraphQL::Schema::Scalar
      end

      class Link < GraphQL::Schema::Directive
        argument :url, String
        argument :as, String, required: false
        argument :import, Import, required: false
        argument :for, Purpose, required: false

        repeatable(true)
        locations SCHEMA
      end

      directive(Link)
    end

    assert_equal LinkSchema::Link, LinkSchema.directives["link"]
    schema = LinkSchema.from_definition(schema_sdl)
    assert_equal ["link"], schema.schema_directives.map(&:graphql_name)
    assert_equal({ url: "https://specs.apollo.dev/federation/v2.0", import: ["@key", "@shareable"] },
      schema.schema_directives.first.arguments.to_h)

    expected_schema = <<~GRAPHQL
      extend schema
        @link(url: "https://specs.apollo.dev/federation/v2.0", import: ["@key", "@shareable"])

      directive @link(as: String, for: Purpose, import: Import, url: String!) repeatable on SCHEMA

      scalar Import

      scalar Purpose

      type Query {
        something: Int
      }
    GRAPHQL
    assert_equal expected_schema, schema.to_definition
  end

  describe "JSON type" do
    class JsonTypeApplication
      SCHEMA_STRING = <<~EOS
        scalar JsonValue

        type Query {
          echoJsonValue(arg: JsonValue): JsonValue
        }
      EOS

      def initialize
        @schema = GraphQL::Schema.from_definition(SCHEMA_STRING, default_resolve: self)
      end

      def execute_query(query_string, **vars)
        @schema.execute(query_string, variables: vars)
      end

      def call(parent_type, field, object, args, context)
        args.fetch(:arg)
      end

      def coerce_input(type, value, ctx)
        nils = ctx[:nils] ||= []
        if value.is_a?(Array)
          nils << value[2]
        else
          nils << value["abc"]
        end
        ::JSON.generate(value)
      end

      def coerce_result(type, value, ctx)
        ::JSON.parse(value)
      end
    end

    it "Sends normal ruby values to schema coercion" do
      app = JsonTypeApplication.new

      res_1 = app.execute_query(<<~EOS, arg: [3, "abc", nil, 7])
        query WithArg($arg: JsonValue) {
          echoJsonValue(arg: $arg)
        }
      EOS

      assert_equal([3, "abc", nil, 7], res_1["data"]["echoJsonValue"])
      assert_equal [nil, nil], res_1.context[:nils]

      res_2 = app.execute_query(<<~EOS)
        query {
          echoJsonValue(arg: [3, "abc", null, 7])
        }
      EOS
      assert_equal([3, "abc", nil, 7], res_2["data"]["echoJsonValue"])
      assert_equal [nil, nil], res_2.context[:nils]

      res_3 = app.execute_query(<<~EOS, arg: { "abc" => nil, "def" => 7 })
      query WithArg($arg: JsonValue) {
        echoJsonValue(arg: $arg)
      }
      EOS

      assert_equal({ "abc" => nil, "def" => 7 }, res_3["data"]["echoJsonValue"])
      assert_equal [nil, nil], res_3.context[:nils]

      res_4 = app.execute_query(<<~EOS)
      query {
        echoJsonValue(arg: { abc: null, def: 7, ghi: { jkl: null } })
      }
      EOS

      assert_equal({ "abc" => nil, "def" => 7, "ghi"=>{"jkl"=>nil} }, res_4["data"]["echoJsonValue"])
      assert_equal [nil, nil], res_4.context[:nils]
    end
  end

  it "reprints schema with extend when root types match" do
    schema_str = <<~EOS
      extend schema
        @customDirective

      directive @customDirective repeatable on SCHEMA

      type Query {
        foo: Int
      }
    EOS

    schema = GraphQL::Schema.from_definition(schema_str)
    assert_equal schema_str, schema.to_definition
  end

  if USING_C_PARSER
    it "makes frozen identifiers with CParser" do
      schema_class = GraphQL::Schema.from_definition("type Query { f: Boolean }")
      assert_equal "Query", schema_class.query.ast_node.name
      assert schema_class.query.ast_node.name.frozen?
    end
  end
end
