# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Directive::Transform do
  class TransformSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :echo, String, null: false do
        argument :input, String
      end

      def echo(input:)
        input
      end
    end

    directive(GraphQL::Schema::Directive::Transform)

    query(Query)
  end

  it "transforms when applicable" do
    str = '{
      normal: echo(input: "Hello")
      upcased: echo(input: "Hello") @transform(by: "upcase")
      downcased: echo(input: "Hello") @transform(by: "downcase")
      nonsense: echo(input: "Hello") @transform(by: "nonsense")
    }'

    res = TransformSchema.execute(str)

    assert_equal "Hello", res["data"]["normal"]
    assert_equal "HELLO", res["data"]["upcased"]
    assert_equal "hello", res["data"]["downcased"]
    assert_equal "Hello", res["data"]["nonsense"]
  end
end
