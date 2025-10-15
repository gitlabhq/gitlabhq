# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::License::Common, feature_category: :dependency_management do
  let(:data) do
    {
      "license" => {
        "id" => "EPL-2.0"
      }
    }
  end

  shared_examples 'with license id' do
    it "sets the expected values" do
      is_expected.to be_kind_of(::Gitlab::Ci::Reports::Sbom::License)

      expect(license.spdx_identifier).to eq("EPL-2.0")
    end
  end

  describe '.parse' do
    subject(:license) { described_class.parse(data) }

    it_behaves_like 'with license id'
  end

  describe "#parse" do
    subject(:license) { described_class.new(data).parse }

    it_behaves_like 'with license id'

    context "when license is not present" do
      let(:data) { {} }

      it "returns nil" do
        is_expected.to be_nil
      end
    end

    context "when the license does not have id" do
      let(:data) do
        {
          "license" => {
            "url" => "https://example.com/license.txt"
          }
        }
      end

      it "returns nil" do
        is_expected.to be_nil
      end
    end

    context 'when there is a valid ID in the name field' do
      let(:data) { { "license" => { "name" => "EPL-2.0" } } }

      it 'moves the name to the id field' do
        expect(license.spdx_identifier).to eq("EPL-2.0")
        expect(license.name).to be_nil
      end
    end

    context 'when name is not an SPDX id' do
      let(:data) { { "license" => { "name" => "BSD-2-Clause-NetBSD" } } }

      it 'leaves the data as-is' do
        expect(license.spdx_identifier).to be_nil
        expect(license.name).to eq("BSD-2-Clause-NetBSD")
      end
    end
  end
end
