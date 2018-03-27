require 'spec_helper'

describe PrometheusService, :use_clean_rails_memory_store_caching do
  include PrometheusHelpers
  include ReactiveCachingHelpers

  let(:project) { create(:prometheus_project) }
  let(:service) { project.prometheus_service }

  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe 'Validations' do
    context 'when manual_configuration is enabled' do
      before do
        subject.manual_configuration = true
      end

      it { is_expected.to validate_presence_of(:api_url) }
    end

    context 'when manual configuration is disabled' do
      before do
        subject.manual_configuration = false
      end

      it { is_expected.not_to validate_presence_of(:api_url) }
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
    context 'manual configuration is enabled' do
      let(:api_url) { 'http://some_url' }

      before do
        subject.active = true
        subject.manual_configuration = true
        subject.api_url = api_url
      end

      it 'returns rest client from api_url' do
        expect(subject.prometheus_client.url).to eq(api_url)
      end
    end

    context 'manual configuration is disabled' do
      let(:api_url) { 'http://some_url' }

      before do
        subject.manual_configuration = false
        subject.api_url = api_url
      end

      it 'no client provided' do
        expect(subject.prometheus_client).to be_nil
      end
    end
  end

  describe '#prometheus_installed?' do
    context 'clusters with installed prometheus' do
      let!(:cluster) { create(:cluster, projects: [project]) }
      let!(:prometheus) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

      it 'returns true' do
        expect(service.prometheus_installed?).to be(true)
      end
    end

    context 'clusters without prometheus installed' do
      let(:cluster) { create(:cluster, projects: [project]) }
      let!(:prometheus) { create(:clusters_applications_prometheus, cluster: cluster) }

      it 'returns false' do
        expect(service.prometheus_installed?).to be(false)
      end
    end

    context 'clusters without prometheus' do
      let(:cluster) { create(:cluster, projects: [project]) }

      it 'returns false' do
        expect(service.prometheus_installed?).to be(false)
      end
    end

    context 'no clusters' do
      it 'returns false' do
        expect(service.prometheus_installed?).to be(false)
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
        allow(service).to receive(:prometheus_installed?).and_return(true)
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
end
