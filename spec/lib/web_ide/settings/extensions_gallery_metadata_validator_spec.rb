# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe WebIde::Settings::ExtensionsGalleryMetadataValidator, feature_category: :web_ide do
  include ResultMatchers

  let(:context) do
    {
      requested_setting_names: [:vscode_extensions_gallery_metadata],
      settings: {
        vscode_extensions_gallery_metadata: extensions_gallery_metadata
      }
    }
  end

  subject(:result) do
    described_class.validate(context)
  end

  context "when vscode_extensions_gallery_metadata is valid" do
    shared_examples "success result" do
      it "return an ok Result containing the original context which was passed" do
        expect(result).to eq(Gitlab::Fp::Result.ok(context))
      end
    end

    context "when enabled is true" do
      let(:extensions_gallery_metadata) do
        {
          enabled: true
        }
      end

      it_behaves_like 'success result'
    end

    context "when enabled is false and disabled_reason is present" do
      let(:extensions_gallery_metadata) do
        {
          enabled: false,
          disabled_reason: :no_user
        }
      end

      it_behaves_like 'success result'
    end
  end

  context "when vscode_extensions_gallery_metadata is invalid" do
    shared_examples "err result" do |expected_error_details:|
      it "returns an err Result containing error details" do
        expect(result).to be_err_result do |message|
          expect(message)
            .to be_a(WebIde::Settings::Messages::SettingsVscodeExtensionsGalleryMetadataValidationFailed)
          message.content => { details: String => error_details }
          expect(error_details).to eq(expected_error_details)
        end
      end
    end

    context "when empty" do
      let(:extensions_gallery_metadata) { {} }

      it_behaves_like "err result", expected_error_details: "root is missing required keys: enabled"
    end

    context "when enabled is missing but disabled_reason is present" do
      let(:extensions_gallery_metadata) { { disabled_reason: :no_user } }

      it_behaves_like "err result", expected_error_details: "root is missing required keys: enabled"
    end

    context "when enabled is false but disabled_reason is missing" do
      let(:extensions_gallery_metadata) do
        {
          enabled: false
        }
      end

      it_behaves_like "err result", expected_error_details: "root is missing required keys: disabled_reason"
    end

    context "for enabled" do
      context "when not a boolean" do
        let(:extensions_gallery_metadata) do
          {
            enabled: "not a boolean"
          }
        end

        it_behaves_like "err result", expected_error_details: "property '/enabled' is not of type: boolean"
      end
    end

    context "for disabled_reason" do
      context "when not a string" do
        let(:extensions_gallery_metadata) do
          {
            enabled: false,
            disabled_reason: 1
          }
        end

        it_behaves_like "err result", expected_error_details:
          "property '/disabled_reason' is not of type: string"
      end
    end
  end

  context "when requested_setting_names does not include vscode_extensions_gallery_metadata" do
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
