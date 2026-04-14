# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Json::RailsEncoder, feature_category: :tooling do
  describe "#stringify" do
    subject(:encoder) { described_class.new }

    it "serializes a hash via Gitlab::Json.dump" do
      jsonified = { "foo" => "bar" }

      expect(Gitlab::Json).to receive(:dump).with(jsonified).and_call_original

      result = encoder.stringify(jsonified)
      expect(result).to eq('{"foo":"bar"}')
    end

    it "serializes an array via Gitlab::Json.dump" do
      jsonified = [1, 2, 3]

      result = encoder.stringify(jsonified)
      expect(result).to eq("[1,2,3]")
    end

    context "when Gitlab::Json.dump raises EncodingError" do
      it "wraps the error as JSON::GeneratorError" do
        allow(Gitlab::Json).to receive(:dump).and_raise(EncodingError, "bad encoding")

        expect { encoder.stringify("value") }.to raise_error(JSON::GeneratorError, "bad encoding")
      end
    end
  end
end
