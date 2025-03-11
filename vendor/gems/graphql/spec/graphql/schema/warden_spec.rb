# frozen_string_literal: true
require "spec_helper"

module MaskHelpers
  def self.build_mask(only:, except:)
    ->(member, context) do
      visible = true
      if visible
        only.each do |filter|
          passes_filter = filter.call(member, context)
          if !passes_filter
            visible = false
            break
          end
        end
      end

      if visible
        except.each do |filter|
          passes_filter = !filter.call(member, context)
          if !passes_filter
            visible = false
            break
          end
        end
      end

      !visible
    end
  end

  # Returns true if `member.metadata` includes any of `flags`
  def self.has_flag?(member, *flags)
    if member.respond_to?(:metadata) && (m = member.metadata)
      if m.is_a?(Hash)
        flags.any? { |f| m[f] }
      else
        m.any? { |item| flags.include?(item) }
      end
    end
  end

  module HasMetadata
    def metadata(key = nil, value = nil)
      if key
        @metadata ||= {}
        @metadata[key] = value
      end
      @metadata
    end
  end


  class BaseArgument < GraphQL::Schema::Argument
    include HasMetadata
  end

  class BaseField < GraphQL::Schema::Field
    include HasMetadata
    argument_class BaseArgument
  end

  class BaseObject < GraphQL::Schema::Object
    extend HasMetadata
    field_class BaseField
  end

  class BaseEnumValue < GraphQL::Schema::EnumValue
    include HasMetadata
  end

  class BaseEnum < GraphQL::Schema::Enum
    extend HasMetadata
    enum_value_class BaseEnumValue
  end

  class BaseInputObject < GraphQL::Schema::InputObject
    extend HasMetadata
    argument_class BaseArgument
  end

  class BaseUnion < GraphQL::Schema::Union
    extend HasMetadata
  end

  module BaseInterface
    include GraphQL::Schema::Interface
    module DefinitionMethods
      include HasMetadata
    end
    field_class BaseField
  end

  class MannerType < BaseEnum
    description "Manner of articulation for this sound"
    metadata :hidden_input_type, true
    value "STOP"
    value "AFFRICATE"
    value "FRICATIVE"
    value "APPROXIMANT"
    value "VOWEL"
    value "TRILL" do
      metadata :hidden_enum_value, true
    end
  end

  class LanguageType < BaseObject
    field :name, String, null: false
    field :families, [String], null: false
    field :phonemes, "[MaskHelpers::PhonemeType]", null: false
    field :graphemes, "[MaskHelpers::GraphemeType]", null: false
  end

  module LanguageMemberType
    include BaseInterface
    metadata :hidden_abstract_type, true
    description "Something that belongs to one or more languages"
    field :languages, [LanguageType], null: false
  end

  class GraphemeType < BaseObject
    description "A building block of spelling in a given language"
    implements LanguageMemberType

    field :name, String, null: false
    field :glyph, String, null: false
    field :languages, [LanguageType], null: false
  end

  class PhonemeType < BaseObject
    description "A building block of sound in a given language"
    metadata :hidden_type, true
    implements LanguageMemberType

    field :name, String, null: false
    field :symbol, String, null: false
    field :languages, [LanguageType], null: false
    field :manner, MannerType, null: false
  end

  class EmicUnitType < BaseUnion
    description "A building block of a word in a given language"
    possible_types GraphemeType, PhonemeType
  end

  class WithinInputType < BaseInputObject
    metadata :hidden_input_object_type, true
    argument :latitude, Float
    argument :longitude, Float
    argument :miles, Float do
      metadata :hidden_input_field, true
    end
  end

  class CheremeInput < BaseInputObject
    argument :name, String, required: false
  end

  module PublicInterfaceType
    include BaseInterface
    field :other, String
  end

  class PublicType < BaseObject
    implements PublicInterfaceType
    field :test, String
  end

  class CheremeDirective < GraphQL::Schema::Directive
    locations(GraphQL::Schema::Directive::OBJECT)
  end

  class CheremeWithInterface < BaseObject
    implements PublicInterfaceType

    field :name, String, null: false
  end

  class Chereme < BaseObject
    description "A basic unit of signed communication"
    implements LanguageMemberType
    directive CheremeDirective

    field :name, String, null: false

    field :chereme_with_interface, CheremeWithInterface
  end

  class Character < BaseObject
    implements LanguageMemberType
    field :code, Int, null: false
  end

  class QueryType < BaseObject
    field :languages, [LanguageType], null: false do
      argument :within, WithinInputType, required: false, description: "Find languages nearby a point" do
        metadata :hidden_argument_with_input_object, true
      end
    end

    field :language, LanguageType do
      metadata :hidden_field, true
      argument :name, String do
        metadata :hidden_argument, true
      end
    end

    field :chereme, Chereme, null: false do
      metadata :hidden_field, true
    end

    field :chereme_with_interface, CheremeWithInterface, null: false do
      metadata :hidden_field, true
    end

    field :phonemes, [PhonemeType], null: false do
      argument :manners, [MannerType], required: false, description: "Filter phonemes by manner of articulation"
    end

    field :phoneme, PhonemeType do
      description "Lookup a phoneme by symbol"
      argument :symbol, String
    end

    field :unit, EmicUnitType do
      description "Find an emic unit by its name"
      argument :name, String
    end

    field :manners, [MannerType], null: false

    field :public_type, PublicType, null: false

    # Warden would exclude this when it was only referenced as a possible_type of LanguageMemberType.
    # But Profile always included it. This makes them behave the same
    field :example_character, Character do
      metadata :hidden_abstract_type, true
    end
  end

  class MutationType < BaseObject
    field :add_phoneme, PhonemeType do
      argument :symbol, String, required: false
    end

    field :add_chereme, String do
      argument :chereme, CheremeInput, required: false do
        metadata :hidden_argument, true
      end
    end
  end

  class Schema < GraphQL::Schema
    use GraphQL::Schema::Warden if ADD_WARDEN
    query QueryType
    mutation MutationType
    subscription MutationType
    orphan_types [Character]
    def self.resolve_type(type, obj, ctx)
      PhonemeType
    end

    def self.visible?(member, context)
      result = super(member, context)
      if result && context[:only] && !Array(context[:only]).all? { |func| func.call(member, context) }
        return false
      end
      if result && context[:except] && Array(context[:except]).any? { |func| func.call(member, context) }
        return false
      end
      result
    end
  end

  module Data
    UVULAR_TRILL = OpenStruct.new({name: "Uvular Trill", symbol: "ʀ", manner: "TRILL"})
    def self.unit(name:)
      UVULAR_TRILL
    end
  end

  def self.query_with_mask(str, mask, variables: {})
    run_query(str, context: { except: mask }, root_value: Data, variables: variables)
  end

  def self.run_query(str, **kwargs)
    filters = {}
    if (only = kwargs.delete(:only))
      filters[:only] = only
    end
    if (except = kwargs.delete(:except))
      filters[:except] = except
    end
    if !filters.empty?
      context = kwargs[:context] ||= {}
      context[:filters] = filters
    end
    Schema.execute(str, **kwargs.merge(root_value: Data))
  end
end


describe GraphQL::Schema::Warden do
  def type_names(introspection_result)
    introspection_result["data"]["__schema"]["types"].map { |t| t["name"] }
  end

  def possible_type_names(type_by_name_result)
    type_by_name_result["possibleTypes"].map { |t| t["name"] }
  end

  def field_type_names(schema_result)
    schema_result["types"]
      .map {|t| t["fields"] }
      .flatten
      .map { |f| f ? get_recursive_field_type_names(f["type"]) : [] }
      .flatten
      .uniq
  end

  def get_recursive_field_type_names(field_result)
    case field_result
    when Hash
      [field_result["name"]].concat(get_recursive_field_type_names(field_result["ofType"]))
    when nil
      []
    else
      raise "Unexpected field result: #{field_result}"
    end
  end

  def error_messages(query_result)
    query_result["errors"].map { |err| err["message"] }
  end

  describe "hiding root types" do
    let(:mask) { ->(m, ctx) { m == MaskHelpers::MutationType } }

    it "acts as if the root doesn't exist" do
      query_string = %|mutation { addPhoneme(symbol: "ϕ") { name } }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      assert MaskHelpers::Schema.mutation # it _does_ exist
      assert_equal 1, res["errors"].length
      assert_equal "Schema is not configured for mutations", res["errors"][0]["message"]

      query_string = %|subscription { addPhoneme(symbol: "ϕ") { name } }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      assert MaskHelpers::Schema.subscription # it _does_ exist
      assert_equal 1, res["errors"].length
      assert_equal "Schema is not configured for subscriptions", res["errors"][0]["message"]
    end

    it "doesn't show in introspection" do
      query_string = <<-GRAPHQL
      {
        __schema {
          queryType {
            name
          }
          mutationType {
            name
          }
          subscriptionType {
            name
          }
          types {
            name
          }
        }
      }
      GRAPHQL
      res = MaskHelpers.query_with_mask(query_string, mask)
      assert_equal "Query", res["data"]["__schema"]["queryType"]["name"]
      assert_nil res["data"]["__schema"]["mutationType"]
      assert_nil res["data"]["__schema"]["subscriptionType"]
      type_names = res["data"]["__schema"]["types"].map { |t| t["name"] }
      refute type_names.include?("Mutation")
      refute type_names.include?("Subscription")
    end
  end

  describe "hiding fields" do
    let(:mask) {
      ->(member, ctx) { MaskHelpers.has_flag?(member, :hidden_field, :hidden_type) }
    }

    it "hides types if no other fields are using it" do
      query_string = %|
        {
          Chereme: __type(name: "Chereme") { fields { name } }
        }
      |

      res = MaskHelpers.query_with_mask(query_string, mask)
      assert_nil res["data"]["Chereme"]
    end

    it "hides types if no other fields are using it (with interface)" do
      query_string = %|
         {
           CheremeWithInterface: __type(name: "CheremeWithInterface") { fields { name } }
         }
       |

      res = MaskHelpers.query_with_mask(query_string, mask)
      assert_nil res["data"]["CheremeWithInterface"]
    end

    it "hides directives if no other fields are using it" do
      query_string = %|
        {
          __schema { directives { name } }
        }
      |

      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_directives = ["deprecated", "include", "oneOf", "skip", "specifiedBy"]
      if !GraphQL::Schema.use_visibility_profile?
        # Not supported by Warden
        expected_directives.unshift("cheremeDirective")
      end

      assert_equal(expected_directives, res["data"]["__schema"]["directives"].map { |d| d["name"] })
    end

    it "causes validation errors" do
      query_string = %|{ phoneme(symbol: "ϕ") { name } }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      err_msg = res["errors"][0]["message"]
      assert_equal "Field 'phoneme' doesn't exist on type 'Query'", err_msg

      query_string = %|{ language(name: "Uyghur") { name } }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      err_msg = res["errors"][0]["message"]
      assert_equal "Field 'language' doesn't exist on type 'Query' (Did you mean `languages`?)", err_msg
    end

    it "doesn't show in introspection" do
      query_string = %|
      {
        LanguageType: __type(name: "Language") { fields { name } }
        __schema {
          types {
            name
            fields {
              name
            }
          }
        }
      }|

      res = MaskHelpers.query_with_mask(query_string, mask)

      # Fields dont appear when finding the type by name
      language_fields = res["data"]["LanguageType"]["fields"].map {|f| f["name"] }
      assert_equal ["families", "graphemes", "name"], language_fields

      # Fields don't appear in the __schema result
      phoneme_fields = res["data"]["__schema"]["types"]
        .map { |t| (t["fields"] || []).select { |f| f["name"].start_with?("phoneme") } }
        .flatten

      assert_equal [], phoneme_fields
    end
  end

  describe "hiding types" do
    it "hides types from introspection" do
      query_string = %|
      {
        Phoneme: __type(name: "Phoneme") { name }
        EmicUnit: __type(name: "EmicUnit") {
          possibleTypes { name }
        }
        LanguageMember: __type(name: "LanguageMember") {
          possibleTypes { name }
        }
        __schema {
          types {
            name
            fields {
              type {
                name
                ofType {
                  name
                  ofType {
                    name
                  }
                }
              }
            }
          }
        }
      }
      |

      res = MaskHelpers.run_query(query_string, context: {
        skip_visibility_migration_error: true,
        except: ->(member, ctx) { MaskHelpers.has_flag?(member, :hidden_type)
      } })
      # It's not visible by name
      assert_nil res["data"]["Phoneme"]

      # It's not visible in `__schema`
      all_type_names = type_names(res)
      assert_equal false, all_type_names.include?("Phoneme")

      # No fields return it
      refute_includes field_type_names(res["data"]["__schema"]), "Phoneme"

      # It's not visible as a union or interface member
      assert_equal false, possible_type_names(res["data"]["EmicUnit"]).include?("Phoneme")
      assert_equal false, possible_type_names(res["data"]["LanguageMember"]).include?("Phoneme")
      assert_equal ["Character", "Chereme", "Grapheme"], possible_type_names(res["data"]["LanguageMember"]).sort
    end

    it "hides interfaces if all possible types are hidden" do
      sdl = %|
        type Query {
          a: String
          repository: Repository
        }

        type Repository implements Node {
          id: ID!
        }

        interface Node {
          id: ID!
        }
      |

      schema = GraphQL::Schema.from_definition(sdl)
      schema.use(GraphQL::Schema::Warden)
      schema.define_singleton_method(:visible?) do |member, ctx|
        super(member, ctx) && (ctx[:hiding] ? member.graphql_name != "Repository" : true)
      end

      query_string = %|
        {
          Node: __type(name: "Node") { name }
        }
      |
      res = schema.execute(query_string)
      assert res["data"]["Node"]

      res = schema.execute(query_string, context: { hiding: true })
      assert_nil res["data"]["Node"]
    end

    it "hides unions if all possible types are hidden or its references are hidden" do
      class PossibleTypesSchema < GraphQL::Schema
        use GraphQL::Schema::Warden if ADD_WARDEN
        class A < GraphQL::Schema::Object
          field :id, ID, null: false
        end

        class B < A; end
        class C < A; end

        class BagOfThings < GraphQL::Schema::Union
          possible_types A, B, C

          if GraphQL::Schema.use_visibility_profile?
            def self.visible?(ctx)
              (
                possible_types.any? { |pt| ctx.schema.visible?(pt, ctx) } ||
                ctx.schema.extra_types.include?(self)
              ) && super
            end
          end
        end

        class Query < GraphQL::Schema::Object
          field :bag, BagOfThings, null: false
        end

        query(Query)

        def self.visible?(member, context)
          res = super(member, context)
          if res && context[:except]
            !context[:except].call(member, context)
          else
            res
          end
        end
      end

      schema = PossibleTypesSchema

      query_string = %|
        {
          BagOfThings: __type(name: "BagOfThings") { name }
          Query: __type(name: "Query") { fields { name } }
        }
      |

      res = schema.execute(query_string)
      assert res["data"]["BagOfThings"]
      assert_equal ["bag"], res["data"]["Query"]["fields"].map { |f| f["name"] }

      # Hide the union when all its possible types are gone. This will cause the field to be hidden too.
      res = schema.execute(query_string, context: { except: ->(m, _) { ["A", "B", "C"].include?(m.graphql_name) } })
      assert_nil res["data"]["BagOfThings"]
      assert_equal [], res["data"]["Query"]["fields"]

      res = schema.execute(query_string, context: { except: ->(m, _) { m.graphql_name == "bag" } })
      assert_nil res["data"]["BagOfThings"]
      assert_equal [], res["data"]["Query"]["fields"]

      # Unreferenced but still visible because extra type
      schema.extra_types([schema.find("BagOfThings")])
      res = schema.execute(query_string, context: { except: ->(m, _) { m.graphql_name == "bag" } })
      assert res["data"]["BagOfThings"]
    end

    it "hides interfaces if all possible types are hidden or its references are hidden" do
      sdl = "
        type Query {
          node: Node
          a: A
        }

        type A implements Node {
          id: ID!
        }

        type B implements Node {
          id: ID!
        }

        type C implements Node {
          id: ID!
        }

        interface Node {
          id: ID!
        }
      "

      schema = GraphQL::Schema.from_definition(sdl)
      schema.use(GraphQL::Schema::Warden) if ADD_WARDEN
      schema.define_singleton_method(:visible?) do |member, context|
        res = super(member, context)
        if res && context[:except]
          !context[:except].call(member, context)
        else
          res
        end
      end

      query_string = %|
        {
          Node: __type(name: "Node") { name }
          Query: __type(name: "Query") { fields { name } }
        }
      |

      res = schema.execute(query_string)
      assert res["data"]["Node"]
      assert_equal ["a", "node"], res["data"]["Query"]["fields"].map { |f| f["name"] }

      res = schema.execute(query_string, context: { skip_visibility_migration_error: true, except: ->(m, _) { ["A", "B", "C"].include?(m.graphql_name) } })

      if GraphQL::Schema.use_visibility_profile?
        # Node is still visible even though it has no possible types
        assert res["data"]["Node"]
        assert_equal [{ "name" => "node" }], res["data"]["Query"]["fields"]
      else
        # When the possible types are all hidden, hide the interface and fields pointing to it
        assert_nil res["data"]["Node"]
        assert_equal [], res["data"]["Query"]["fields"]
      end

      # Even when it's not the return value of a field,
      # still show the interface since it allows code reuse
      res = schema.execute(query_string, context: { except: ->(m, _) { m.graphql_name == "node" } })
      assert_equal "Node", res["data"]["Node"]["name"]
      assert_equal [{"name" => "a"}], res["data"]["Query"]["fields"]
    end

    it "can't be a fragment condition" do
      query_string = %|
      {
        unit(name: "bilabial trill") {
          ... on Phoneme { name }
          ... f1
        }
      }

      fragment f1 on Phoneme {
        name
      }
      |

      res = MaskHelpers.run_query(query_string, context: { except: ->(member, ctx) { MaskHelpers.has_flag?(member, :hidden_type) } })

      expected_errors = [
        "No such type Phoneme, so it can't be a fragment condition",
        "No such type Phoneme, so it can't be a fragment condition",
      ]
      assert_equal expected_errors, error_messages(res)
    end

    it "can't be a resolve_type result" do
      query_string = %|
      {
        unit(name: "Uvular Trill") { __typename }
      }
      |

      assert_raises(MaskHelpers::EmicUnitType::UnresolvedTypeError) {
        MaskHelpers.run_query(query_string, context: { except: ->(member, ctx) { MaskHelpers.has_flag?(member, :hidden_type) } })
      }
    end

    describe "hiding an abstract type" do
      let(:mask) {
        ->(member, ctx) { MaskHelpers.has_flag?(member, :hidden_abstract_type) }
      }

      it "isn't present in a type's interfaces" do
        query_string = %|
        {
          __type(name: "Phoneme") {
            interfaces { name }
          }
        }
        |

        res = MaskHelpers.query_with_mask(query_string, mask)
        interfaces_names = res["data"]["__type"]["interfaces"].map { |i| i["name"] }
        refute_includes interfaces_names, "LanguageMember"
      end

      it "hides implementations if they are not referenced anywhere else" do
        query_string = %|
        {
          __type(name: "Character") {
            fields { name }
          }
        }
        |

        res = MaskHelpers.query_with_mask(query_string, mask)
        type = res["data"]["__type"]
        assert_nil type
      end
    end
  end

  describe "hiding arguments" do
    let(:mask) {
      ->(member, ctx) {
        MaskHelpers.has_flag?(member, :hidden_argument, :hidden_input_type)
      }
    }

    it "hides types if no other fields or arguments are using it" do
      query_string = %|
        {
          CheremeInput: __type(name: "CheremeInput") { fields { name } }
        }
      |

      res = MaskHelpers.query_with_mask(query_string, mask)
      assert_nil res["data"]["CheremeInput"]
    end

    it "isn't present in introspection" do
      query_string = %|
      {
        Query: __type(name: "Query") { fields { name, args { name } } }
      }
      |
      res = MaskHelpers.query_with_mask(query_string, mask)

      query_field_args = res["data"]["Query"]["fields"].each_with_object({}) { |f, memo| memo[f["name"]] = f["args"].map { |a| a["name"] } }
      # hidden argument:
      refute_includes query_field_args["language"], "name"
      # hidden input type:
      refute_includes query_field_args["phoneme"], "manner"
    end

    it "isn't valid in a query" do
      query_string = %|
      {
        language(name: "Catalan") { name }
        phonemes(manners: STOP) { symbol }
      }
      |
      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_errors = [
        "Field 'language' doesn't accept argument 'name'",
        "Field 'phonemes' doesn't accept argument 'manners'",
      ]
      assert_equal expected_errors, error_messages(res)
    end
  end

  describe "hiding input type arguments" do
    let(:mask) {
      ->(member, ctx) { MaskHelpers.has_flag?(member, :hidden_input_field) }
    }

    it "isn't present in introspection" do
      query_string = %|
      {
        WithinInput: __type(name: "WithinInput") { inputFields { name } }
      }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      input_field_names = res["data"]["WithinInput"]["inputFields"].map { |f| f["name"] }
      refute_includes input_field_names, "miles"
    end

    it "isn't a valid default value" do
      query_string = %|
      query findLanguages($nearby: WithinInput = {latitude: 1.0, longitude: 2.2, miles: 3.3}) {
        languages(within: $nearby) { name }
      }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_errors = ["Default value for $nearby doesn't match type WithinInput"]
      assert_equal expected_errors, error_messages(res)
    end

    it "isn't a valid literal input" do
      query_string = %|
      {
        languages(within: {latitude: 1.0, longitude: 2.2, miles: 3.3}) { name }
      }|
      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_errors =
        [
          "InputObject 'WithinInput' doesn't accept argument 'miles'"
        ]
      assert_equal expected_errors, error_messages(res)
    end

    it "isn't a valid variable input" do
      query_string = %|
      query findLanguages($nearby: WithinInput!) {
        languages(within: $nearby) { name }
      }|
      res = MaskHelpers.query_with_mask(query_string, mask, variables: { "latitude" => 1.0, "longitude" => 2.2, "miles" => 3.3})
      expected_errors = ["Variable $nearby of type WithinInput! was provided invalid value"]
      assert_equal expected_errors, error_messages(res)
    end
  end

  describe "hiding input types" do
    let(:mask) {
      ->(member, ctx) { MaskHelpers.has_flag?(member, :hidden_input_object_type) }
    }

    it "isn't present in introspection" do
      query_string = %|
      {
        WithinInput: __type(name: "WithinInput") { name }
        Query: __type(name: "Query") { fields { name, args { name } } }
        __schema {
          types { name }
        }
      }
      |

      res = MaskHelpers.query_with_mask(query_string, mask)

      assert_nil res["data"]["WithinInput"], "The type isn't accessible by name"

      languages_arg_names = res["data"]["Query"]["fields"].find { |f| f["name"] == "languages" }["args"].map { |a| a["name"] }
      refute_includes languages_arg_names, "within", "Arguments that point to it are gone"

      type_names = res["data"]["__schema"]["types"].map { |t| t["name"] }
      refute_includes type_names, "WithinInput", "It isn't in the schema's types"
    end

    it "isn't a valid input" do
      query_string = %|
      query findLanguages($nearby: WithinInput!) {
        languages(within: $nearby) { name }
      }
      |

      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_errors = [
        "WithinInput isn't a defined input type (on $nearby)",
        "Field 'languages' doesn't accept argument 'within'",
        "Variable $nearby is declared by findLanguages but not used",
      ]

      assert_equal expected_errors, error_messages(res)
    end
  end

  describe "hiding enum values" do
    let(:mask) {
      ->(member, ctx) { MaskHelpers.has_flag?(member, :hidden_enum_value) }
    }

    it "isn't present in introspection" do
      query_string = %|
      {
        Manner: __type(name: "Manner") { enumValues { name } }
        __schema {
          types {
            enumValues { name }
          }
        }
      }
      |

      res = MaskHelpers.query_with_mask(query_string, mask)

      manner_values = res["data"]["Manner"]["enumValues"]
        .map { |v| v["name"] }

      schema_values = res["data"]["__schema"]["types"]
        .map { |t| t["enumValues"] || [] }
        .flatten
        .map { |v| v["name"] }

      refute_includes manner_values, "TRILL", "It's not present on __type"
      refute_includes schema_values, "TRILL", "It's not present in __schema"
    end

    it "isn't a valid literal input" do
      query_string = %|
      { phonemes(manners: [STOP, TRILL]) { symbol } }
      |
      res = MaskHelpers.query_with_mask(query_string, mask)
      # It's not a good error message ... but it's something!
      expected_errors = [
        "Argument 'manners' on Field 'phonemes' has an invalid value ([STOP, TRILL]). Expected type '[Manner!]'.",
      ]
      assert_equal expected_errors, error_messages(res)
    end

    it "isn't a valid default value" do
      query_string = %|
      query getPhonemes($manners: [Manner!] = [STOP, TRILL]){ phonemes(manners: $manners) { symbol } }
      |
      res = MaskHelpers.query_with_mask(query_string, mask)
      expected_errors = ["Expected \"TRILL\" to be one of: STOP, AFFRICATE, FRICATIVE, APPROXIMANT, VOWEL"]
      assert_equal expected_errors, error_messages(res)
    end

    it "isn't a valid variable input" do
      query_string = %|
      query getPhonemes($manners: [Manner!]!) {
        phonemes(manners: $manners) { symbol }
      }
      |
      res = MaskHelpers.query_with_mask(query_string, mask, variables: { "manners" => ["STOP", "TRILL"] })
      # It's not a good error message ... but it's something!
      expected_errors = [
        "Variable $manners of type [Manner!]! was provided invalid value for 1 (Expected \"TRILL\" to be one of: STOP, AFFRICATE, FRICATIVE, APPROXIMANT, VOWEL)",
      ]
      assert_equal expected_errors, error_messages(res)
    end

    it "raises a runtime error" do
      query_string = %|
      {
        unit(name: "Uvular Trill") { ... on Phoneme { manner } }
      }
      |
      expected_class = MaskHelpers::MannerType::UnresolvedValueError
      assert_raises(expected_class) {
        MaskHelpers.query_with_mask(query_string, mask)
      }
    end
  end

  describe "multiple filters" do
    let(:visible_enum_value) { ->(member, ctx) { !MaskHelpers.has_flag?(member, :hidden_enum_value) } }
    let(:visible_abstract_type) { ->(member, ctx) { !MaskHelpers.has_flag?(member, :hidden_abstract_type) } }
    let(:hidden_input_object) { ->(member, ctx) { MaskHelpers.has_flag?(member, :hidden_input_object_type) } }
    let(:hidden_type) { ->(member, ctx) { MaskHelpers.has_flag?(member, :hidden_type) } }

    let(:query_str) { <<-GRAPHQL
      {
        enum: __type(name: "Manner") { enumValues { name } }
        input: __type(name: "WithinInput") { name }
        abstractType: __type(name: "Grapheme") { interfaces { name } }
        type: __type(name: "Phoneme") { name }
      }
    GRAPHQL
    }

    describe "multiple filters for execution" do
      it "applies all of them" do
        res = MaskHelpers.run_query(
          query_str,
          context: {
            except: MaskHelpers.build_mask(
              only: [visible_enum_value, visible_abstract_type],
              except: [hidden_input_object, hidden_type],
            )
          },
        )

        assert_nil res["data"]["input"]
        enum_values = res["data"]["enum"]["enumValues"].map { |v| v["name"] }
        assert_equal 5, enum_values.length
        refute_includes enum_values, "TRILL"
        # These are also filtered out:
        assert_equal 0, res["data"]["abstractType"]["interfaces"].length
        assert_nil res["data"]["type"]
      end
    end

    describe "adding filters in instrumentation" do
      it "applies only/except filters" do
        except = MaskHelpers.build_mask(
          only: [visible_enum_value],
          except: [hidden_input_object],
        )
        res = MaskHelpers.run_query(query_str, context: { except: except })
        assert_nil res["data"]["input"]
        enum_values = res["data"]["enum"]["enumValues"].map { |v| v["name"] }
        assert_equal 5, enum_values.length
        refute_includes enum_values, "TRILL"
        # These are unaffected:
        assert_includes res["data"]["abstractType"]["interfaces"].map { |i| i["name"] }, "LanguageMember"
        assert_equal "Phoneme", res["data"]["type"]["name"]
      end

      it "applies multiple filters" do
        context = {
          only: [visible_enum_value, visible_abstract_type],
          except: [hidden_input_object, hidden_type],
        }
        res = MaskHelpers.run_query(query_str, context: context)
        assert_nil res["data"]["input"]
        enum_values = res["data"]["enum"]["enumValues"].map { |v| v["name"] }
        assert_equal 5, enum_values.length
        refute_includes enum_values, "TRILL"
        # These are also filtered out:
        assert_equal 0, res["data"]["abstractType"]["interfaces"].length
        assert_nil res["data"]["type"]
      end
    end
  end

  describe "NullWarden" do
    it "implements all Warden methods" do
      warden_methods = GraphQL::Schema::Warden.instance_methods - Object.methods
      warden_methods.each do |method_name|
        warden_params =  GraphQL::Schema::Warden.instance_method(method_name).parameters
        assert GraphQL::Schema::Warden::NullWarden.method_defined?(method_name), "Null warden also responds to #{method_name} (#{warden_params})"
        assert_equal warden_params, GraphQL::Schema::Warden::NullWarden.instance_method(method_name).parameters,"#{method_name} has the same parameters"
      end
    end
  end

  describe "PassThruWarden is used when no warden is used" do
    it "uses PassThruWarden when a hash is used for context" do
      assert_equal GraphQL::Schema::Warden::PassThruWarden, GraphQL::Schema::Warden.from_context({})
    end

    it "uses PassThruWarden when a warden on the context nor query" do
      context = GraphQL::Query::Context.new(query: OpenStruct.new(schema: GraphQL::Schema.new), values: {})
      assert_equal GraphQL::Schema::Warden::PassThruWarden, GraphQL::Schema::Warden.from_context(context)
    end
  end

  it "doesn't hide subclasses of invisible objects" do
    identifiable = Module.new do
      include GraphQL::Schema::Interface
      graphql_name "Identifiable"
      field :id, "ID", null: false
    end

    hidden_account = Class.new(GraphQL::Schema::Object) do
      graphql_name "Account"
      implements identifiable
      def self.visible?(_ctx); false; end
    end

    visible_account = Class.new(hidden_account) do
      graphql_name "NewAccount"
      has_no_fields(true)
      def self.visible?(_ctx); true; end
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      field :account, visible_account

      def account
        { id: "1" }
      end
    end

    schema = Class.new(GraphQL::Schema) do
      query(query_type)
      use GraphQL::Schema::Warden if ADD_WARDEN
    end

    query_str = <<-GRAPHQL
      query {
        account {
          id
        }
      }
    GRAPHQL

    result = schema.execute(query_str, context: { skip_visibility_migration_error: true })

    if GraphQL::Schema.use_visibility_profile?
      assert_equal "1", result["data"]["account"]["id"]
    else
      assert_equal ["Field 'id' doesn't exist on type 'NewAccount'"], result["errors"].map { |e| e["message"] }
    end
  end
end
