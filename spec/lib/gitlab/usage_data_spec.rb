# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageData, :aggregate_failures do
  include UsageDataHelpers

  before do
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)

    stub_object_store_settings
  end

  shared_examples "usage data execution" do
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
        expect(count_data[:issues_created_from_gitlab_error_tracking_ui]).to eq(1)
        expect(count_data[:issues_with_associated_zoom_link]).to eq(2)
        expect(count_data[:issues_using_zoom_quick_actions]).to eq(3)
        expect(count_data[:issues_with_embedded_grafana_charts_approx]).to eq(2)
        expect(count_data[:incident_issues]).to eq(4)

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

      describe 'the results of calling #totals on all objects in the array' do
        subject { described_class.usage_data_counters.map(&:totals) }

        it { is_expected.to all(be_a Hash) }
        it { is_expected.to all(have_attributes(keys: all(be_a Symbol), values: all(be_a Integer))) }
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

    context 'when not relying on database records' do
      describe '#features_usage_data_ce' do
        subject { described_class.features_usage_data_ce }

        it 'gathers feature usage data' do
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
        end

        context 'with existing container expiration policies' do
          let_it_be(:disabled) { create(:container_expiration_policy, enabled: false) }
          let_it_be(:enabled) { create(:container_expiration_policy, enabled: true) }
          %i[keep_n cadence older_than].each do |attribute|
            ContainerExpirationPolicy.send("#{attribute}_options").keys.each do |value|
              let_it_be("container_expiration_policy_with_#{attribute}_set_to_#{value}") { create(:container_expiration_policy, attribute => value) }
            end
          end

          let(:inactive_policies) { ::ContainerExpirationPolicy.where(enabled: false) }
          let(:active_policies) { ::ContainerExpirationPolicy.active }

          it 'gathers usage data' do
            expect(subject[:projects_with_expiration_policy_enabled]).to eq 16
            expect(subject[:projects_with_expiration_policy_disabled]).to eq 1

            expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_unset]).to eq 10
            expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_set_to_1]).to eq 1
            expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_set_to_5]).to eq 1
            expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_set_to_10]).to eq 1
            expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_set_to_25]).to eq 1
            expect(subject[:projects_with_expiration_policy_enabled_with_keep_n_set_to_50]).to eq 1

            expect(subject[:projects_with_expiration_policy_enabled_with_older_than_unset]).to eq 12
            expect(subject[:projects_with_expiration_policy_enabled_with_older_than_set_to_7d]).to eq 1
            expect(subject[:projects_with_expiration_policy_enabled_with_older_than_set_to_14d]).to eq 1
            expect(subject[:projects_with_expiration_policy_enabled_with_older_than_set_to_30d]).to eq 1
            expect(subject[:projects_with_expiration_policy_enabled_with_older_than_set_to_90d]).to eq 1

            expect(subject[:projects_with_expiration_policy_enabled_with_cadence_set_to_1d]).to eq 12
            expect(subject[:projects_with_expiration_policy_enabled_with_cadence_set_to_7d]).to eq 1
            expect(subject[:projects_with_expiration_policy_enabled_with_cadence_set_to_14d]).to eq 1
            expect(subject[:projects_with_expiration_policy_enabled_with_cadence_set_to_1month]).to eq 1
            expect(subject[:projects_with_expiration_policy_enabled_with_cadence_set_to_3month]).to eq 1
          end
        end
      end

      describe '#components_usage_data' do
        subject { described_class.components_usage_data }

        it 'gathers components usage data' do
          expect(Gitlab::UsageData).to receive(:app_server_type).and_return('server_type')
          expect(subject[:app_server][:type]).to eq('server_type')
          expect(subject[:gitlab_pages][:enabled]).to eq(Gitlab.config.pages.enabled)
          expect(subject[:gitlab_pages][:version]).to eq(Gitlab::Pages::VERSION)
          expect(subject[:git][:version]).to eq(Gitlab::Git.version)
          expect(subject[:database][:adapter]).to eq(Gitlab::Database.adapter_name)
          expect(subject[:database][:version]).to eq(Gitlab::Database.version)
          expect(subject[:gitaly][:version]).to be_present
          expect(subject[:gitaly][:servers]).to be >= 1
          expect(subject[:gitaly][:filesystems]).to be_an(Array)
          expect(subject[:gitaly][:filesystems].first).to be_a(String)
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

      describe '#count' do
        let(:relation) { double(:relation) }

        it 'returns the count when counting succeeds' do
          allow(relation).to receive(:count).and_return(1)

          expect(described_class.count(relation, batch: false)).to eq(1)
        end

        it 'returns the fallback value when counting fails' do
          allow(relation).to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))

          expect(described_class.count(relation, fallback: 15, batch: false)).to eq(15)
        end
      end

      describe '#distinct_count' do
        let(:relation) { double(:relation) }

        it 'returns the count when counting succeeds' do
          allow(relation).to receive(:distinct_count_by).and_return(1)

          expect(described_class.distinct_count(relation, batch: false)).to eq(1)
        end

        it 'returns the fallback value when counting fails' do
          allow(relation).to receive(:distinct_count_by).and_raise(ActiveRecord::StatementInvalid.new(''))

          expect(described_class.distinct_count(relation, fallback: 15, batch: false)).to eq(15)
        end
      end
    end
  end

  context 'when usage usage_ping_batch_counter is true' do
    before do
      stub_feature_flags(usage_ping_batch_counter: true)
    end

    it_behaves_like 'usage data execution'
  end

  context 'when usage usage_ping_batch_counter is false' do
    before do
      stub_feature_flags(usage_ping_batch_counter: false)
    end

    it_behaves_like 'usage data execution'
  end

  describe '#alt_usage_data' do
    it 'returns the fallback when it gets an error' do
      expect(described_class.alt_usage_data { raise StandardError } ).to eq(-1)
    end

    it 'returns the evaluated block when give' do
      expect(described_class.alt_usage_data { Gitlab::CurrentSettings.uuid } ).to eq(Gitlab::CurrentSettings.uuid)
    end

    it 'returns the value when given' do
      expect(described_class.alt_usage_data(1)).to eq 1
    end
  end
end
