# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::UniqueDirectivesPerLocation do
  include StaticValidationHelpers

  let(:schema) { GraphQL::Schema.from_definition("
    type Query {
      type: Type
    }

    type Type {
      field: String
    }

    directive @A on FIELD
    directive @B on FIELD
    directive @C repeatable on FIELD
  ") }

  describe "query with no directives" do
    let(:query_string) {"
      {
        type {
          field
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with repeatable directives" do
    let(:query_string) {"
      {
        type {
          field @C @C @C
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with unique directives in different locations" do
    let(:query_string) {"
      {
        type @A {
          field @B
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with unique directives in same locations" do
    let(:query_string) {"
      {
        type @A @B {
          field @A @B
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with same directives in different locations" do
    let(:query_string) {"
      {
        type @A {
          field @A
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with same directives in similar locations" do
    let(:query_string) {"
      {
        type {
          field @A
          field @A
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with duplicate directives in one location" do
    let(:query_string) {"
      {
        type {
          field @A @A
        }
      }
    "}

    it "fails rule" do
      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 17 }, { "line" => 4, "column" => 20 }],
        "path" => ["query", "type", "field"],
        "extensions" => {"code"=>"directiveNotUniqueForLocation", "directiveName"=>"A"}
      }
    end
  end


  describe "query with many duplicate directives in one location" do
    let(:query_string) {"
      {
        type {
          field @A @A @A
        }
      }
    "}

    it "fails rule" do
      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 17 }, { "line" => 4, "column" => 20 },  { "line" => 4, "column" => 23 }],
        "path" => ["query", "type", "field"],
        "extensions" => {"code"=>"directiveNotUniqueForLocation", "directiveName"=>"A"}
      }
    end
  end

  describe "query with different duplicate directives in one location" do
    let(:query_string) {"
      {
        type {
          field @A @B @A @B
        }
      }
    "}

    it "fails rule" do
      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 17 }, { "line" => 4, "column" => 23 }],
        "path" => ["query", "type", "field"],
        "extensions" => {"code"=>"directiveNotUniqueForLocation", "directiveName"=>"A"}
      }

      assert_includes errors, {
        "message" => 'The directive "B" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 20 }, { "line" => 4, "column" => 26 }],
        "path" => ["query", "type", "field"],
        "extensions" => {"code"=>"directiveNotUniqueForLocation", "directiveName"=>"B"}
      }
    end
  end

  describe "query with duplicate directives in many locations" do
    let(:query_string) {"
      {
        type @A @A {
          field @A @A
        }
      }
    "}

    it "fails rule" do
      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 3, "column" => 14 }, { "line" => 3, "column" => 17 }],
        "path" => ["query", "type"],
        "extensions" => {"code"=>"directiveNotUniqueForLocation", "directiveName"=>"A"}
      }

      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 17 }, { "line" => 4, "column" => 20 }],
        "path" => ["query", "type", "field"],
        "extensions" => {"code"=>"directiveNotUniqueForLocation", "directiveName"=>"A"}
      }
    end
  end

  describe "with error limiting" do
    let(:query_string) {"
      {
        type @A @A {
          field @A @A
        }
      }
    "}

    describe("disabled") do
      let(:args) {
        { max_errors: nil }
      }

      it "does not limit the number of errors" do
        assert_equal(error_messages.length, 2)
        assert_equal(error_messages, [
          "The directive \"A\" can only be used once at this location.",
          "The directive \"A\" can only be used once at this location."
        ])
      end
    end

    describe("enabled") do
      let(:args) {
        { max_errors: 1 }
      }

      it "does limit the number of errors" do
        assert_equal(error_messages.length, 1)
        assert_equal(error_messages, [
          "The directive \"A\" can only be used once at this location."
        ])
      end
    end
  end
end
