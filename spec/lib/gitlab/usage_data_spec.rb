# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageData, :aggregate_failures do
  include UsageDataHelpers

  before do
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
  end

  shared_examples "usage data execution" do
    describe '#data' do
      let!(:ud) { build(:usage_data) }

      before do
        allow(Gitlab::GrafanaEmbedUsageData).to receive(:issue_count).and_return(2)
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
        expect(count_data[:projects_slack_notifications_active]).to eq(2)
        expect(count_data[:projects_slack_slash_active]).to eq(1)
        expect(count_data[:projects_slack_active]).to eq(2)
        expect(count_data[:projects_slack_slash_commands_active]).to eq(1)
        expect(count_data[:projects_custom_issue_tracker_active]).to eq(1)
        expect(count_data[:projects_mattermost_active]).to eq(0)
        expect(count_data[:projects_with_repositories_enabled]).to eq(3)
        expect(count_data[:projects_with_error_tracking_enabled]).to eq(1)
        expect(count_data[:projects_with_alerts_service_enabled]).to eq(1)
        expect(count_data[:issues_created_from_gitlab_error_tracking_ui]).to eq(1)
        expect(count_data[:issues_with_associated_zoom_link]).to eq(2)
        expect(count_data[:issues_using_zoom_quick_actions]).to eq(3)
        expect(count_data[:issues_with_embedded_grafana_charts_approx]).to eq(2)
        expect(count_data[:incident_issues]).to eq(4)

        expect(count_data[:clusters_enabled]).to eq(4)
        expect(count_data[:project_clusters_enabled]).to eq(3)
        expect(count_data[:group_clusters_enabled]).to eq(1)
        expect(count_data[:clusters_disabled]).to eq(3)
        expect(count_data[:project_clusters_disabled]).to eq(1)
        expect(count_data[:group_clusters_disabled]).to eq(2)
        expect(count_data[:group_clusters_enabled]).to eq(1)
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
      end

      it 'works when queries time out' do
        allow_any_instance_of(ActiveRecord::Relation)
          .to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))

        expect { subject }.not_to raise_error
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
      end

      describe '#components_usage_data' do
        subject { described_class.components_usage_data }

        it 'gathers components usage data' do
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

        it 'gathers variable data' do
          allow_any_instance_of(
            ::Clusters::Applications::IngressModsecurityUsageService
          ).to receive(:execute).and_return(
            {
              ingress_modsecurity_blocking: 1,
              ingress_modsecurity_disabled: 2
            }
          )

          expect(subject[:ingress_modsecurity_blocking]).to eq(1)
          expect(subject[:ingress_modsecurity_disabled]).to eq(2)
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
end
