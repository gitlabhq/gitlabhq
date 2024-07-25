# frozen_string_literal: true

# require 'fast_spec_helper' -- this no longer runs under fast_spec_helper
require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Graphql::KnownOperations do
  using RSpec::Parameterized::TableSyntax

  # Include duplicated operation names to test that we are unique-ifying them
  let(:fake_operations) { %w[foo foo bar bar] }
  let(:fake_schema) do
    Class.new(GraphQL::Schema) do
      query Graphql::FakeQueryType
    end
  end

  subject { described_class.new(fake_operations) }

  describe "#from_query" do
    where(:query_string, :expected) do
      "query { helloWorld }"         | described_class::UNKNOWN
      "query fuzzyyy { helloWorld }" | described_class::UNKNOWN
      "query foo { helloWorld }"     | described_class::Operation.new("foo")
    end

    with_them do
      it "returns known operation name from GraphQL Query" do
        query = ::GraphQL::Query.new(fake_schema, query_string)

        expect(subject.from_query(query)).to eq(expected)
      end
    end
  end

  describe "#operations" do
    it "returns array of known operations" do
      expect(subject.operations.map(&:name)).to match_array(%w[unknown foo bar])
    end
  end

  describe "Operation#to_caller_id" do
    where(:query_string, :expected) do
      "query { helloWorld }"         | "graphql:#{described_class::UNKNOWN.name}"
      "query foo { helloWorld }"     | "graphql:foo"
    end

    with_them do
      it "formats operation name for caller_id metric property" do
        query = ::GraphQL::Query.new(fake_schema, query_string)

        expect(subject.from_query(query).to_caller_id).to eq(expected)
      end
    end
  end

  describe "Opeartion#query_urgency" do
    it "returns the associated query urgency" do
      query = ::GraphQL::Query.new(fake_schema, "query foo { helloWorld }")

      expect(subject.from_query(query).query_urgency).to equal(::Gitlab::EndpointAttributes::DEFAULT_URGENCY)
    end
  end

  describe ".default" do
    it "returns a memoization of values from webpack", :aggregate_failures do
      # .default could have been referenced in another spec, so we need to clean it up here
      described_class.instance_variable_set(:@default, nil)

      expect(Gitlab::Webpack::GraphqlKnownOperations).to receive(:load).once.and_return(fake_operations)

      2.times { described_class.default }

      # Uses reference equality to verify memoization
      expect(described_class.default).to equal(described_class.default)
      expect(described_class.default).to be_a(described_class)
      expect(described_class.default.operations.map(&:name)).to include(*fake_operations)
    end
  end
end
