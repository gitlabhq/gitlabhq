# frozen_string_literal: true

require 'spec_helper'

describe PrometheusService, :use_clean_rails_memory_store_caching do
  include PrometheusHelpers
  include ReactiveCachingHelpers

  let(:project) { create(:prometheus_project) }
  let(:service) { project.prometheus_service }

  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  context 'redirects' do
    it 'does not follow redirects' do
      redirect_to = 'https://redirected.example.com'
      redirect_req_stub = stub_prometheus_request(prometheus_query_url('1'), status: 302, headers: { location: redirect_to })
      redirected_req_stub = stub_prometheus_request(redirect_to, body: { 'status': 'success' })

      result = service.test

      # result = { success: false, result: error }
      expect(result[:success]).to be_falsy
      expect(result[:result]).to be_instance_of(Gitlab::PrometheusClient::Error)

      expect(redirect_req_stub).to have_been_requested
      expect(redirected_req_stub).not_to have_been_requested
    end
  end

  describe 'Validations' do
    context 'when manual_configuration is enabled' do
      before do
        service.manual_configuration = true
      end

      it 'validates presence of api_url' do
        expect(service).to validate_presence_of(:api_url)
      end
    end

    context 'when manual configuration is disabled' do
      before do
        service.manual_configuration = false
      end

      it 'does not validate presence of api_url' do
        expect(service).not_to validate_presence_of(:api_url)
      end
    end

    context 'when the api_url domain points to localhost or local network' do
      let(:domain) { Addressable::URI.parse(service.api_url).hostname }

      it 'cannot query' do
        expect(service.can_query?).to be true

        aggregate_failures do
          ['127.0.0.1', '192.168.2.3'].each do |url|
            allow(Addrinfo).to receive(:getaddrinfo).with(domain, any_args).and_return([Addrinfo.tcp(url, 80)])

            expect(service.can_query?).to be false
          end
        end
      end

      context 'with self-monitoring project and internal Prometheus' do
        before do
          service.api_url = 'http://localhost:9090'

          stub_application_setting(instance_administration_project_id: project.id)
          stub_config(prometheus: { enable: true, listen_address: 'localhost:9090' })
        end

        it 'allows self-monitoring project to connect to internal Prometheus' do
          aggregate_failures do
            ['127.0.0.1', '192.168.2.3'].each do |url|
              allow(Addrinfo).to receive(:getaddrinfo).with(domain, any_args).and_return([Addrinfo.tcp(url, 80)])

              expect(service.can_query?).to be true
            end
          end
        end

        it 'does not allow self-monitoring project to connect to other local URLs' do
          service.api_url = 'http://localhost:8000'

          aggregate_failures do
            ['127.0.0.1', '192.168.2.3'].each do |url|
              allow(Addrinfo).to receive(:getaddrinfo).with(domain, any_args).and_return([Addrinfo.tcp(url, 80)])

              expect(service.can_query?).to be false
            end
          end
        end
      end
    end
  end

  describe '#test' do
    before do
      service.manual_configuration = true
    end

    let!(:req_stub) { stub_prometheus_request(prometheus_query_url('1'), body: prometheus_value_body('vector')) }

    context 'success' do
      it 'reads the discovery endpoint' do
        expect(service.test[:result]).to eq('Checked API endpoint')
        expect(service.test[:success]).to be_truthy
        expect(req_stub).to have_been_requested.twice
      end
    end

    context 'failure' do
      let!(:req_stub) { stub_prometheus_request(prometheus_query_url('1'), status: 404) }

      it 'fails to read the discovery endpoint' do
        expect(service.test[:success]).to be_falsy
        expect(req_stub).to have_been_requested
      end
    end
  end

  describe '#prometheus_client' do
    let(:api_url) { 'http://some_url' }

    before do
      service.active = true
      service.api_url = api_url
      service.manual_configuration = manual_configuration
    end

    context 'manual configuration is enabled' do
      let(:manual_configuration) { true }

      it 'calls valid?' do
        allow(service).to receive(:valid?).and_call_original

        expect(service.prometheus_client).not_to be_nil

        expect(service).to have_received(:valid?)
      end
    end

    context 'manual configuration is disabled' do
      let(:manual_configuration) { false }

      it 'no client provided' do
        expect(service.prometheus_client).to be_nil
      end
    end
  end

  describe '#prometheus_available?' do
    context 'clusters with installed prometheus' do
      before do
        create(:clusters_applications_prometheus, :installed, cluster: cluster)
      end

      context 'cluster belongs to project' do
        let(:cluster) { create(:cluster, projects: [project]) }

        it 'returns true' do
          expect(service.prometheus_available?).to be(true)
        end
      end

      context 'cluster belongs to projects group' do
        set(:group) { create(:group) }
        let(:project) { create(:prometheus_project, group: group) }
        let(:cluster) { create(:cluster_for_group, :with_installed_helm, groups: [group]) }

        it 'returns true' do
          expect(service.prometheus_available?).to be(true)
        end
      end

      context 'cluster belongs to gitlab instance' do
        let(:cluster) { create(:cluster, :instance) }

        it 'returns true' do
          expect(service.prometheus_available?).to be(true)
        end
      end
    end

    context 'clusters with updated prometheus' do
      let!(:cluster) { create(:cluster, projects: [project]) }
      let!(:prometheus) { create(:clusters_applications_prometheus, :updated, cluster: cluster) }

      it 'returns true' do
        expect(service.prometheus_available?).to be(true)
      end
    end

    context 'clusters without prometheus installed' do
      let(:cluster) { create(:cluster, projects: [project]) }
      let!(:prometheus) { create(:clusters_applications_prometheus, cluster: cluster) }

      it 'returns false' do
        expect(service.prometheus_available?).to be(false)
      end
    end

    context 'clusters without prometheus' do
      let(:cluster) { create(:cluster, projects: [project]) }

      it 'returns false' do
        expect(service.prometheus_available?).to be(false)
      end
    end

    context 'no clusters' do
      it 'returns false' do
        expect(service.prometheus_available?).to be(false)
      end
    end
  end

  describe '#synchronize_service_state before_save callback' do
    context 'no clusters with prometheus are installed' do
      context 'when service is inactive' do
        before do
          service.active = false
        end

        it 'activates service when manual_configuration is enabled' do
          expect { service.update!(manual_configuration: true) }.to change { service.active }.from(false).to(true)
        end

        it 'keeps service inactive when manual_configuration is disabled' do
          expect { service.update!(manual_configuration: false) }.not_to change { service.active }.from(false)
        end
      end

      context 'when service is active' do
        before do
          service.active = true
        end

        it 'keeps the service active when manual_configuration is enabled' do
          expect { service.update!(manual_configuration: true) }.not_to change { service.active }.from(true)
        end

        it 'inactivates the service when manual_configuration is disabled' do
          expect { service.update!(manual_configuration: false) }.to change { service.active }.from(true).to(false)
        end
      end
    end

    context 'with prometheus installed in the cluster' do
      before do
        allow(service).to receive(:prometheus_available?).and_return(true)
      end

      context 'when service is inactive' do
        before do
          service.active = false
        end

        it 'activates service when manual_configuration is enabled' do
          expect { service.update!(manual_configuration: true) }.to change { service.active }.from(false).to(true)
        end

        it 'activates service when manual_configuration is disabled' do
          expect { service.update!(manual_configuration: false) }.to change { service.active }.from(false).to(true)
        end
      end

      context 'when service is active' do
        before do
          service.active = true
        end

        it 'keeps service active when manual_configuration is enabled' do
          expect { service.update!(manual_configuration: true) }.not_to change { service.active }.from(true)
        end

        it 'keeps service active when manual_configuration is disabled' do
          expect { service.update!(manual_configuration: false) }.not_to change { service.active }.from(true)
        end
      end
    end
  end

  describe '#track_events after_commit callback' do
    before do
      allow(service).to receive(:prometheus_available?).and_return(true)
    end

    context "enabling manual_configuration" do
      it "tracks enable event" do
        service.update!(manual_configuration: false)

        expect(Gitlab::Tracking).to receive(:event).with('cluster:services:prometheus', 'enabled_manual_prometheus')

        service.update!(manual_configuration: true)
      end

      it "tracks disable event" do
        service.update!(manual_configuration: true)

        expect(Gitlab::Tracking).to receive(:event).with('cluster:services:prometheus', 'disabled_manual_prometheus')

        service.update!(manual_configuration: false)
      end
    end
  end
end
