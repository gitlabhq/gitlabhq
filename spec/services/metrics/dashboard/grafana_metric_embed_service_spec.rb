# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::GrafanaMetricEmbedService do
  include MetricsDashboardHelpers
  include ReactiveCachingHelpers
  include GrafanaApiHelpers

  let_it_be(:project) { build(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:grafana_integration) { create(:grafana_integration, project: project) }

  let(:grafana_url) do
    valid_grafana_dashboard_link(grafana_integration.grafana_url)
  end

  before do
    project.add_maintainer(user)
  end

  describe '.valid_params?' do
    let(:valid_params) { { embedded: true, grafana_url: grafana_url } }

    subject { described_class.valid_params?(params) }

    let(:params) { valid_params }

    it { is_expected.to be_truthy }

    context 'not embedded' do
      let(:params) { valid_params.except(:embedded) }

      it { is_expected.to be_falsey }
    end

    context 'undefined grafana_url' do
      let(:params) { valid_params.except(:grafana_url) }

      it { is_expected.to be_falsey }
    end
  end

  describe '.from_cache' do
    let(:params) { [project.id, user.id, grafana_url] }

    subject { described_class.from_cache(*params) }

    it 'initializes an instance of GrafanaMetricEmbedService' do
      expect(subject).to be_an_instance_of(described_class)
      expect(subject.project).to eq(project)
      expect(subject.current_user).to eq(user)
      expect(subject.params[:grafana_url]).to eq(grafana_url)
    end
  end

  describe '#get_dashboard', :use_clean_rails_memory_store_caching do
    let(:service_params) do
      [
        project,
        user,
        {
          embedded: true,
          grafana_url: grafana_url
        }
      ]
    end

    let(:service) { described_class.new(*service_params) }
    let(:service_call) { service.get_dashboard }

    context 'without caching' do
      before do
        synchronous_reactive_cache(service)
      end

      it_behaves_like 'raises error for users with insufficient permissions'

      context 'without a grafana integration' do
        before do
          allow(project).to receive(:grafana_integration).and_return(nil)
        end

        it_behaves_like 'misconfigured dashboard service response', :bad_request
      end

      context 'when grafana cannot be reached' do
        before do
          allow(grafana_integration.client).to receive(:get_dashboard).and_raise(::Grafana::Client::Error)
        end

        it_behaves_like 'misconfigured dashboard service response', :service_unavailable
      end

      context 'when panelId is missing' do
        let(:grafana_url) do
          grafana_integration.grafana_url +
            '/d/XDaNK6amz/gitlab-omnibus-redis' \
            '?from=1570397739557&to=1570484139557'
        end

        before do
          stub_dashboard_request(grafana_integration.grafana_url)
        end

        it_behaves_like 'misconfigured dashboard service response', :unprocessable_entity
      end

      context 'when uid is missing' do
        let(:grafana_url) { grafana_integration.grafana_url + '/d/' }

        before do
          stub_dashboard_request(grafana_integration.grafana_url)
        end

        it_behaves_like 'misconfigured dashboard service response', :unprocessable_entity
      end

      context 'when the dashboard response contains misconfigured json' do
        before do
          stub_dashboard_request(grafana_integration.grafana_url, body: '')
        end

        it_behaves_like 'misconfigured dashboard service response', :unprocessable_entity
      end

      context 'when the datasource response contains misconfigured json' do
        before do
          stub_dashboard_request(grafana_integration.grafana_url)
          stub_datasource_request(grafana_integration.grafana_url, body: '')
        end

        it_behaves_like 'misconfigured dashboard service response', :unprocessable_entity
      end

      context 'when the embed was created successfully' do
        before do
          stub_dashboard_request(grafana_integration.grafana_url)
          stub_datasource_request(grafana_integration.grafana_url)
        end

        it_behaves_like 'valid embedded dashboard service response'
      end
    end

    context 'with caching', :use_clean_rails_memory_store_caching do
      let(:cache_params) { [project.id, user.id, grafana_url] }

      context 'when value not present in cache' do
        it 'returns nil' do
          expect(ReactiveCachingWorker)
            .to receive(:perform_async)
            .with(service.class, service.id, *cache_params)

          expect(service_call).to eq(nil)
        end
      end

      context 'when value present in cache' do
        let(:return_value) { { 'http_status' => :ok, 'dashboard' => '{}' } }

        before do
          stub_reactive_cache(service, return_value, cache_params)
        end

        it 'returns cached value' do
          expect(ReactiveCachingWorker)
            .not_to receive(:perform_async)
            .with(service.class, service.id, *cache_params)

          expect(service_call[:http_status]).to eq(return_value[:http_status])
          expect(service_call[:dashboard]).to eq(return_value[:dashboard])
        end
      end
    end
  end
end

describe Metrics::Dashboard::GrafanaUidParser do
  let_it_be(:grafana_integration) { create(:grafana_integration) }
  let_it_be(:project) { grafana_integration.project }

  subject { described_class.new(grafana_url, project).parse }

  context 'with a Grafana-defined uid' do
    let(:grafana_url) { grafana_integration.grafana_url + '/d/XDaNK6amz/?panelId=1' }

    it { is_expected.to eq 'XDaNK6amz' }
  end

  context 'with a user-defined uid' do
    let(:grafana_url) { grafana_integration.grafana_url + '/d/pgbouncer-main/pgbouncer-overview?panelId=1' }

    it { is_expected.to eq 'pgbouncer-main' }
  end

  context 'when a uid is not present' do
    let(:grafana_url) { grafana_integration.grafana_url }

    it { is_expected.to be nil }
  end

  context 'when the url starts with unrelated content' do
    let(:grafana_url) { 'js:' + grafana_integration.grafana_url }

    it { is_expected.to be nil }
  end
end

describe Metrics::Dashboard::DatasourceNameParser do
  include GrafanaApiHelpers

  let(:grafana_url) { valid_grafana_dashboard_link('https://gitlab.grafana.net') }
  let(:grafana_dashboard) { JSON.parse(fixture_file('grafana/dashboard_response.json'), symbolize_names: true) }

  subject { described_class.new(grafana_url, grafana_dashboard).parse }

  it { is_expected.to eq 'GitLab Omnibus' }

  context 'when the panelId is missing from the url' do
    let(:grafana_url) { 'https:/gitlab.grafana.net/d/jbdbks/' }

    it { is_expected.to be nil }
  end

  context 'when the panel is not present' do
    # We're looking for panelId of 8, but only 6 is present
    let(:grafana_dashboard) { { dashboard: { panels: [{ id: 6 }] } } }

    it { is_expected.to be nil }
  end

  context 'when the dashboard panel does not have a datasource' do
    let(:grafana_dashboard) { { dashboard: { panels: [{ id: 8 }] } } }

    it { is_expected.to be nil }
  end
end
