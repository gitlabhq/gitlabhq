# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Relay::ConnectionType" do
  describe ".create_type" do
    describe "connections with custom Edge classes / EdgeTypes" do
      let(:query_string) {%|
        query($testNames: Boolean!) {
          rebels {
            basesWithCustomEdge {
              totalCountTimes100
              fieldName @include(if: $testNames)
              edges {
                upcasedName @include(if: $testNames)
                upcasedParentName @include(if: $testNames)
                edgeClassName
                node {
                  name
                }
                cursor
              }
            }
          }
        }
      |}

      it "uses the custom edge and custom connection" do
        result = star_wars_query(query_string, { "testNames" => true })
        bases = result["data"]["rebels"]["basesWithCustomEdge"]
        assert_equal 300, bases["totalCountTimes100"]
        assert_equal 'basesWithCustomEdge', bases["fieldName"]
        assert_equal ["YAVIN", "ECHO BASE", "SECRET HIDEOUT"] , bases["edges"].map { |e| e["upcasedName"] }
        upcased_rebels_name = "ALLIANCE TO RESTORE THE REPUBLIC"
        assert_equal [upcased_rebels_name] , bases["edges"].map { |e| e["upcasedParentName"] }.uniq
        assert_equal ["Yavin", "Echo Base", "Secret Hideout"] , bases["edges"].map { |e| e["node"]["name"] }
        assert_equal ["StarWars::NewCustomBaseEdge"] , bases["edges"].map { |e| e["edgeClassName"] }.uniq
      end
    end

    describe "connections with nodes field" do
      let(:query_string) {%|
        {
          rebels {
            bases {
              nodes {
                name
              }
            }
            basesWithCustomEdge {
              nodes {
                name
              }
            }
          }
        }
      |}

      it "uses the custom edge and custom connection" do
        result = star_wars_query(query_string)
        bases = result["data"]["rebels"]["bases"]
        assert_equal ["Yavin", "Echo Base", "Secret Hideout"] , bases["nodes"].map { |e| e["name"] }
        bases_with_custom_edge = result["data"]["rebels"]["basesWithCustomEdge"]
        assert_equal ["Yavin", "Echo Base", "Secret Hideout"] , bases_with_custom_edge["nodes"].map { |e| e["name"] }
      end
    end

    describe "connections without nodes field" do
      let(:query_string) {%|
        {
          rebels {
            basesWithoutNodes {
              nodes {
                name
              }
            }
          }
        }
      |}

      it "raises error" do
        result = star_wars_query(query_string)
        assert_includes result["errors"][0]["message"], "Field 'nodes' doesn't exist"
      end
    end

    describe "when an execution error is raised" do
      let(:query_string) {%|
        {
          basesWithNullName {
            edges {
              node {
                name
              }
            }
          }
        }
      |}

      it "nullifies the parent and adds an error" do
        result = star_wars_query(query_string)
        assert_nil result["data"]["basesWithNullName"]["edges"][0]["node"]
        assert_equal "Boom!", result["errors"][0]["message"]
      end
    end
  end
end
