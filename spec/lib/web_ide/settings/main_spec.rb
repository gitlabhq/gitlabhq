# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe WebIde::Settings::Main, feature_category: :web_ide do
  let(:settings) { 'some settings' }
  let(:context_passed_along_steps) { { settings: settings } }

  let(:rop_steps) do
    [
      [WebIde::Settings::SettingsInitializer, :map],
      [WebIde::Settings::ExtensionsGalleryMetadataGenerator, :map],
      [Gitlab::Fp::Settings::EnvVarOverrideProcessor, :and_then],
      [WebIde::Settings::ExtensionsGalleryValidator, :and_then],
      [WebIde::Settings::ExtensionsGalleryMetadataValidator, :and_then],
      [WebIde::Settings::ExtensionsGalleryViewModelGenerator, :map]
    ]
  end

  describe "happy path" do
    let(:expected_response) do
      {
        status: :success,
        settings: settings
      }
    end

    it "returns expected response" do
      # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
      expect do
        described_class.get_settings(context_passed_along_steps)
      end
        .to invoke_rop_steps(rop_steps)
              .from_main_class(described_class)
              .with_context_passed_along_steps(context_passed_along_steps)
              .and_return_expected_value(expected_response)
    end
  end

  describe "error cases" do
    let(:error_details) { "some error details" }
    let(:err_message_content) { { details: error_details } }

    shared_examples "rop invocation with error response" do
      it "returns expected response" do
        # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
        expect do
          described_class.get_settings(context_passed_along_steps)
        end
          .to invoke_rop_steps(rop_steps)
                .from_main_class(described_class)
                .with_context_passed_along_steps(context_passed_along_steps)
                .with_err_result_for_step(err_result_for_step)
                .and_return_expected_value(expected_response)
      end
    end

    # rubocop:disable Style/TrailingCommaInArrayLiteral -- let the last element have a comma for simpler diffs
    # rubocop:disable Layout/LineLength -- we want to avoid excessive wrapping for RSpec::Parameterized Nested Array Style so we can have formatting consistency between entries
    where(:case_name, :err_result_for_step, :expected_response) do
      [
        [
          "when ExtensionsGalleryValidator returns SettingsVscodeExtensionsGalleryValidationFailed",
          {
            step_class: WebIde::Settings::ExtensionsGalleryValidator,
            returned_message: lazy { WebIde::Settings::Messages::SettingsVscodeExtensionsGalleryValidationFailed.new(err_message_content) }
          },
          {
            status: :error,
            message: lazy { "Settings VSCode extensions gallery validation failed: #{error_details}" },
            reason: :internal_server_error
          },
        ],
        [
          "when ExtensionsGalleryMetadataValidator returns SettingsVscodeExtensionsGalleryMetadataValidationFailed",
          {
            step_class: WebIde::Settings::ExtensionsGalleryMetadataValidator,
            returned_message: lazy { WebIde::Settings::Messages::SettingsVscodeExtensionsGalleryMetadataValidationFailed.new(err_message_content) }
          },
          {
            status: :error,
            message: lazy { "Settings VSCode extensions gallery metadata validation failed: #{error_details}" },
            reason: :internal_server_error
          },
        ],
        [
          "when EnvVarOverrideProcessor returns SettingsEnvironmentVariableOverrideFailed",
          {
            step_class: Gitlab::Fp::Settings::EnvVarOverrideProcessor,
            returned_message:
              lazy { WebIde::Settings::Messages::SettingsEnvironmentVariableOverrideFailed.new(err_message_content) }
          },
          {
            status: :error,
            message: lazy { "Settings environment variable override failed: #{error_details}" },
            reason: :internal_server_error
          },
        ],
        [
          "when an unmatched error is returned, an exception is raised",
          {
            step_class: WebIde::Settings::ExtensionsGalleryValidator,
            returned_message: lazy { Class.new(Gitlab::Fp::Message).new(err_message_content) }
          },
          Gitlab::Fp::UnmatchedResultError
        ],
      ]
    end
    # rubocop:enable Style/TrailingCommaInArrayLiteral
    # rubocop:enable Layout/LineLength

    with_them do
      it_behaves_like "rop invocation with error response"
    end
  end
end
