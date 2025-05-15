# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::License::Common, feature_category: :dependency_management do
  describe "#parse" do
    subject(:license) { described_class.new(data).parse }

    context "when the license is defined by id" do
      let(:data) do
        {
          "license" => {
            "id" => "Apache-2.0",
            "url" => "https://www.apache.org/licenses/LICENSE-2.0.txt"
          }
        }
      end

      it "sets the expected values" do
        is_expected.to be_kind_of(::Gitlab::Ci::Reports::Sbom::License)

        expect(license.spdx_identifier).to eq("Apache-2.0")
        expect(license.url).to eq("https://www.apache.org/licenses/LICENSE-2.0.txt")
      end
    end

    context "when the license is defined by name" do
      let(:data) do
        {
          "license" => {
            "name" => "Example, Inc. Commercial License"
          }
        }
      end

      it "sets the expected values" do
        is_expected.to be_kind_of(::Gitlab::Ci::Reports::Sbom::License)

        expect(license.name).to eq("Example, Inc. Commercial License")
      end
    end
  end

  it_behaves_like 'with sbom licenses'
end
