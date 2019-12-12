# frozen_string_literal: true

require "spec_helper"

describe Gitlab::GoogleCodeImport::Client do
  let(:raw_data) { JSON.parse(fixture_file("GoogleCodeProjectHosting.json")) }

  subject { described_class.new(raw_data) }

  describe "#valid?" do
    context "when the data is valid" do
      it "returns true" do
        expect(subject).to be_valid
      end
    end

    context "when the data is invalid" do
      let(:raw_data) { "No clue" }

      it "returns true" do
        expect(subject).not_to be_valid
      end
    end
  end

  describe "#repos" do
    it "returns only Git repositories" do
      expect(subject.repos.length).to eq(1)
      expect(subject.incompatible_repos.length).to eq(1)
    end
  end

  describe "#repo" do
    it "returns the referenced repository" do
      expect(subject.repo("tint2").name).to eq("tint2")
    end
  end
end
