# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ParameterFilters::SamlResponse, feature_category: :system_access do
  let(:mock_saml_response) { File.read('spec/fixtures/authentication/saml_response.xml') }

  describe "filter sensitive values" do
    let(:log_saml_values) do
      described_class.log(mock_saml_response)
    end

    it "lists the non sensitive attributes" do
      expect(Gitlab::AuthLogger).to receive(:info).with(payload_type: 'saml_response', saml_response: {
        allowed_clock_drift: 2.220446049250313e-16,
        assertion_encrypted: false,
        assertion_id: "_d71a3a8e9fcc45c9e9d248ef7049393fc8f04e5f75",
        attributes: { "eduPersonAffiliation" => %w[users examplerole1], "mail" => ["test@example.com"],
                      "uid" => ["test"] },
        audiences: ["http://sp.example.com/demo1/metadata.php"],
        destination: "http://sp.example.com/demo1/index.php?acs",
        in_response_to: "ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685",
        issuer: ["http://idp.example.com/metadata.php"],
        name_id: "_ce3d2948b4cf20146dee0a0b3dd6f69b6cf86f62d7",
        name_id_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:transient",
        name_id_namequalifier: nil,
        name_id_spnamequalifier: "http://sp.example.com/demo1/metadata.php",
        response_id: "pfxb9b71715-2202-9a51-8ae5-689d5b9dd25a",
        session_index: "_be9967abd904ddcae3c0eb4189adbe3f71e327cf93",
        status_code: "urn:oasis:names:tc:SAML:2.0:status:Success",
        status_message: nil,
        success: true
      })

      log_saml_values
    end

    context "with malformed data" do
      let(:mock_saml_response) { '<abc' }

      it "returns error message" do
        expect(Gitlab::AuthLogger).to receive(:error).with(payload_type: 'saml_response', error: anything)

        log_saml_values
      end
    end
  end
end
