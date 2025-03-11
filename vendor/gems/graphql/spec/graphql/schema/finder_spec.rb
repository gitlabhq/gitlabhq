# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Finder do
  let(:finder) { GraphQL::Schema::Finder.new(Jazz::Schema) }

  describe "#find" do
    it "finds a valid object type" do
      type = finder.find("Ensemble")
      assert_equal "Ensemble", type.graphql_name
    end

    it "raises when finding an invalid object type" do
      exception = assert_raises GraphQL::Schema::Finder::MemberNotFoundError do
        finder.find("DoesNotExist")
      end

      assert_match(/Could not find type `DoesNotExist` in schema./, exception.message)
    end

    it "finds a valid directive" do
      directive = finder.find("@include")
      assert_equal "include", directive.graphql_name
    end

    it "raises when finding an invalid directive" do
      exception = assert_raises GraphQL::Schema::Finder::MemberNotFoundError do
        finder.find("@yolo")
      end

      assert_match(/Could not find directive `@yolo` in schema./, exception.message)
    end

    it "finds a valid field" do
      field = finder.find("Ensemble.musicians")
      assert_equal "musicians", field.graphql_name
    end

    it "finds a meta field" do
      field = finder.find("Ensemble.__typename")
      assert_equal "__typename", field.graphql_name
    end

    it "raises when finding an in valid field" do
      exception = assert_raises GraphQL::Schema::Finder::MemberNotFoundError do
        finder.find("Ensemble.nope")
      end

      assert_match(/Could not find field `nope` on object type `Ensemble`./, exception.message)
    end

    it "finds a valid argument" do
      arg = finder.find("Query.find.id")
      assert_equal "id", arg.graphql_name
    end

    it "raises when finding an invalid argument" do
      exception = assert_raises GraphQL::Schema::Finder::MemberNotFoundError do
        finder.find("Query.find.thisArgumentIsInvalid")
      end

      assert_match(/Could not find argument `thisArgumentIsInvalid` on field `find`./, exception.message)
    end

    it "raises when selecting on an argument" do
      exception = assert_raises GraphQL::Schema::Finder::MemberNotFoundError do
        finder.find("Query.find.id.whyYouDoThis")
      end

      assert_match(/Cannot select member `whyYouDoThis` on a field./, exception.message)
    end

    it "finds a valid interface" do
      type = finder.find("NamedEntity")
      assert_equal "NamedEntity", type.graphql_name
    end

    it "finds a valid input type" do
      type = finder.find("LegacyInput")
      assert_equal "LegacyInput", type.graphql_name
    end

    it "finds a valid input field" do
      input_field = finder.find("LegacyInput.intValue")
      assert_equal "intValue", input_field.graphql_name
    end

    it "raises when finding an invalid input field" do
      exception = assert_raises GraphQL::Schema::Finder::MemberNotFoundError do
        finder.find("LegacyInput.wat")
      end

      assert_match(/Could not find input field `wat` on input object type `LegacyInput`./, exception.message)
    end

    it "finds a valid union type" do
      type = finder.find("PerformingAct")
      assert_equal "PerformingAct", type.graphql_name
    end

    it "raises when selecting a possible type" do
      exception = assert_raises GraphQL::Schema::Finder::MemberNotFoundError do
        finder.find("PerformingAct.Musician")
      end

      assert_match(/Cannot select union possible type `Musician`. Select the type directly instead./, exception.message)
    end

    it "finds a valid enum type" do
      type = finder.find("Family")
      assert_equal "Family", type.graphql_name
    end

    it "finds a valid enum value" do
      value = finder.find("Family.BRASS")
      assert_equal "BRASS", value.graphql_name
    end

    it "raises when finding an invalid enum value" do
      exception = assert_raises GraphQL::Schema::Finder::MemberNotFoundError do
        finder.find("Family.THISISNOTASTATUS")
      end

      assert_match(/Could not find enum value `THISISNOTASTATUS` on enum type `Family`./, exception.message)
    end

    it "raises when selecting on an enum value" do
      exception = assert_raises GraphQL::Schema::Finder::MemberNotFoundError do
        finder.find("Family.BRASS.wat")
      end

      assert_match(/Cannot select member `wat` on an enum value./, exception.message)
    end
  end
end
