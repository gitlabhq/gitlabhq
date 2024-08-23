# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Ci::Parsers::Sbom::Validators::CyclonedxSchemaValidator,
  feature_category: :dependency_management do
  let(:report_data) do
    {
      "bomFormat" => "CycloneDX",
      "specVersion" => spec_version,
      "version" => 1
    }
  end

  subject(:validator) { described_class.new(report_data) }

  shared_examples 'a validator that performs the expected validations' do
    let(:required_attributes) do
      {
        "bomFormat" => "CycloneDX",
        "specVersion" => spec_version,
        "version" => 1
      }
    end

    context "with minimally valid report" do
      let(:report_data) { required_attributes }

      it { is_expected.to be_valid }
    end

    context "when report has components" do
      let(:report_data) { required_attributes.merge({ "components" => components }) }

      context "with minimally valid components" do
        let(:components) do
          [
            {
              "type" => "library",
              "name" => "activesupport"
            },
            {
              "type" => "library",
              "name" => "byebug"
            }
          ]
        end

        it { is_expected.to be_valid }
      end

      context "when components have versions" do
        let(:components) do
          [
            {
              "type" => "library",
              "name" => "activesupport",
              "version" => "5.1.4"
            },
            {
              "type" => "library",
              "name" => "byebug",
              "version" => "10.0.0"
            }
          ]
        end

        it { is_expected.to be_valid }
      end

      context 'when components have licenses' do
        let(:components) do
          [
            {
              "type" => "library",
              "name" => "activesupport",
              "version" => "5.1.4",
              "licenses" => [
                { "license" => { "id" => "MIT" } }
              ]
            }
          ]
        end

        it { is_expected.to be_valid }
      end

      context 'when components have a signature' do
        let(:components) do
          [
            {
              "type" => "library",
              "name" => "activesupport",
              "version" => "5.1.4",
              "signature" => {
                "algorithm" => "ES256",
                "publicKey" => {
                  "kty" => "EC",
                  "crv" => "P-256",
                  "x" => "6BKxpty8cI-exDzCkh-goU6dXq3MbcY0cd1LaAxiNrU",
                  "y" => "mCbcvUzm44j3Lt2b5BPyQloQ91tf2D2V-gzeUxWaUdg"
                },
                "value" => "ybT1qz5zHNi4Ndc6y7Zhamuf51IqXkPkZwjH1XcC-KSuBiaQplTw6Jasf2MbCLg3CF7PAdnMO__WSLwvI5r2jA"
              }
            }
          ]
        end

        it { is_expected.to be_valid }
      end

      context "when components are not valid" do
        let(:components) do
          [
            { "type" => "foo" },
            { "name" => "activesupport" }
          ]
        end

        it { is_expected.not_to be_valid }

        it "outputs errors for each validation failure" do
          expect(validator.errors).to match_array(
            [
              "property '/components/0' is missing required keys: name",
              a_string_starting_with("property '/components/0/type' is not one of:"),
              "property '/components/1' is missing required keys: type"
            ])
        end
      end

      describe "name length validation" do
        let(:components) do
          [
            { "type" => "library", "name" => "" },
            { "type" => "library", "name" => "a" * 256 }
          ]
        end

        it { is_expected.not_to be_valid }

        it "outputs errors for each validation failure" do
          expect(validator.errors).to match_array(
            [
              "property '/components/0/name' is invalid: error_type=minLength",
              "property '/components/1/name' is invalid: error_type=maxLength"
            ])
        end
      end

      describe "version length validation" do
        let(:components) do
          [
            { "type" => "library", "name" => "activesupport", "version" => "" },
            { "type" => "library", "name" => "activesupport", "version" => "a" * 256 }
          ]
        end

        it { is_expected.not_to be_valid }

        it "outputs errors for each validation failure" do
          expect(validator.errors).to match_array(
            [
              "property '/components/0/version' is invalid: error_type=minLength",
              "property '/components/1/version' is invalid: error_type=maxLength"
            ])
        end
      end
    end

    context "when report has metadata" do
      let(:metadata) do
        {
          "timestamp" => "2022-02-23T08:02:39Z",
          "tools" => [{ "vendor" => "GitLab", "name" => "Gemnasium", "version" => "2.34.0" }],
          "authors" => [{ "name" => "GitLab", "email" => "support@gitlab.com" }]
        }
      end

      let(:report_data) { required_attributes.merge({ "metadata" => metadata }) }

      it { is_expected.to be_valid }

      context "when metadata has properties" do
        before do
          metadata.merge!({ "properties" => properties })
        end

        context "when properties are valid" do
          let(:properties) do
            [
              { "name" => "gitlab:dependency_scanning:input_file", "value" => "Gemfile.lock" },
              { "name" => "gitlab:dependency_scanning:package_manager", "value" => "bundler" }
            ]
          end

          it { is_expected.to be_valid }
        end

        context "when properties are invalid" do
          let(:properties) do
            [
              { "name" => ["gitlab:meta:schema_version"], "value" => 1 }
            ]
          end

          it { is_expected.not_to be_valid }

          it "outputs errors for each validation failure" do
            expect(validator.errors).to match_array(
              [
                "property '/metadata/properties/0/name' is not of type: string",
                "property '/metadata/properties/0/value' is not of type: string"
              ])
          end
        end
      end
    end
  end

  context 'when spec version is supported' do
    where(:spec_version) { %w[1.4 1.5 1.6] }

    with_them do
      it_behaves_like 'a validator that performs the expected validations'
    end
  end

  context 'when spec version is not supported' do
    let(:spec_version) { '1.3' }

    it { is_expected.not_to be_valid }
  end
end
