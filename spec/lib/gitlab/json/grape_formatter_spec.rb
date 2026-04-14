# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Json::GrapeFormatter, feature_category: :tooling do
  describe ".call" do
    context "when object is a Precompiled instance" do
      it "returns the precompiled string without re-encoding" do
        precompiled = Gitlab::Json::Precompiled.new('{"foo":"bar"}')

        expect(described_class.call(precompiled)).to eq('{"foo":"bar"}')
      end

      it "handles a Precompiled wrapping an array" do
        precompiled = Gitlab::Json::Precompiled.new(%w[a b])

        expect(described_class.call(precompiled)).to eq("[a,b]")
      end
    end

    context "when object is a plain Ruby object" do
      it "encodes a hash to JSON" do
        expect(described_class.call({ "foo" => "bar" })).to eq('{"foo":"bar"}')
      end

      it "encodes an array to JSON" do
        expect(described_class.call([1, 2, 3])).to eq("[1,2,3]")
      end

      it "encodes a string to JSON" do
        expect(described_class.call("hello")).to eq('"hello"')
      end
    end
  end
end
