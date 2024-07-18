# frozen_string_literal: true

require_relative "../rd_fast_spec_helper"

RSpec.describe RemoteDevelopment::Settings::Main, :rd_fast, feature_category: :remote_development do
  let(:settings) { 'some settings' }
  let(:context_passed_along_steps) { { settings: settings } }

  let(:rop_steps) do
    [
      [RemoteDevelopment::Settings::SettingsInitializer, :map],
      [RemoteDevelopment::Settings::CurrentSettingsReader, :and_then],
      [Gitlab::Fp::Settings::EnvVarOverrideProcessor, :and_then],
      [RemoteDevelopment::Settings::ReconciliationIntervalSecondsValidator, :and_then]
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
          "when CurrentSettingsReader returns SettingsCurrentSettingsReadFailed",
          {
            step_class: RemoteDevelopment::Settings::CurrentSettingsReader,
            returned_message: lazy { RemoteDevelopment::Settings::Messages::SettingsCurrentSettingsReadFailed.new(err_message_content) }
          },
          {
            status: :error,
            message: lazy { "Settings current settings read failed: #{error_details}" },
            reason: :internal_server_error
          },
        ],
        [
          "when EnvVarOverrideProcessor returns SettingsEnvironmentVariableOverrideFailed",
          {
            step_class: Gitlab::Fp::Settings::EnvVarOverrideProcessor,
            returned_message:
              lazy do
                RemoteDevelopment::Settings::Messages::SettingsEnvironmentVariableOverrideFailed.new(
                  err_message_content
                )
              end
          },
          {
            status: :error,
            message: lazy { "Settings environment variable override failed: #{error_details}" },
            reason: :internal_server_error
          },
        ],
        [
          "when ReconciliationIntervalSecondsValidator returns SettingsPartialReconciliationIntervalSecondsValidationFailed",
          {
            step_class: RemoteDevelopment::Settings::ReconciliationIntervalSecondsValidator,
            returned_message: lazy { RemoteDevelopment::Settings::Messages::SettingsPartialReconciliationIntervalSecondsValidationFailed.new(err_message_content) }
          },
          {
            status: :error,
            message: lazy { "Settings partial reconciliation interval seconds validation failed: #{error_details}" },
            reason: :internal_server_error
          },
        ],
        [
          "when ReconciliationIntervalSecondsValidator returns SettingsFullReconciliationIntervalSecondsValidationFailed",
          {
            step_class: RemoteDevelopment::Settings::ReconciliationIntervalSecondsValidator,
            returned_message: lazy { RemoteDevelopment::Settings::Messages::SettingsFullReconciliationIntervalSecondsValidationFailed.new(err_message_content) }

          },
          {
            status: :error,
            message: lazy { "Settings full reconciliation interval seconds validation failed: #{error_details}" },
            reason: :internal_server_error
          },
        ],
        [
          "when ReconciliationIntervalSecondsValidator returns SettingsPartialReconciliationIntervalSecondsValidationFailed",
          {
            step_class: RemoteDevelopment::Settings::ReconciliationIntervalSecondsValidator,
            returned_message: lazy { RemoteDevelopment::Settings::Messages::SettingsPartialReconciliationIntervalSecondsValidationFailed.new(err_message_content) }
          },
          {
            status: :error,
            message: lazy { "Settings partial reconciliation interval seconds validation failed: #{error_details}" },
            reason: :internal_server_error
          },
        ],
        [
          "when an unmatched error is returned, an exception is raised",
          {
            step_class: RemoteDevelopment::Settings::CurrentSettingsReader,
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
