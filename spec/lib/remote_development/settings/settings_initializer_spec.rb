# frozen_string_literal: true

require_relative "../rd_fast_spec_helper"

RSpec.describe RemoteDevelopment::Settings::SettingsInitializer,
  :rd_fast, feature_category: :remote_development do
  let(:all_possible_requested_setting_names) { RemoteDevelopment::Settings::DefaultSettings.default_settings.keys }
  let(:requested_setting_names) { all_possible_requested_setting_names }
  let(:context) do
    { requested_setting_names: requested_setting_names }
  end

  subject(:returned_value) do
    described_class.init(context)
  end

  it "invokes DefaultSettingsParser and sets up necessary values in context for subsequent steps" do
    expect(returned_value).to match(
      {
        requested_setting_names: [
          :default_branch_name,
          :default_max_hours_before_termination,
          :max_hours_before_termination_limit,
          :project_cloner_image,
          :tools_injector_image,
          :full_reconciliation_interval_seconds,
          :partial_reconciliation_interval_seconds
        ],
        settings: hash_including(default_max_hours_before_termination: 24),
        setting_types: {
          default_branch_name: String,
          default_max_hours_before_termination: Integer,
          full_reconciliation_interval_seconds: Integer,
          max_hours_before_termination_limit: Integer,
          partial_reconciliation_interval_seconds: Integer,
          project_cloner_image: String,
          tools_injector_image: String
        },
        env_var_prefix: "GITLAB_REMOTE_DEVELOPMENT",
        env_var_failed_message_class: RemoteDevelopment::Settings::Messages::SettingsEnvironmentVariableOverrideFailed
      }
    )
  end

  context "when mutually dependent settings are not all specified" do
    context "for full_reconciliation_interval_seconds and partial_reconciliation_interval_seconds" do
      let(:requested_setting_names) { [:full_reconciliation_interval_seconds] }

      it "raises a descriptive exception" do
        expect { returned_value }.to raise_error(
          /full_reconciliation_interval_seconds and partial_reconciliation_interval_seconds.*mutually dependent/
        )
      end
    end
  end
end
