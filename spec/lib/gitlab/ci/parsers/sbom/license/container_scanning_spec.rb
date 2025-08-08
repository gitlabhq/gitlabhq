# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::License::ContainerScanning, feature_category: :dependency_management do
  describe "#parse" do
    subject(:license) { described_class.new(data).parse }

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

        expect(license.spdx_identifier).to eq("Example, Inc. Commercial License")
      end

      context "when the license also defines the id" do
        let(:data) do
          {
            "license" => {
              "id" => "Example ID, Inc. Commercial License",
              "name" => "Example NAME, Inc. Commercial License"
            }
          }
        end

        it "sets the expected values" do
          is_expected.to be_kind_of(::Gitlab::Ci::Reports::Sbom::License)

          expect(license.spdx_identifier).to eq("Example ID, Inc. Commercial License")
        end
      end
    end

    context "when the license is defined by id" do
      let(:data) do
        {
          "license" => {
            "id" => "Example, Inc. Commercial License"
          }
        }
      end

      it "sets the expected values" do
        is_expected.to be_kind_of(::Gitlab::Ci::Reports::Sbom::License)

        expect(license.spdx_identifier).to eq("Example, Inc. Commercial License")
      end
    end
  end

  it_behaves_like 'with sbom licenses'
end
