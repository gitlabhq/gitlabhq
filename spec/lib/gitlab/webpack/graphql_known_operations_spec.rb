# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Webpack::GraphqlKnownOperations do
  let(:content) do
    <<-EOF
    - hello
    - world
    - test
    EOF
  end

  around do |example|
    described_class.clear_memoization!

    example.run

    described_class.clear_memoization!
  end

  describe ".load" do
    context "when file loader returns" do
      before do
        allow(::Gitlab::Webpack::FileLoader).to receive(:load).with("graphql_known_operations.yml").and_return(content)
      end

      it "returns memoized value" do
        expect(::Gitlab::Webpack::FileLoader).to receive(:load).once

        2.times { ::Gitlab::Webpack::GraphqlKnownOperations.load }

        expect(::Gitlab::Webpack::GraphqlKnownOperations.load).to eq(%w[hello world test])
      end
    end

    context "when file loader errors" do
      before do
        allow(::Gitlab::Webpack::FileLoader).to receive(:load).and_raise(StandardError.new("test"))
      end

      it "returns empty array" do
        expect(::Gitlab::Webpack::GraphqlKnownOperations.load).to eq([])
      end
    end
  end
end
