# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Webpack::GraphqlKnownOperations, feature_category: :api do
  let(:yaml_content) do
    <<~YAML
      addGroupVariable:
        feature_category: continuous_integration
        urgency: low
      currentUser:
        feature_category: null
        urgency: default
      getPipelineDetails:
        feature_category: continuous_integration
        urgency: default
      UpdateBoard:
        feature_category: team_planning
        urgency: high
    YAML
  end

  around do |example|
    described_class.clear_memoization!
    example.run
    described_class.clear_memoization!
  end

  before do
    allow(::Gitlab::Webpack::FileLoader).to receive(:load)
      .with("graphql_known_operations.yml")
      .and_return(yaml_content)
  end

  describe ".load" do
    let(:expected_result) do
      {
        "addGroupVariable" => { "feature_category" => "continuous_integration", "urgency" => "low" },
        "currentUser" => { "feature_category" => nil, "urgency" => "default" },
        "getPipelineDetails" => { "feature_category" => "continuous_integration", "urgency" => "default" },
        "UpdateBoard" => { "feature_category" => "team_planning", "urgency" => "high" }
      }
    end

    it "parses and returns the operations hash" do
      expect(described_class.load).to eq(expected_result)
    end

    it "returns memoized value" do
      expect(::Gitlab::Webpack::FileLoader).to receive(:load).once

      2.times { ::Gitlab::Webpack::GraphqlKnownOperations.load }
    end

    context "when file loader errors" do
      before do
        allow(::Gitlab::Webpack::FileLoader).to receive(:load)
          .and_raise(StandardError.new("test"))
      end

      it "returns empty array" do
        expect(::Gitlab::Webpack::GraphqlKnownOperations.load).to eq([])
      end
    end
  end

  describe "YAML output validation", :aggregate_failures do
    let(:operations) { described_class.load }

    it "returns a non-empty Hash" do
      expect(operations).to be_a(Hash)
      expect(operations).not_to be_empty
    end

    it "contains operation entries with required fields" do
      operations.each do |operation_name, metadata|
        expect(operation_name).to be_a(String)
        expect(metadata).to be_a(Hash)
        expect(metadata).to have_key('feature_category')
        expect(metadata).to have_key('urgency')
      end
    end

    it "has valid urgency values" do
      valid_urgencies = %w[default low high]

      operations.each do |operation_name, metadata|
        urgency = metadata['urgency']
        expect(valid_urgencies).to include(urgency),
          "Operation '#{operation_name}' has invalid urgency: '#{urgency}'"
      end
    end

    it "has properly formatted operation names" do
      operations.each_key do |operation_name|
        expect(operation_name).to match(/\A[a-zA-Z][a-zA-Z0-9_]*\z/),
          "Operation name '#{operation_name}' is not a valid GraphQL operation name"
      end
    end

    it "has feature_category as either a string or null" do
      operations.each do |operation_name, metadata|
        feature_category = metadata['feature_category']
        expect([String, NilClass]).to include(feature_category.class),
          "Operation '#{operation_name}' has invalid feature_category type: #{feature_category.class}"
      end
    end
  end
end
