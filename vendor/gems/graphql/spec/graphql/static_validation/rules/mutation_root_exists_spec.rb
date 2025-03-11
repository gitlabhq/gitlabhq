# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::MutationRootExists do
  include StaticValidationHelpers

  let(:query_string) {%|
    mutation addBagel {
      introduceShip(input: {shipName: "Bagel"}) {
        clientMutationId
        shipEdge {
          node { name, id }
        }
      }
    }
  |}

  let(:schema) {
    Class.new(GraphQL::Schema) do
      query_root = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
      end

      query query_root
    end
  }

  it "errors when a mutation is performed on a schema without a mutation root" do
    assert_equal(1, errors.length)
    missing_mutation_root_error = {
      "message"=>"Schema is not configured for mutations",
      "locations"=>[{"line"=>2, "column"=>5}],
      "path"=>["mutation addBagel"],
      "extensions"=>{"code"=>"missingMutationConfiguration"}
    }
    assert_includes(errors, missing_mutation_root_error)
  end
end
