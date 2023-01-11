# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Ci::Parsers::Sbom::Validators::CyclonedxSchemaValidator,
  feature_category: :dependency_management do
  # Reports should be valid or invalid according to the specification at
  # https://cyclonedx.org/docs/1.4/json/

  subject(:validator) { described_class.new(report_data) }

  let_it_be(:required_attributes) do
    {
      "bomFormat" => "CycloneDX",
      "specVersion" => "1.4",
      "version" => 1
    }
  end

  context "with minimally valid report" do
    let_it_be(:report_data) { required_attributes }

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
            "property '/components/0/type' is not one of: [\"application\", \"framework\"," \
              " \"library\", \"container\", \"operating-system\", \"device\", \"firmware\", \"file\"]",
            "property '/components/1' is missing required keys: type"
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
