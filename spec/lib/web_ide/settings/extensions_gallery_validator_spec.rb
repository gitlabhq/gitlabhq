# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe WebIde::Settings::ExtensionsGalleryValidator, feature_category: :web_ide do
  include ResultMatchers

  let(:service_url) { "https://open-vsx.org/vscode/gallery" }
  let(:item_url) { "https://open-vsx.org/vscode/item" }
  let(:resource_url_template) { "https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}" }
  let(:vscode_extensions_gallery) do
    {
      service_url: service_url,
      item_url: item_url,
      resource_url_template: resource_url_template,
      control_url: "",
      nls_base_url: "",
      publisher_url: ""
    }
  end

  let(:requested_setting_names) { [:vscode_extensions_gallery] }
  let(:context) do
    {
      requested_setting_names: requested_setting_names,
      settings: {
        vscode_extensions_gallery: vscode_extensions_gallery
      }
    }
  end

  subject(:result) do
    described_class.validate(context)
  end

  context "when vscode_extensions_gallery is valid" do
    shared_examples "success result" do
      it "return an ok Result containing the original context which was passed" do
        expect(result).to eq(Gitlab::Fp::Result.ok(context))
      end
    end

    context "when all settings are present" do
      it_behaves_like 'success result'
    end

    context "when only :vscode_extensions_gallery_metadata is requested" do
      let(:requested_setting_names) { [:vscode_extensions_gallery_metadata] }

      it_behaves_like 'success result'
    end
  end

  context "when vscode_extensions_gallery is invalid" do
    shared_examples "err result" do |expected_error_details:|
      it "returns an err Result containing error details" do
        expect(result).to be_err_result do |message|
          expect(message).to be_a WebIde::Settings::Messages::SettingsVscodeExtensionsGalleryValidationFailed
          message.content => { details: String => error_details }
          expect(error_details).to eq(expected_error_details)
        end
      end
    end

    context "when missing required entries" do
      let(:vscode_extensions_gallery) { {} }

      it_behaves_like "err result", expected_error_details:
        "root is missing required keys: service_url, item_url, resource_url_template"
    end

    context "for service_url" do
      context "when not a string" do
        let(:service_url) { { not_a_string: true } }

        it_behaves_like "err result", expected_error_details: "property '/service_url' is not of type: string"
      end
    end

    context "for item_url" do
      context "when not a string" do
        let(:item_url) { { not_a_string: true } }

        it_behaves_like "err result", expected_error_details: "property '/item_url' is not of type: string"
      end
    end

    context "for resource_url_template" do
      context "when not a string" do
        let(:resource_url_template) { { not_a_string: true } }

        it_behaves_like "err result", expected_error_details: "property '/resource_url_template' is not of type: string"
      end
    end
  end

  context "when requested_setting_names does not include relevant settings" do
    let(:context) do
      {
        requested_setting_names: [:some_other_setting]
      }
    end

    it "returns an ok result with the original context" do
      expect(result).to be_ok_result(context)
    end
  end
end
