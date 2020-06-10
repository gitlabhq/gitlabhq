# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageData, :aggregate_failures do
  include UsageDataHelpers

  before do
    stub_usage_data_connections
    stub_object_store_settings
  end

  describe '#uncached_data' do
    it 'ensures recorded_at is set before any other usage data calculation' do
      %i(alt_usage_data redis_usage_data distinct_count count).each do |method|
        expect(described_class).not_to receive(method)
      end
      expect(described_class).to receive(:recorded_at).and_raise(Exception.new('Stopped calculating recorded_at'))

      expect { described_class.uncached_data }.to raise_error('Stopped calculating recorded_at')
    end
  end

  describe '#data' do
    let!(:ud) { build(:usage_data) }

    before do
      allow(described_class).to receive(:grafana_embed_usage_data).and_return(2)
    end

    subject { described_class.data }

    it 'gathers usage data' do
      expect(subject.keys).to include(*UsageDataHelpers::USAGE_DATA_KEYS)
    end

    it 'gathers usage counts' do
      count_data = subject[:counts]

      expect(count_data[:boards]).to eq(1)
      expect(count_data[:projects]).to eq(4)
      expect(count_data.values_at(*UsageDataHelpers::SMAU_KEYS)).to all(be_an(Integer))
      expect(count_data.keys).to include(*UsageDataHelpers::COUNTS_KEYS)
      expect(UsageDataHelpers::COUNTS_KEYS - count_data.keys).to be_empty
    end

    it 'gathers projects data correctly' do
      count_data = subject[:counts]

      expect(count_data[:projects]).to eq(4)
      expect(count_data[:projects_asana_active]).to eq(0)
      expect(count_data[:projects_prometheus_active]).to eq(1)
      expect(count_data[:projects_jira_active]).to eq(4)
      expect(count_data[:projects_jira_server_active]).to eq(2)
      expect(count_data[:projects_jira_cloud_active]).to eq(2)
      expect(count_data[:jira_imports_projects_count]).to eq(2)
      expect(count_data[:jira_imports_total_imported_count]).to eq(3)
      expect(count_data[:jira_imports_total_imported_issues_count]).to eq(13)
      expect(count_data[:projects_slack_notifications_active]).to eq(2)
      expect(count_data[:projects_slack_slash_active]).to eq(1)
      expect(count_data[:projects_slack_active]).to eq(2)
      expect(count_data[:projects_slack_slash_commands_active]).to eq(1)
      expect(count_data[:projects_custom_issue_tracker_active]).to eq(1)
      expect(count_data[:projects_mattermost_active]).to eq(0)
      expect(count_data[:projects_with_repositories_enabled]).to eq(3)
      expect(count_data[:projects_with_error_tracking_enabled]).to eq(1)
      expect(count_data[:projects_with_alerts_service_enabled]).to eq(1)
      expect(count_data[:projects_with_prometheus_alerts]).to eq(2)
      expect(count_data[:projects_with_terraform_reports]).to eq(2)
      expect(count_data[:projects_with_terraform_states]).to eq(2)
      expect(count_data[:terraform_reports]).to eq(6)
      expect(count_data[:terraform_states]).to eq(3)
      expect(count_data[:issues_created_from_gitlab_error_tracking_ui]).to eq(1)
      expect(count_data[:issues_with_associated_zoom_link]).to eq(2)
      expect(count_data[:issues_using_zoom_quick_actions]).to eq(3)
      expect(count_data[:issues_with_embedded_grafana_charts_approx]).to eq(2)
      expect(count_data[:incident_issues]).to eq(4)
      expect(count_data[:issues_created_gitlab_alerts]).to eq(1)
      expect(count_data[:issues_created_from_alerts]).to eq(3)
      expect(count_data[:issues_created_manually_from_alerts]).to eq(1)
      expect(count_data[:alert_bot_incident_issues]).to eq(4)
      expect(count_data[:incident_labeled_issues]).to eq(3)

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
      expect(count_data[:clusters_applications_helm]).to eq(1)
      expect(count_data[:clusters_applications_ingress]).to eq(1)
      expect(count_data[:clusters_applications_cert_managers]).to eq(1)
      expect(count_data[:clusters_applications_crossplane]).to eq(1)
      expect(count_data[:clusters_applications_prometheus]).to eq(1)
      expect(count_data[:clusters_applications_runner]).to eq(1)
      expect(count_data[:clusters_applications_knative]).to eq(1)
      expect(count_data[:clusters_applications_elastic_stack]).to eq(1)
      expect(count_data[:grafana_integrated_projects]).to eq(2)
      expect(count_data[:clusters_applications_jupyter]).to eq(1)
      expect(count_data[:clusters_management_project]).to eq(1)
    end

    it 'gathers object store usage correctly' do
      expect(subject[:object_store]).to eq(
        { artifacts: { enabled: true, object_store: { enabled: true, direct_upload: true, background_upload: false, provider: "AWS" } },
         external_diffs: { enabled: false },
         lfs: { enabled: true, object_store: { enabled: false, direct_upload: true, background_upload: false, provider: "AWS" } },
         uploads: { enabled: nil, object_store: { enabled: false, direct_upload: true, background_upload: false, provider: "AWS" } },
         packages: { enabled: true, object_store: { enabled: false, direct_upload: false, background_upload: true, provider: "AWS" } } }
      )
    end

    it 'gathers topology data' do
      expect(subject.keys).to include(:topology)
    end

    context 'with existing container expiration policies' do
      let_it_be(:disabled) { create(:container_expiration_policy, enabled: false) }
      let_it_be(:enabled) { create(:container_expiration_policy, enabled: true) }

      %i[keep_n cadence older_than].each do |attribute|
        ContainerExpirationPolicy.send("#{attribute}_options").keys.each do |value|
          let_it_be("container_expiration_policy_with_#{attribute}_set_to_#{value}") { create(:container_expiration_policy, attribute => value) }
        end
      end

      let_it_be('container_expiration_policy_with_keep_n_set_to_null') { create(:container_expiration_policy, keep_n: nil) }
      let_it_be('container_expiration_policy_with_older_than_set_to_null') { create(:container_expiration_policy, older_than: nil) }

      let(:inactive_policies) { ::ContainerExpirationPolicy.where(enabled: false) }
      let(:active_policies) { ::ContainerExpirationPolicy.active }

      subject { described_class.data[:counts] }

      it 'gathers usage data' do
        expect(subject[:projects_with_expiration_policy_enabled]).to eq 22
        expect(subject[:projects_with_expiration_policy_disabled]).to eq 1

        expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_unset]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_set_to_1]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_set_to_5]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_set_to_10]).to eq 16
        expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_set_to_25]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_set_to_50]).to eq 1

        expect(subject[:projects_with_expiration_policy_enabled_with_older_than_unset]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_older_than_set_to_7d]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_older_than_set_to_14d]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_older_than_set_to_30d]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_older_than_set_to_90d]).to eq 18

        expect(subject[:projects_with_expiration_policy_enabled_with_cadence_set_to_1d]).to eq 18
        expect(subject[:projects_with_expiration_policy_enabled_with_cadence_set_to_7d]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_cadence_set_to_14d]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_cadence_set_to_1month]).to eq 1
        expect(subject[:projects_with_expiration_policy_enabled_with_cadence_set_to_3month]).to eq 1
      end
    end

    it 'works when queries time out' do
      allow_any_instance_of(ActiveRecord::Relation)
        .to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))

      expect { subject }.not_to raise_error
    end

    it 'jira usage works when queries time out' do
      allow_any_instance_of(ActiveRecord::Relation)
        .to receive(:find_in_batches).and_raise(ActiveRecord::StatementInvalid.new(''))

      expect { described_class.jira_usage }.not_to raise_error
    end
  end

  describe '#usage_data_counters' do
    subject { described_class.usage_data_counters }

    it { is_expected.to all(respond_to :totals) }
    it { is_expected.to all(respond_to :fallback_totals) }

    describe 'the results of calling #totals on all objects in the array' do
      subject { described_class.usage_data_counters.map(&:totals) }

      it { is_expected.to all(be_a Hash) }
      it { is_expected.to all(have_attributes(keys: all(be_a Symbol), values: all(be_a Integer))) }
    end

    describe 'the results of calling #fallback_totals on all objects in the array' do
      subject { described_class.usage_data_counters.map(&:fallback_totals) }

      it { is_expected.to all(be_a Hash) }
      it { is_expected.to all(have_attributes(keys: all(be_a Symbol), values: all(eq(-1)))) }
    end

    it 'does not have any conflicts' do
      all_keys = subject.flat_map { |counter| counter.totals.keys }

      expect(all_keys.size).to eq all_keys.to_set.size
    end
  end

  describe '#license_usage_data' do
    subject { described_class.license_usage_data }

    it 'gathers license data' do
      expect(subject[:uuid]).to eq(Gitlab::CurrentSettings.uuid)
      expect(subject[:version]).to eq(Gitlab::VERSION)
      expect(subject[:installation_type]).to eq('gitlab-development-kit')
      expect(subject[:active_user_count]).to eq(User.active.size)
      expect(subject[:recorded_at]).to be_a(Time)
    end
  end

  describe '.recording_ce_finished_at' do
    subject { described_class.recording_ce_finish_data }

    it 'gathers time ce recording finishes at' do
      expect(subject[:recording_ce_finished_at]).to be_a(Time)
    end
  end

  context 'when not relying on database records' do
    describe '#features_usage_data_ce' do
      subject { described_class.features_usage_data_ce }

      it 'gathers feature usage data', :aggregate_failures do
        expect(subject[:instance_auto_devops_enabled]).to eq(Gitlab::CurrentSettings.auto_devops_enabled?)
        expect(subject[:mattermost_enabled]).to eq(Gitlab.config.mattermost.enabled)
        expect(subject[:signup_enabled]).to eq(Gitlab::CurrentSettings.allow_signup?)
        expect(subject[:ldap_enabled]).to eq(Gitlab.config.ldap.enabled)
        expect(subject[:gravatar_enabled]).to eq(Gitlab::CurrentSettings.gravatar_enabled?)
        expect(subject[:omniauth_enabled]).to eq(Gitlab::Auth.omniauth_enabled?)
        expect(subject[:reply_by_email_enabled]).to eq(Gitlab::IncomingEmail.enabled?)
        expect(subject[:container_registry_enabled]).to eq(Gitlab.config.registry.enabled)
        expect(subject[:dependency_proxy_enabled]).to eq(Gitlab.config.dependency_proxy.enabled)
        expect(subject[:gitlab_shared_runners_enabled]).to eq(Gitlab.config.gitlab_ci.shared_runners_enabled)
        expect(subject[:web_ide_clientside_preview_enabled]).to eq(Gitlab::CurrentSettings.web_ide_clientside_preview_enabled?)
        expect(subject[:grafana_link_enabled]).to eq(Gitlab::CurrentSettings.grafana_enabled?)
      end

      context 'with embedded grafana' do
        it 'returns true when embedded grafana is enabled' do
          stub_application_setting(grafana_enabled: true)

          expect(subject[:grafana_link_enabled]).to eq(true)
        end

        it 'returns false when embedded grafana is disabled' do
          stub_application_setting(grafana_enabled: false)

          expect(subject[:grafana_link_enabled]).to eq(false)
        end
      end
    end

    describe '#components_usage_data' do
      subject { described_class.components_usage_data }

      it 'gathers basic components usage data' do
        stub_runtime(:puma)

        expect(subject[:app_server][:type]).to eq('puma')
        expect(subject[:gitlab_pages][:enabled]).to eq(Gitlab.config.pages.enabled)
        expect(subject[:gitlab_pages][:version]).to eq(Gitlab::Pages::VERSION)
        expect(subject[:git][:version]).to eq(Gitlab::Git.version)
        expect(subject[:database][:adapter]).to eq(Gitlab::Database.adapter_name)
        expect(subject[:database][:version]).to eq(Gitlab::Database.version)
        expect(subject[:gitaly][:version]).to be_present
        expect(subject[:gitaly][:servers]).to be >= 1
        expect(subject[:gitaly][:clusters]).to be >= 0
        expect(subject[:gitaly][:filesystems]).to be_an(Array)
        expect(subject[:gitaly][:filesystems].first).to be_a(String)
      end

      def stub_runtime(runtime)
        allow(Gitlab::Runtime).to receive(:identify).and_return(runtime)
      end
    end

    describe '#app_server_type' do
      subject { described_class.app_server_type }

      it 'successfully identifies runtime and returns the identifier' do
        expect(Gitlab::Runtime).to receive(:identify).and_return(:runtime_identifier)

        is_expected.to eq('runtime_identifier')
      end

      context 'when runtime is not identified' do
        let(:exception) { Gitlab::Runtime::IdentificationError.new('exception message from runtime identify') }

        it 'logs the exception and returns unknown app server type' do
          expect(Gitlab::Runtime).to receive(:identify).and_raise(exception)

          expect(Gitlab::AppLogger).to receive(:error).with(exception.message)
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception)
          expect(subject).to eq('unknown_app_server_type')
        end
      end
    end

    describe '#object_store_config' do
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
                  'background_upload' => false,
                  'proxy_download' => false } })

          expect(subject).to eq(
            { enabled: true, object_store: { enabled: true, direct_upload: true, background_upload: false, provider: "AWS" } })
        end
      end

      context 'when retrieve component setting meets exception' do
        it 'returns -1 for component enable status' do
          allow(Settings).to receive(:[]).with(component).and_raise(StandardError)

          expect(subject).to eq({ enabled: -1 })
        end
      end
    end

    describe '#object_store_usage_data' do
      subject { described_class.object_store_usage_data }

      it 'fetches object store config of five components' do
        %w(artifacts external_diffs lfs uploads packages).each do |component|
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

    describe '#cycle_analytics_usage_data' do
      subject { described_class.cycle_analytics_usage_data }

      it 'works when queries time out in new' do
        allow(Gitlab::CycleAnalytics::UsageData)
          .to receive(:new).and_raise(ActiveRecord::StatementInvalid.new(''))

        expect { subject }.not_to raise_error
      end

      it 'works when queries time out in to_json' do
        allow_any_instance_of(Gitlab::CycleAnalytics::UsageData)
          .to receive(:to_json).and_raise(ActiveRecord::StatementInvalid.new(''))

        expect { subject }.not_to raise_error
      end
    end

    describe '#ingress_modsecurity_usage' do
      subject { described_class.ingress_modsecurity_usage }

      let(:environment) { create(:environment) }
      let(:project) { environment.project }
      let(:environment_scope) { '*' }
      let(:deployment) { create(:deployment, :success, environment: environment, project: project, cluster: cluster) }
      let(:cluster) { create(:cluster, environment_scope: environment_scope, projects: [project]) }
      let(:ingress_mode) { :modsecurity_blocking }
      let!(:ingress) { create(:clusters_applications_ingress, ingress_mode, cluster: cluster) }

      context 'when cluster is disabled' do
        let(:cluster) { create(:cluster, :disabled, projects: [project]) }

        it 'gathers ingress data' do
          expect(subject[:ingress_modsecurity_logging]).to eq(0)
          expect(subject[:ingress_modsecurity_blocking]).to eq(0)
          expect(subject[:ingress_modsecurity_disabled]).to eq(0)
          expect(subject[:ingress_modsecurity_not_installed]).to eq(0)
        end
      end

      context 'when deployment is unsuccessful' do
        let!(:deployment) { create(:deployment, :failed, environment: environment, project: project, cluster: cluster) }

        it 'gathers ingress data' do
          expect(subject[:ingress_modsecurity_logging]).to eq(0)
          expect(subject[:ingress_modsecurity_blocking]).to eq(0)
          expect(subject[:ingress_modsecurity_disabled]).to eq(0)
          expect(subject[:ingress_modsecurity_not_installed]).to eq(0)
        end
      end

      context 'when deployment is successful' do
        let!(:deployment) { create(:deployment, :success, environment: environment, project: project, cluster: cluster) }

        context 'when modsecurity is in blocking mode' do
          it 'gathers ingress data' do
            expect(subject[:ingress_modsecurity_logging]).to eq(0)
            expect(subject[:ingress_modsecurity_blocking]).to eq(1)
            expect(subject[:ingress_modsecurity_disabled]).to eq(0)
            expect(subject[:ingress_modsecurity_not_installed]).to eq(0)
          end
        end

        context 'when modsecurity is in logging mode' do
          let(:ingress_mode) { :modsecurity_logging }

          it 'gathers ingress data' do
            expect(subject[:ingress_modsecurity_logging]).to eq(1)
            expect(subject[:ingress_modsecurity_blocking]).to eq(0)
            expect(subject[:ingress_modsecurity_disabled]).to eq(0)
            expect(subject[:ingress_modsecurity_not_installed]).to eq(0)
          end
        end

        context 'when modsecurity is disabled' do
          let(:ingress_mode) { :modsecurity_disabled }

          it 'gathers ingress data' do
            expect(subject[:ingress_modsecurity_logging]).to eq(0)
            expect(subject[:ingress_modsecurity_blocking]).to eq(0)
            expect(subject[:ingress_modsecurity_disabled]).to eq(1)
            expect(subject[:ingress_modsecurity_not_installed]).to eq(0)
          end
        end

        context 'when modsecurity is not installed' do
          let(:ingress_mode) { :modsecurity_not_installed }

          it 'gathers ingress data' do
            expect(subject[:ingress_modsecurity_logging]).to eq(0)
            expect(subject[:ingress_modsecurity_blocking]).to eq(0)
            expect(subject[:ingress_modsecurity_disabled]).to eq(0)
            expect(subject[:ingress_modsecurity_not_installed]).to eq(1)
          end
        end

        context 'with multiple projects' do
          let(:environment_2) { create(:environment) }
          let(:project_2) { environment_2.project }
          let(:cluster_2) { create(:cluster, environment_scope: environment_scope, projects: [project_2]) }
          let!(:ingress_2) { create(:clusters_applications_ingress, :modsecurity_logging, cluster: cluster_2) }
          let!(:deployment_2) { create(:deployment, :success, environment: environment_2, project: project_2, cluster: cluster_2) }

          it 'gathers non-duplicated ingress data' do
            expect(subject[:ingress_modsecurity_logging]).to eq(1)
            expect(subject[:ingress_modsecurity_blocking]).to eq(1)
            expect(subject[:ingress_modsecurity_disabled]).to eq(0)
            expect(subject[:ingress_modsecurity_not_installed]).to eq(0)
          end
        end

        context 'with multiple deployments' do
          let!(:deployment_2) { create(:deployment, :success, environment: environment, project: project, cluster: cluster) }

          it 'gathers non-duplicated ingress data' do
            expect(subject[:ingress_modsecurity_logging]).to eq(0)
            expect(subject[:ingress_modsecurity_blocking]).to eq(1)
            expect(subject[:ingress_modsecurity_disabled]).to eq(0)
            expect(subject[:ingress_modsecurity_not_installed]).to eq(0)
          end
        end

        context 'with multiple projects' do
          let(:environment_2) { create(:environment) }
          let(:project_2) { environment_2.project }
          let!(:deployment_2) { create(:deployment, :success, environment: environment_2, project: project_2, cluster: cluster) }
          let(:cluster) { create(:cluster, environment_scope: environment_scope, projects: [project, project_2]) }

          it 'gathers ingress data' do
            expect(subject[:ingress_modsecurity_logging]).to eq(0)
            expect(subject[:ingress_modsecurity_blocking]).to eq(2)
            expect(subject[:ingress_modsecurity_disabled]).to eq(0)
            expect(subject[:ingress_modsecurity_not_installed]).to eq(0)
          end
        end

        context 'with multiple environments' do
          let!(:environment_2) { create(:environment, project: project) }
          let!(:deployment_2) { create(:deployment, :success, environment: environment_2, project: project, cluster: cluster) }

          it 'gathers ingress data' do
            expect(subject[:ingress_modsecurity_logging]).to eq(0)
            expect(subject[:ingress_modsecurity_blocking]).to eq(2)
            expect(subject[:ingress_modsecurity_disabled]).to eq(0)
            expect(subject[:ingress_modsecurity_not_installed]).to eq(0)
          end
        end
      end
    end

    describe '#grafana_embed_usage_data' do
      subject { described_class.grafana_embed_usage_data }

      let(:project) { create(:project) }
      let(:description_with_embed) { "Some comment\n\nhttps://grafana.example.com/d/xvAk4q0Wk/go-processes?orgId=1&from=1573238522762&to=1573240322762&var-job=prometheus&var-interval=10m&panelId=1&fullscreen" }
      let(:description_with_unintegrated_embed) { "Some comment\n\nhttps://grafana.exp.com/d/xvAk4q0Wk/go-processes?orgId=1&from=1573238522762&to=1573240322762&var-job=prometheus&var-interval=10m&panelId=1&fullscreen" }
      let(:description_with_non_grafana_inline_metric) { "Some comment\n\n#{Gitlab::Routing.url_helpers.metrics_namespace_project_environment_url(*['foo', 'bar', 12])}" }

      shared_examples "zero count" do
        it "does not count the issue" do
          expect(subject).to eq(0)
        end
      end

      context 'with project grafana integration enabled' do
        before do
          create(:grafana_integration, project: project, enabled: true)
        end

        context 'with valid and invalid embeds' do
          before do
            # Valid
            create(:issue, project: project, description: description_with_embed)
            create(:issue, project: project, description: description_with_embed)
            # In-Valid
            create(:issue, project: project, description: description_with_unintegrated_embed)
            create(:issue, project: project, description: description_with_non_grafana_inline_metric)
            create(:issue, project: project, description: nil)
            create(:issue, project: project, description: '')
            create(:issue, project: project)
          end

          it 'counts only the issues with embeds' do
            expect(subject).to eq(2)
          end
        end
      end

      context 'with project grafana integration disabled' do
        before do
          create(:grafana_integration, project: project, enabled: false)
        end

        context 'with one issue having a grafana link in the description and one without' do
          before do
            create(:issue, project: project, description: description_with_embed)
            create(:issue, project: project)
          end

          it_behaves_like('zero count')
        end
      end

      context 'with an un-integrated project' do
        context 'with one issue having a grafana link in the description and one without' do
          before do
            create(:issue, project: project, description: description_with_embed)
            create(:issue, project: project)
          end

          it_behaves_like('zero count')
        end
      end
    end
  end

  describe '#merge_requests_usage_data' do
    let(:time_period) { { created_at: 2.days.ago..Time.current } }
    let(:merge_request) { create(:merge_request) }
    let(:other_user) { create(:user) }
    let(:another_user) { create(:user) }

    before do
      create(:event, target: merge_request, author: merge_request.author, created_at: 1.day.ago)
      create(:event, target: merge_request, author: merge_request.author, created_at: 1.hour.ago)
      create(:event, target: merge_request, author: merge_request.author, created_at: 3.days.ago)
      create(:event, target: merge_request, author: other_user, created_at: 1.day.ago)
      create(:event, target: merge_request, author: other_user, created_at: 1.hour.ago)
      create(:event, target: merge_request, author: other_user, created_at: 3.days.ago)
      create(:event, target: merge_request, author: another_user, created_at: 4.days.ago)
    end

    it 'returns the distinct count of users using merge requests (via events table) within the specified time period' do
      expect(described_class.merge_requests_usage_data(time_period)).to eq(
        merge_requests_users: 2
      )
    end
  end
end
