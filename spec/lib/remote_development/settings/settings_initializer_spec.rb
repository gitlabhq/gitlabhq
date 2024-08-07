# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe RemoteDevelopment::Settings::SettingsInitializer,
  feature_category: :remote_development do
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
          :partial_reconciliation_interval_seconds,
          :workspaces_quota,
          :workspaces_per_user_quota,
          :network_policy_egress,
          :default_resources_per_workspace_container,
          :max_resources_per_workspace,
          :gitlab_workspaces_proxy_namespace,
          :network_policy_enabled
        ],
        settings: {
          default_branch_name: nil,
          default_max_hours_before_termination: 24,
          max_hours_before_termination_limit: 120,
          project_cloner_image: 'alpine/git:2.36.3',
          tools_injector_image: 'registry.gitlab.com/gitlab-org/remote-development/gitlab-workspaces-tools:2.0.0',
          full_reconciliation_interval_seconds: 3600,
          partial_reconciliation_interval_seconds: 10,
          workspaces_quota: -1,
          workspaces_per_user_quota: -1,
          network_policy_egress: [{
            allow: "0.0.0.0/0",
            except: %w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16]
          }],
          default_resources_per_workspace_container: {},
          max_resources_per_workspace: {},
          gitlab_workspaces_proxy_namespace: {},
          network_policy_enabled: true
        },
        setting_types: {
          default_branch_name: String,
          default_max_hours_before_termination: Integer,
          full_reconciliation_interval_seconds: Integer,
          max_hours_before_termination_limit: Integer,
          partial_reconciliation_interval_seconds: Integer,
          project_cloner_image: String,
          tools_injector_image: String,
          workspaces_quota: Integer,
          workspaces_per_user_quota: Integer,
          network_policy_egress: Array,
          default_resources_per_workspace_container: Hash,
          max_resources_per_workspace: Hash,
          gitlab_workspaces_proxy_namespace: Hash,
          network_policy_enabled: Object
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
