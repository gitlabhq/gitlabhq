# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageData, :aggregate_failures, feature_category: :service_ping do
  include UsageDataHelpers

  before do
    stub_usage_data_connections
    stub_object_store_settings
    clear_memoized_values(described_class::CE_MEMOIZED_VALUES)
    stub_database_flavor_check('Cloud SQL for PostgreSQL')
  end

  describe '.data' do
    subject { described_class.data }

    it 'includes basic top and second level keys' do
      is_expected.to include(:counts)
      is_expected.to include(:counts_weekly)
      is_expected.to include(:license)

      # usage_activity_by_stage data
      is_expected.to include(:usage_activity_by_stage)
      is_expected.to include(:usage_activity_by_stage_monthly)
      expect(subject[:usage_activity_by_stage])
        .to include(:configure, :create, :manage, :monitor, :plan, :release, :verify)
      expect(subject[:usage_activity_by_stage_monthly])
        .to include(:configure, :create, :manage, :monitor, :plan, :release, :verify)
      expect(subject[:usage_activity_by_stage_monthly][:create])
        .to include(:snippets)
    end

    it 'clears memoized values' do
      allow(described_class).to receive(:clear_memoization)

      subject

      described_class::CE_MEMOIZED_VALUES.each do |key|
        expect(described_class).to have_received(:clear_memoization).with(key)
      end
    end

    it 'ensures recorded_at is set before any other usage data calculation' do
      %i[alt_usage_data redis_usage_data distinct_count count].each do |method|
        expect(described_class).not_to receive(method)
      end
      expect(described_class).to receive(:recorded_at).and_raise(Exception.new('Stopped calculating recorded_at'))

      expect { subject }.to raise_error('Stopped calculating recorded_at')
    end

    context 'when generating usage ping in critical weeks' do
      it 'does not raise error when generated in last week of the year' do
        travel_to(DateTime.parse('2020-12-29')) do
          expect { subject }.not_to raise_error
        end
      end

      it 'does not raise error when generated in first week of the year' do
        travel_to(DateTime.parse('2021-01-01')) do
          expect { subject }.not_to raise_error
        end
      end

      it 'does not raise error when generated in second week of the year' do
        travel_to(DateTime.parse('2021-01-07')) do
          expect { subject }.not_to raise_error
        end
      end

      it 'does not raise error when generated in 3rd week of the year' do
        travel_to(DateTime.parse('2021-01-14')) do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe 'usage_activity_by_stage_package' do
    it 'includes accurate usage_activity_by_stage data' do
      for_defined_days_back do
        create(:project, packages: [create(:generic_package)])
      end

      expect(described_class.usage_activity_by_stage_package({})).to eq(
        projects_with_packages: 2
      )
      expect(described_class.usage_activity_by_stage_package(described_class.monthly_time_range_db_params)).to eq(
        projects_with_packages: 1
      )
    end
  end

  describe '.usage_activity_by_stage_configure' do
    it 'includes accurate usage_activity_by_stage data' do
      for_defined_days_back do
        user = create(:user)
        project = create(:project, creator: user)
        create(:cluster, user: user)
        create(:cluster, :disabled, user: user)
        create(:cluster_provider_gcp, :created)
        create(:cluster_provider_aws, :created)
        create(:cluster_platform_kubernetes)
        create(:cluster, :group, :disabled, user: user)
        create(:cluster, :group, user: user)
        create(:cluster, :instance, :disabled, :production_environment)
        create(:cluster, :instance, :production_environment)
        create(:cluster, :management_project)
        create(:integrations_slack, project: project)
        create(:slack_slash_commands_integration, project: project)
        create(:prometheus_integration, project: project)
      end

      expect(described_class.usage_activity_by_stage_configure({})).to include(
        clusters_management_project: 2,
        clusters_disabled: 4,
        clusters_enabled: 12,
        clusters_platforms_gke: 2,
        clusters_platforms_eks: 2,
        clusters_platforms_user: 2,
        instance_clusters_disabled: 2,
        instance_clusters_enabled: 2,
        group_clusters_disabled: 2,
        group_clusters_enabled: 2,
        project_clusters_disabled: 2,
        project_clusters_enabled: 10,
        projects_slack_notifications_active: 2,
        projects_slack_slash_active: 2
      )
      expect(described_class.usage_activity_by_stage_configure(described_class.monthly_time_range_db_params)).to include(
        clusters_management_project: 1,
        clusters_disabled: 2,
        clusters_enabled: 6,
        clusters_platforms_gke: 1,
        clusters_platforms_eks: 1,
        clusters_platforms_user: 1,
        instance_clusters_disabled: 1,
        instance_clusters_enabled: 1,
        group_clusters_disabled: 1,
        group_clusters_enabled: 1,
        project_clusters_disabled: 1,
        project_clusters_enabled: 5,
        projects_slack_notifications_active: 1,
        projects_slack_slash_active: 1
      )
    end
  end

  describe 'usage_activity_by_stage_create' do
    it 'includes accurate usage_activity_by_stage data' do
      for_defined_days_back do
        user = create(:user)
        project = create(:project, :repository_private, :test_repo, :remote_mirror, creator: user)
        create(:merge_request, source_project: project)
        create(:deploy_key, user: user)
        create(:key, user: user)
        create(:project, creator: user, disable_overriding_approvers_per_merge_request: true)
        create(:project, creator: user, disable_overriding_approvers_per_merge_request: false)
        create(:remote_mirror, project: project, enabled: true)
        another_user = create(:user)
        another_project = create(:project, :repository, creator: another_user)
        create(:remote_mirror, project: another_project, enabled: false)
        create(:personal_snippet, author: user)
      end

      expect(described_class.usage_activity_by_stage_create({})).to include(
        deploy_keys: 2,
        keys: 2,
        projects_with_disable_overriding_approvers_per_merge_request: 2,
        projects_without_disable_overriding_approvers_per_merge_request: 6,
        remote_mirrors: 2,
        snippets: 2
      )
      expect(described_class.usage_activity_by_stage_create(described_class.monthly_time_range_db_params)).to include(
        deploy_keys: 1,
        keys: 1,
        projects_with_disable_overriding_approvers_per_merge_request: 1,
        projects_without_disable_overriding_approvers_per_merge_request: 3,
        remote_mirrors: 1,
        snippets: 1
      )
    end
  end

  describe 'usage_activity_by_stage_manage' do
    let_it_be(:error_rate) { Gitlab::Database::PostgresHll::BatchDistinctCounter::ERROR_RATE }

    it 'includes accurate usage_activity_by_stage data' do
      stub_config(
        omniauth:
          { providers: omniauth_providers }
      )
      allow(Devise).to receive(:omniauth_providers).and_return(%w[ldapmain ldapsecondary group_saml])

      for_defined_days_back do
        user = create(:user)
        user2 = create(:user)
        create(:group_member, user: user)
        create(:authentication_event, user: user, provider: :ldapmain, result: :success)
        create(:authentication_event, user: user2, provider: :ldapsecondary, result: :success)
        create(:authentication_event, user: user2, provider: :group_saml, result: :success)
        create(:authentication_event, user: user2, provider: :group_saml, result: :success)
        create(:authentication_event, user: user, provider: :group_saml, result: :failed)
      end

      for_defined_days_back(days: [31, 29, 3]) do
        create(:event)
      end

      stub_const('Gitlab::Database::PostgresHll::BatchDistinctCounter::DEFAULT_BATCH_SIZE', 1)
      stub_const('Gitlab::Database::PostgresHll::BatchDistinctCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      expect(described_class.usage_activity_by_stage_manage({})).to include(
        events: -1,
        groups: 2,
        users_created: 10,
        omniauth_providers: ['google_oauth2'],
        user_auth_by_provider: {
          'group_saml' => 2,
          'ldap' => 4,
          'standard' => 0,
          'two-factor' => 0,
          'two-factor-via-u2f-device' => 0,
          "two-factor-via-webauthn-device" => 0
        }
      )
      expect(described_class.usage_activity_by_stage_manage(described_class.monthly_time_range_db_params)).to include(
        events: be_within(error_rate).percent_of(2),
        groups: 1,
        users_created: 6,
        omniauth_providers: ['google_oauth2'],
        user_auth_by_provider: {
          'group_saml' => 1,
          'ldap' => 2,
          'standard' => 0,
          'two-factor' => 0,
          'two-factor-via-u2f-device' => 0,
          "two-factor-via-webauthn-device" => 0
        }
      )
    end

    it 'includes imports usage data', :clean_gitlab_redis_cache do
      for_defined_days_back do
        user = create(:user)

        %w[gitlab_project github bitbucket bitbucket_server gitea git manifest fogbugz].each do |type|
          create(:project, import_type: type, creator_id: user.id)
        end

        jira_project = create(:project, creator_id: user.id)
        create(:jira_import_state, :finished, project: jira_project)

        create(:issue_csv_import, user: user)

        group = create(:group)
        group.add_owner(user)
        create(:group_import_state, group: group, user: user)

        bulk_import = create(:bulk_import, user: user)
        create(:bulk_import_entity, :group_entity, bulk_import: bulk_import)
        create(:bulk_import_entity, :project_entity, bulk_import: bulk_import)
      end

      expect(described_class.usage_activity_by_stage_manage({})).to include(
        {
          bulk_imports: {
            gitlab_v1: 2
          },
          group_imports: {
            group_import: 2,
            gitlab_migration: 2
          }
        }
      )
      expect(described_class.usage_activity_by_stage_manage(described_class.monthly_time_range_db_params)).to include(
        {
          bulk_imports: {
            gitlab_v1: 1
          },
          group_imports: {
            group_import: 1,
            gitlab_migration: 1
          }
        }
      )
    end

    def omniauth_providers
      [
        double('provider', name: 'google_oauth2'),
        double('provider', name: 'ldapmain'),
        double('provider', name: 'group_saml')
      ]
    end
  end

  describe 'usage_activity_by_stage_monitor' do
    it 'includes accurate usage_activity_by_stage data' do
      for_defined_days_back do
        user = create(:user, dashboard: 'operations')
        cluster = create(:cluster, user: user)
        project = create(:project, creator: user)
        create(:clusters_integrations_prometheus, cluster: cluster)
        create(:project_error_tracking_setting)
        create(:incident)
        create(:incident, alert_management_alert: create(:alert_management_alert))
        create(:issue, alert_management_alert: create(:alert_management_alert))
        create(:alert_management_http_integration, :active, project: project)
      end

      expect(described_class.usage_activity_by_stage_monitor({})).to include(
        clusters: 2,
        clusters_integrations_prometheus: 2,
        operations_dashboard_default_dashboard: 2,
        projects_with_error_tracking_enabled: 2,
        projects_with_incidents: 4,
        projects_with_alert_incidents: 4,
        projects_with_enabled_alert_integrations_histogram: { '1' => 2 }
      )

      data_28_days = described_class.usage_activity_by_stage_monitor(described_class.monthly_time_range_db_params)
      expect(data_28_days).to include(
        clusters: 1,
        clusters_integrations_prometheus: 1,
        operations_dashboard_default_dashboard: 1,
        projects_with_error_tracking_enabled: 1,
        projects_with_incidents: 2,
        projects_with_alert_incidents: 2
      )

      expect(data_28_days).not_to include(:projects_with_enabled_alert_integrations_histogram)
    end
  end

  describe 'usage_activity_by_stage_plan' do
    it 'includes accurate usage_activity_by_stage data' do
      for_defined_days_back do
        user = create(:user)
        project = create(:project, creator: user)
        issue = create(:issue, project: project, author: user)
        create(:issue, project: project, author: Users::Internal.support_bot)
        create(:note, project: project, noteable: issue, author: user)
        create(:todo, project: project, target: issue, author: user)
        create(:jira_integration, active: true, project: create(:project, :jira_dvcs_server, creator: user))
      end

      expect(described_class.usage_activity_by_stage_plan({})).to include(
        notes: 2,
        projects: 2,
        todos: 2,
        service_desk_enabled_projects: 2,
        service_desk_issues: 2,
        projects_jira_active: 2,
        projects_jira_dvcs_server_active: 2
      )
      expect(described_class.usage_activity_by_stage_plan(described_class.monthly_time_range_db_params)).to include(
        notes: 1,
        projects: 1,
        todos: 1,
        service_desk_enabled_projects: 1,
        service_desk_issues: 1,
        projects_jira_active: 1,
        projects_jira_dvcs_server_active: 1
      )
    end

    it 'does not merge the data from instrumentation classes' do
      for_defined_days_back do
        user = create(:user)
        project = create(:project, creator: user)
        create(:issue, project: project, author: user)
        create(:issue, project: project, author: Users::Internal.support_bot)
      end

      expect(described_class.usage_activity_by_stage_plan({})).to include(issues: 3)
      expect(described_class.usage_activity_by_stage_plan(described_class.monthly_time_range_db_params)).to include(issues: 2)
    end
  end

  describe 'usage_activity_by_stage_release' do
    it 'includes accurate usage_activity_by_stage data' do
      for_defined_days_back do
        user = create(:user)
        create(:deployment, :failed, user: user)
        release = create(:release, author: user)
        create(:milestone, project: release.project, releases: [release])
        create(:deployment, :success, user: user)
      end

      expect(described_class.usage_activity_by_stage_release({})).to include(
        deployments: 2,
        failed_deployments: 2,
        releases: 2,
        successful_deployments: 2,
        releases_with_milestones: 2
      )
      expect(described_class.usage_activity_by_stage_release(described_class.monthly_time_range_db_params)).to include(
        deployments: 1,
        failed_deployments: 1,
        releases: 1,
        successful_deployments: 1,
        releases_with_milestones: 1
      )
    end
  end

  describe 'usage_activity_by_stage_verify' do
    it 'includes accurate usage_activity_by_stage data' do
      for_defined_days_back do
        user = create(:user)
        create(:ci_build, user: user)
        create(:ci_empty_pipeline, source: :external, user: user)
        create(:ci_empty_pipeline, user: user)
        create(:ci_pipeline, :auto_devops_source, user: user)
        create(:ci_pipeline, :repository_source, user: user)
        create(:ci_pipeline_schedule, owner: user)
        create(:ci_trigger, owner: user)
      end

      expect(described_class.usage_activity_by_stage_verify({})).to include(
        ci_builds: 2,
        ci_external_pipelines: 2,
        ci_internal_pipelines: 2,
        ci_pipeline_config_auto_devops: 2,
        ci_pipeline_config_repository: 2,
        ci_pipeline_schedules: 2,
        ci_pipelines: 2,
        ci_triggers: 2
      )
      expect(described_class.usage_activity_by_stage_verify(described_class.monthly_time_range_db_params)).to include(
        ci_builds: 1,
        ci_external_pipelines: 1,
        ci_internal_pipelines: 1,
        ci_pipeline_config_auto_devops: 1,
        ci_pipeline_config_repository: 1,
        ci_pipeline_schedules: 1,
        ci_pipelines: 1,
        ci_triggers: 1
      )
    end
  end

  describe '.data' do
    let!(:ud) { build(:usage_data) }

    subject { described_class.data }

    it 'gathers usage data' do
      expect(subject.keys).to include(*UsageDataHelpers::USAGE_DATA_KEYS)
    end

    it 'gathers usage counts', :aggregate_failures do
      count_data = subject[:counts]
      expect(count_data[:projects]).to eq(4)
      expect(count_data.keys).to include(*UsageDataHelpers::COUNTS_KEYS)
      expect(UsageDataHelpers::COUNTS_KEYS - count_data.keys).to be_empty
      expect(count_data.values).to all(be_a_kind_of(Integer))
    end

    it 'gathers usage counts correctly' do
      count_data = subject[:counts]

      expect(count_data[:projects]).to eq(4)
      expect(count_data[:projects_asana_active]).to eq(0)
      expect(count_data[:projects_prometheus_active]).to eq(1)
      expect(count_data[:projects_jenkins_active]).to eq(1)
      expect(count_data[:projects_jira_active]).to eq(4)
      expect(count_data[:jira_imports_projects_count]).to eq(2)
      expect(count_data[:jira_imports_total_imported_count]).to eq(3)
      expect(count_data[:jira_imports_total_imported_issues_count]).to eq(13)
      expect(count_data[:projects_slack_active]).to eq(2)
      expect(count_data[:projects_slack_slash_commands_active]).to eq(1)
      expect(count_data[:projects_custom_issue_tracker_active]).to eq(1)
      expect(count_data[:projects_mattermost_active]).to eq(1)
      expect(count_data[:groups_mattermost_active]).to eq(1)
      expect(count_data[:instances_mattermost_active]).to eq(1)
      expect(count_data[:projects_inheriting_mattermost_active]).to eq(1)
      expect(count_data[:groups_inheriting_slack_active]).to eq(1)
      expect(count_data[:projects_with_repositories_enabled]).to eq(3)
      expect(count_data[:projects_with_error_tracking_enabled]).to eq(1)
      expect(count_data[:projects_with_enabled_alert_integrations]).to eq(1)
      expect(count_data[:projects_with_terraform_reports]).to eq(2)
      expect(count_data[:projects_with_terraform_states]).to eq(2)
      expect(count_data[:protected_branches]).to eq(2)
      expect(count_data[:protected_branches_except_default]).to eq(1)
      expect(count_data[:terraform_reports]).to eq(6)
      expect(count_data[:terraform_states]).to eq(3)
      expect(count_data[:issues_created_from_gitlab_error_tracking_ui]).to eq(1)
      expect(count_data[:issues_with_associated_zoom_link]).to eq(2)
      expect(count_data[:issues_using_zoom_quick_actions]).to eq(3)
      expect(count_data[:incident_issues]).to eq(4)
      expect(count_data[:alert_bot_incident_issues]).to eq(4)
      expect(count_data[:clusters_enabled]).to eq(6)
      expect(count_data[:project_clusters_enabled]).to eq(4)
      expect(count_data[:group_clusters_enabled]).to eq(1)
      expect(count_data[:instance_clusters_enabled]).to eq(1)
      expect(count_data[:clusters_disabled]).to eq(3)
      expect(count_data[:project_clusters_disabled]).to eq(1)
      expect(count_data[:group_clusters_disabled]).to eq(1)
      expect(count_data[:instance_clusters_disabled]).to eq(1)
      expect(count_data[:clusters_platforms_eks]).to eq(1)
      expect(count_data[:clusters_platforms_gke]).to eq(1)
      expect(count_data[:clusters_platforms_user]).to eq(1)
      expect(count_data[:clusters_integrations_prometheus]).to eq(1)
      expect(count_data[:clusters_management_project]).to eq(1)
      expect(count_data[:kubernetes_agents]).to eq(2)
      expect(count_data[:kubernetes_agents_with_token]).to eq(1)

      expect(count_data[:feature_flags]).to eq(1)

      expect(count_data[:projects_creating_incidents]).to eq(2)
      expect(count_data[:projects_with_packages]).to eq(2)
      expect(count_data[:packages]).to eq(4)
      expect(count_data[:user_preferences_user_gitpod_enabled]).to eq(1)
    end

    it 'gathers object store usage correctly' do
      expect(subject[:object_store]).to eq(
        { artifacts: { enabled: true, object_store: { enabled: true, direct_upload: true, background_upload: false, provider: "AWS" } },
          external_diffs: { enabled: false },
          lfs: { enabled: true, object_store: { enabled: false, direct_upload: true, background_upload: false, provider: "AWS" } },
          uploads: { enabled: nil, object_store: { enabled: false, direct_upload: true, background_upload: false, provider: "AWS" } },
          packages: { enabled: true, object_store: { enabled: false, direct_upload: false, background_upload: false, provider: "AWS" } } }
      )
    end

    context 'when queries time out' do
      let(:metric_method) { :count }

      before do
        allow_any_instance_of(ActiveRecord::Relation).to receive(metric_method).and_raise(ActiveRecord::StatementInvalid)
        allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(should_raise_for_dev)
      end

      context 'with should_raise_for_dev? true' do
        let(:should_raise_for_dev) { true }

        it 'raises an error' do
          expect { subject }.to raise_error(ActiveRecord::StatementInvalid)
        end
      end

      context 'with should_raise_for_dev? false' do
        let(:should_raise_for_dev) { false }

        it 'does not raise an error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    it 'includes a recording_ce_finished_at timestamp' do
      expect(subject[:recording_ce_finished_at]).to be_a(Time)
    end
  end

  context 'when not relying on database records' do
    describe '.components_usage_data' do
      subject { described_class.components_usage_data }

      it 'gathers basic components usage data' do
        stub_application_setting(container_registry_vendor: 'gitlab', container_registry_version: 'x.y.z')

        expect(subject[:gitlab_pages][:enabled]).to eq(Gitlab.config.pages.enabled)
        expect(subject[:gitlab_pages][:version]).to eq(Gitlab::Pages::VERSION)
        expect(subject[:git][:version]).to eq(Gitlab::Git.version)
        expect(subject[:database][:adapter]).to eq(ApplicationRecord.database.adapter_name)
        expect(subject[:database][:version]).to eq(ApplicationRecord.database.version)
        expect(subject[:database][:pg_system_id]).to eq(ApplicationRecord.database.system_id)
        expect(subject[:database][:flavor]).to eq('Cloud SQL for PostgreSQL')
        expect(subject[:mail][:smtp_server]).to eq(ActionMailer::Base.smtp_settings[:address])
        expect(subject[:gitaly][:version]).to be_present
        expect(subject[:gitaly][:servers]).to be >= 1
        expect(subject[:gitaly][:clusters]).to be >= 0
        expect(subject[:gitaly][:filesystems]).to be_an(Array)
        expect(subject[:gitaly][:filesystems].first).to be_a(String)
        expect(subject[:container_registry_server][:vendor]).to eq('gitlab')
        expect(subject[:container_registry_server][:version]).to eq('x.y.z')
      end
    end

    describe '.object_store_config' do
      let(:component) { 'lfs' }

      subject { described_class.object_store_config(component) }

      context 'when object_store is not configured' do
        it 'returns component enable status only' do
          allow(Settings).to receive(:[]).with(component).and_return({ 'enabled' => false })

          expect(subject).to eq({ enabled: false })
        end
      end

      context 'when object_store is configured' do
        it 'returns filtered object store config' do
          allow(Settings).to receive(:[]).with(component)
            .and_return(
              { 'enabled' => true,
                'object_store' =>
                { 'enabled' => true,
                  'remote_directory' => component,
                  'direct_upload' => true,
                  'connection' =>
                { 'provider' => 'AWS', 'aws_access_key_id' => 'minio', 'aws_secret_access_key' => 'gdk-minio', 'region' => 'gdk', 'endpoint' => 'http://127.0.0.1:9000', 'path_style' => true },
                  'proxy_download' => false } })

          expect(subject).to eq(
            { enabled: true, object_store: { enabled: true, direct_upload: true, background_upload: false, provider: "AWS" } })
        end
      end

      context 'when retrieve component setting meets exception' do
        before do
          allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(should_raise_for_dev)
          allow(Settings).to receive(:[]).with(component).and_raise(StandardError)
        end

        context 'with should_raise_for_dev? false' do
          let(:should_raise_for_dev) { false }

          it 'returns -1 for component enable status' do
            expect(subject).to eq({ enabled: -1 })
          end
        end

        context 'with should_raise_for_dev? true' do
          let(:should_raise_for_dev) { true }

          it 'raises an error' do
            expect { subject.value }.to raise_error(StandardError)
          end
        end
      end
    end

    describe '.object_store_usage_data' do
      subject { described_class.object_store_usage_data }

      it 'fetches object store config of five components' do
        %w[artifacts external_diffs lfs uploads packages].each do |component|
          expect(described_class).to receive(:object_store_config).with(component).and_return("#{component}_object_store_config")
        end

        expect(subject).to eq(
          object_store: {
            artifacts: 'artifacts_object_store_config',
            external_diffs: 'external_diffs_object_store_config',
            lfs: 'lfs_object_store_config',
            uploads: 'uploads_object_store_config',
            packages: 'packages_object_store_config'
          })
      end
    end
  end

  def for_defined_days_back(days: [31, 3])
    days.each do |n|
      travel_to(n.days.ago) do
        yield
      end
    end
  end

  describe '.service_desk_counts' do
    subject { described_class.send(:service_desk_counts) }

    let(:project) { create(:project, :service_desk_enabled) }

    it 'gathers Service Desk data' do
      create_list(:issue, 2, :confidential, author: Users::Internal.support_bot, project: project)

      expect(subject).to eq(service_desk_enabled_projects: 1, service_desk_issues: 2)
    end
  end

  describe ".with_metadata" do
    it 'records duration' do
      result = described_class.with_metadata { 1 + 1 }

      expect(result.duration).to be_an(Float)
    end

    it 'records error and returns nil', :aggregate_failures do
      allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

      result = described_class.with_metadata { raise }

      expect(result.error).to be_an(StandardError)
      expect(result).to be_nil
    end
  end
end
