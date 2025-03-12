# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FieldsWillMerge do
  include StaticValidationHelpers

  let(:schema) {
    GraphQL::Schema.from_definition(%|
      type Query {
        dog: Dog
        cat: Cat
        pet: Pet
        toy: Toy
        animal: Animal
      }

      union Animal = Dog \| Cat

      type Mutation {
        registerPet(params: PetParams): Pet
      }

      enum PetCommand {
        SIT
        HEEL
        JUMP
        DOWN
      }

      enum ToySize {
        SMALL
        LARGE
      }

      enum PetSpecies {
        DOG
        CAT
      }

      input PetParams {
        name: String!
        species: PetSpecies!
      }

      interface Mammal {
        name(surname: Boolean = false): String!
        nickname: String
      }

      interface Pet {
        name(surname: Boolean = false): String!
        nickname: String
        toys: [Toy!]!
      }

      interface Canine {
        barkVolume: Int!
      }

      interface Feline {
        meowVolume: Int!
      }

      type Dog implements Pet & Mammal & Canine {
        name(surname: Boolean = false): String!
        nickname: String
        doesKnowCommand(dogCommand: PetCommand): Boolean!
        barkVolume: Int!
        toys: [Toy!]!
      }

      type Cat implements Pet & Mammal & Feline {
        name(surname: Boolean = false): String!
        nickname: String
        doesKnowCommand(catCommand: PetCommand): Boolean!
        meowVolume: Int!
        toys: [Toy!]!
      }

      type Toy {
        name: String!
        size: ToySize!
        image(maxWidth: Int!): String!
      }
    |)
  }

  describe "unique fields" do
    let(:query_string) {%|
      {
        dog {
          name
          nickname
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "identical fields" do
    let(:query_string) {%|
      {
        dog {
          name
          name
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "identical fields with identical input objects" do
    let(:query_string) {%|
      mutation {
        registerPet(params: { name: "Fido", species: DOG }) {
          name
        }
        registerPet(params: { name: "Fido", species: DOG }) {
          __typename
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "identical fields with identical args" do
    let(:query_string) {%|
      {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand(dogCommand: SIT)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "identical fields with identical values" do
    let(:query_string) {%|
      query($dogCommand: PetCommand) {
        dog {
          doesKnowCommand(dogCommand: $dogCommand)
          doesKnowCommand(dogCommand: $dogCommand)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "identical aliases and fields" do
    let(:query_string) {%|
      {
        dog {
          otherName: name
          otherName: name
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "different args with different aliases" do
    let(:query_string) {%|
      {
        dog {
          knowsSit: doesKnowCommand(dogCommand: SIT)
          knowsDown: doesKnowCommand(dogCommand: DOWN)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "conflicting args value and var" do
    let(:query_string) {%|
      query ($dogCommand: PetCommand) {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand(dogCommand: $dogCommand)
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'doesKnowCommand' has an argument conflict: {dogCommand:"SIT"} or {dogCommand:"$dogCommand"}?)], error_messages
    end
  end

  describe "multiple conflicting args value and var" do
    let(:query_string) {%|
      query ($dogCommand: PetCommand) {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand(dogCommand: HEEL)
          doesKnowCommand(dogCommand: $dogCommand)
        }
      }
    |}

    it "fails rule" do
      message = %Q(Field 'doesKnowCommand' has an argument conflict: {dogCommand:"SIT"} or {dogCommand:"HEEL"} or {dogCommand:"$dogCommand"}?)

      assert_equal [message], error_messages
    end
  end

  describe "very large multiple conflicting args value and var" do
    let(:query_string) {%|
      query ($a: PetCommand, $b: PetCommand, $c: PetCommand, $d: PetCommand, $e: PetCommand, $f: PetCommand) {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand(dogCommand: HEEL)
          doesKnowCommand(dogCommand: JUMP)
          doesKnowCommand(dogCommand: DOWN)
          doesKnowCommand(dogCommand: $a)
          doesKnowCommand(dogCommand: $b)
          doesKnowCommand(dogCommand: $c)
          doesKnowCommand(dogCommand: $d)
          doesKnowCommand(dogCommand: $e)
          doesKnowCommand(dogCommand: $f)
        }
      }
    |}

    it "fails rule" do
      assert_equal 1, error_messages.size # instead of n**2 = 100
      assert_match %r/SIT.*HEEL.*JUMP.*DOWN.*\$a.*\$b.*\$c.*\$d.*\$e.*\$f/, error_messages.first
    end
  end

  describe "conflicting args value and var" do
    let(:query_string) {%|
      query ($varOne: PetCommand, $varTwo: PetCommand) {
        dog {
          doesKnowCommand(dogCommand: $varOne)
          doesKnowCommand(dogCommand: $varTwo)
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'doesKnowCommand' has an argument conflict: {dogCommand:"$varOne"} or {dogCommand:"$varTwo"}?)], error_messages
    end
  end

  describe "different directives with different aliases" do
    let(:query_string) {%|
      {
        dog {
          nameIfTrue: name @include(if: true)
          nameIfFalse: name @include(if: false)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "different skip/include directives accepted" do
    let(:query_string) {%|
      {
        dog {
          name @include(if: true)
          name @include(if: false)
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "same aliases with different field targets" do
    let(:query_string) {%|
      {
        dog {
          fido: name
          fido: nickname
        }
      }
    |}

    it "fails rule" do
      assert_equal ["Field 'fido' has a field conflict: name or nickname?"], error_messages
    end
  end

  describe "multiple aliases with different field targets" do
    let(:query_string) {%|
      {
        dog {
          fido: name
          fido: nickname
          fido: barkVolume
        }
      }
    |}

    it "fails rule" do
      assert_equal ["Field 'fido' has a field conflict: name or nickname or barkVolume?"], error_messages
    end
  end

  describe "alias masking direct field access" do
    let(:query_string) {%|
      {
        dog {
          name: nickname
          name
        }
      }
    |}

    it "fails rule" do
      assert_equal ["Field 'name' has a field conflict: nickname or name?"], error_messages
    end
  end

  describe "different args, second adds an argument" do
    let(:query_string) {%|
      {
        dog {
          doesKnowCommand
          doesKnowCommand(dogCommand: HEEL)
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'doesKnowCommand' has an argument conflict: {} or {dogCommand:"HEEL"}?)], error_messages
    end
  end

  describe "different args, second missing an argument" do
    let(:query_string) {%|
      {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'doesKnowCommand' has an argument conflict: {dogCommand:"SIT"} or {}?)], error_messages
    end
  end

  describe "conflicting args" do
    let(:query_string) {%|
      {
        dog {
          doesKnowCommand(dogCommand: SIT)
          doesKnowCommand(dogCommand: HEEL)
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'doesKnowCommand' has an argument conflict: {dogCommand:"SIT"} or {dogCommand:"HEEL"}?)], error_messages
    end
  end

  describe "conflicting arg values" do
    let(:query_string) {%|
      {
        toy {
          image(maxWidth: 10)
          image(maxWidth: 20)
        }
      }
    |}

    it "fails rule" do
      assert_equal [%q(Field 'image' has an argument conflict: {maxWidth:"10"} or {maxWidth:"20"}?)], error_messages
    end
  end

  describe "encounters conflict in fragments" do
    let(:query_string) {%|
      {
        pet {
          ...A
          ...B
          name
        }
      }

      fragment A on Dog {
        x: name
      }

      fragment B on Dog {
        x: nickname
        name: nickname
      }
    |}

    it "fails rule" do
      assert_equal [
        "Field 'x' has a field conflict: name or nickname?",
        "Field 'name' has a field conflict: name or nickname?"
      ], error_messages
    end

    describe "with error limiting" do
      describe("disabled") do
        let(:args) {
          { max_errors: nil }
        }

        it "does not limit the number of errors" do
          assert_equal(error_messages, [
            "Field 'x' has a field conflict: name or nickname?",
            "Field 'name' has a field conflict: name or nickname?"
          ])
        end
      end

      describe("enabled") do
        let(:args) {
          { max_errors: 1 }
        }

        it "does limit the number of errors" do
          assert_equal(error_messages, [
            "Field 'x' has a field conflict: name or nickname?",
          ])
        end
      end
    end
  end


  describe "deep conflict" do
    let(:query_string) {%|
      {
        dog {
          x: name
        }

        dog {
          x: nickname
        }
      }
    |}

    it "fails rule" do
      expected_errors = [
        {
          "message"=>"Field 'x' has a field conflict: name or nickname?",
          "locations"=>[
            {"line"=>4, "column"=>11},
            {"line"=>8, "column"=>11}
          ],
          "path"=>[],
          "extensions"=>{"code"=>"fieldConflict", "fieldName"=>"x", "conflicts"=>"name or nickname"}
        }
      ]
      assert_equal expected_errors, errors
    end
  end

  describe "deep conflict with multiple issues" do
    let(:query_string) {%|
      {
        dog {
          x: name
          y: barkVolume
        }

        dog {
          x: nickname
          y: doesKnowCommand
        }
      }
    |}

    it "fails rule" do
      assert_equal [
        "Field 'x' has a field conflict: name or nickname?",
        "Field 'y' has a field conflict: barkVolume or doesKnowCommand?",
      ], error_messages
    end

    describe "with error limiting" do
      describe("disabled") do
        let(:args) {
          { max_errors: nil }
        }

        it "does not limit the number of errors" do
          assert_equal(error_messages, [
            "Field 'x' has a field conflict: name or nickname?",
            "Field 'y' has a field conflict: barkVolume or doesKnowCommand?",
          ])
        end
      end

      describe("enabled") do
        let(:args) {
          { max_errors: 1 }
        }

        it "does limit the number of errors" do
          assert_equal(error_messages, [
            "Field 'x' has a field conflict: name or nickname?",
          ])
        end
      end
    end
  end

  describe "very deep conflict" do
    let(:query_string) {%|
      {
        dog {
          toys {
            x: name
          }
        }

        dog {
          toys {
            x: size
          }
        }
      }
    |}

    it "fails rule" do
      assert_equal [
        "Field 'x' has a field conflict: name or size?",
      ], error_messages
    end
  end


  describe "same aliases allowed on non-overlapping fields" do
    let(:query_string) {%|
      {
        pet {
          ... on Dog {
            name
          }
          ... on Cat {
            name: nickname
          }
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "nested spreads on the same type with a conflict" do
    let(:query_string) {%|
      {
        dog {
          name
          ...D
        }
      }

      fragment D on Dog {
        ...D2
      }

      fragment D2 on Dog {
        name: __typename
      }
    |}

    it "finds a conflict" do
      assert_equal [
        {"message"=>"Field 'name' has a field conflict: name or __typename?",
          "locations"=>[{"line"=>4, "column"=>11}, {"line"=>14, "column"=>9}],
          "path"=>[],
          "extensions"=>
          {"code"=>"fieldConflict",
           "fieldName"=>"name",
           "conflicts"=>"name or __typename"}
        }
      ], errors
    end
  end

  describe "same aliases not allowed on different interfaces" do
    let(:query_string) {%|
      {
        pet {
          ... on Pet {
            name
          }
          ... on Mammal {
            name: nickname
          }
        }
      }
    |}

    it "fails rule" do
      assert_equal [
        "Field 'name' has a field conflict: name or nickname?",
      ], error_messages
    end
  end

  describe "same aliases on divergent abstract types" do
    let(:query_string) {%|
      {
        animal {
          ... on Feline {
            volume: meowVolume
          }
          ... on Canine {
            volume: barkVolume
          }
        }
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "same aliases allowed on different parent interfaces and different concrete types" do
    let(:query_string) {%|
      {
        pet {
          ... on Pet {
            ...X
          }
          ... on Mammal {
            ...Y
          }
        }
      }

      fragment X on Dog {
        name
      }
      fragment Y on Cat {
        name: nickname
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "allows different args where no conflict is possible" do
    let(:query_string) {%|
      {
        pet {
          ... on Dog {
            ...X
          }
          ... on Cat {
            ...Y
          }
        }
      }

      fragment X on Pet {
        name(surname: true)
      }

      fragment Y on Pet {
        name
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end

    describe "allows different args where no conflict is possible" do
      let(:query_string) {%|
        {
          pet {
            ... on Dog {
              ... on Pet {
                name
              }
            }
            ... on Cat {
              name(surname: true)
            }
          }
        }
      |}

      it "passes rule" do
        assert_equal [], errors
      end
    end

    describe "allows different args where no conflict is possible with uneven abstract scoping" do
      let(:query_string) {%|
        {
          pet {
            ... on Pet {
              ... on Dog {
                name
              }
            }
            ... on Cat {
              name(surname: true)
            }
          }
        }
      |}

      it "passes rule" do
        assert_equal [], errors
      end
    end
  end

  describe "allows different args where no conflict is possible deep" do
    let(:query_string) {%|
      {
        pet {
          ... on Dog {
            ...X
          }
        }
        pet {
          ... on Cat {
            ...Y
          }
        }
      }

      fragment X on Pet {
        name(surname: true)
      }

      fragment Y on Pet {
        name
      }
    |}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "arguments that are a list of enums, in fragments" do
    let(:schema) {
      GraphQL::Schema.from_definition <<-GRAPHQL
      type Query {
        field(categories: [Category!]): Int
      }

      enum Category {
        A
        B
        C
      }
      GRAPHQL
    }

    describe "When there's not a conflict" do
      let(:query_string) {
        "
        {
          field(categories: [A, B, C])
          ...Q
        }
        fragment Q on Query {
          field(categories: [A, B, C])
        }
        "
      }

      it "doesn't find errors" do
        assert_equal [], errors
      end
    end

    describe "When there is a conflict" do
      let(:query_string) {
        "
        {
          field(categories: [A, B])
          ...Q
        }
        fragment Q on Query {
          field(categories: [A, B, C])
        }
        "
      }

      it "adds an error" do
        expected_error = {
          "message"=>"Field 'field' has an argument conflict: {categories:\"[A, B]\"} or {categories:\"[A, B, C]\"}?",
          "locations"=>[{"line"=>3, "column"=>11}, {"line"=>7, "column"=>11}],
          "path"=>[],
          "extensions"=> {
            "code"=>"fieldConflict",
            "fieldName"=>"field",
            "conflicts"=>"{categories:\"[A, B]\"} or {categories:\"[A, B, C]\"}"
          }
        }

        assert_equal [expected_error], errors
      end
    end
  end

  describe "return types must be unambiguous" do
    let(:schema) {
      GraphQL::Schema.from_definition(%|
        type Query {
          someBox: SomeBox
          connection: Connection
        }

        type Edge {
          id: ID
          name: String
        }

        interface SomeBox {
          deepBox: SomeBox
          unrelatedField: String
        }

        type StringBox implements SomeBox {
          scalar: String
          deepBox: StringBox
          unrelatedField: String
          listStringBox: [StringBox]
          stringBox: StringBox
          intBox: IntBox
        }

        type IntBox implements SomeBox {
          scalar: Int
          deepBox: IntBox
          unrelatedField: String
          listStringBox: [StringBox]
          stringBox: StringBox
          intBox: IntBox
        }

        interface NonNullStringBox1 {
          scalar: String!
        }

        type NonNullStringBox1Impl implements SomeBox & NonNullStringBox1 {
          scalar: String!
          unrelatedField: String
          deepBox: SomeBox
        }

        interface NonNullStringBox2 {
          scalar: String!
        }

        type NonNullStringBox2Impl implements SomeBox & NonNullStringBox2 {
          scalar: String!
          unrelatedField: String
          deepBox: SomeBox
        }

        type Connection {
          edges: [Edge]
        }
      |)
    }

    describe "compatible return shapes on different return types" do
      let(:query_string) {%|
        {
          someBox {
            ... on SomeBox {
              deepBox {
                unrelatedField
              }
            }
            ... on StringBox {
              deepBox {
                unrelatedField
              }
            }
          }
        }
      |}

      it "passes rule" do
        assert_equal [], errors
      end
    end

    describe "reports correctly when a non-exclusive follows an exclusive" do
      let(:query_string) {%|
        {
          someBox {
            ... on IntBox {
              deepBox {
                ...X
              }
            }
          }
          someBox {
            ... on StringBox {
              deepBox {
                ...Y
              }
            }
          }
          memoed: someBox {
            ... on IntBox {
              deepBox {
                ...X
              }
            }
          }
          memoed: someBox {
            ... on StringBox {
              deepBox {
                ...Y
              }
            }
          }
          other: someBox {
            ...X
          }
          other: someBox {
            ...Y
          }
        }
        fragment X on SomeBox {
          scalar: deepBox { unrelatedField }
        }
        fragment Y on SomeBox {
          scalar: unrelatedField
        }
      |}

      it "fails rule" do
        assert_includes error_messages, "Field 'scalar' has a field conflict: deepBox or unrelatedField?"
      end
    end
  end

  describe "conflicts exceeding the max_errors count" do
    signature = (1..20).map { |n| "$arg#{n}: PetCommand" }.join(', ')
    fields = (1..20).map { |n| "doesKnowCommand(dogCommand: $arg#{n})" }.join(" ")

    let(:args) do
      { max_errors: 10 }
    end

    let(:query_string) {%|
      query (#{signature}) {
        dog { #{fields} }
      }
    |}

    it "fails rule" do
      assert_equal 1, error_messages.size
      (1..11).each do |n|
        assert_match %r/\$arg#{n}/, error_messages.first
      end

      refute_match %r/\$arg12/, error_messages.first
    end
  end
end
