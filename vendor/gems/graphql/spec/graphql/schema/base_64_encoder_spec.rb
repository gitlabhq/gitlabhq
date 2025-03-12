# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Base64Encoder do
  describe ".decode" do
    it "decodes base64 encoded strings" do
      string = "12345"
      encoded_string = GraphQL::Schema::Base64Encoder.encode(string)
      decoded_string = GraphQL::Schema::Base64Encoder.decode(encoded_string)

      assert_equal(string, decoded_string)
    end

    it "raises an execution error when an invalid cursor is given" do
      assert_raises(GraphQL::ExecutionError) do
        GraphQL::Schema::Base64Encoder.decode("12345")
      end
    end
  end
end
