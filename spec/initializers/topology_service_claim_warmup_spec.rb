# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'config/initializers/topology_service_claim_warmup', feature_category: :cell do
  let(:load_initializer) do
    load Rails.root.join('config/initializers/topology_service_claim_warmup.rb')
  end

  context 'when cell is enabled' do
    before do
      stub_config_cell({ enabled: true, id: 1 })
      allow(Rails.env).to receive(:test?).and_return(false)
    end

    it 'pre-warms the claim service connection on worker start' do
      claim_service = Gitlab::TopologyServiceClient::ClaimService.instance
      allow(claim_service).to receive(:warmup!)
      expect(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start).and_yield

      load_initializer

      expect(claim_service).to have_received(:warmup!)
    end

    it 'tracks the error without raising when warmup fails' do
      claim_service = Gitlab::TopologyServiceClient::ClaimService.instance
      allow(claim_service).to receive(:warmup!).and_raise(GRPC::Unavailable.new)
      allow(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start).and_yield

      expect(Gitlab::ErrorTracking).to receive(:track_exception)
        .with(instance_of(GRPC::Unavailable), feature_category: :cell)

      expect { load_initializer }.not_to raise_error
    end
  end

  context 'when cell is disabled' do
    before do
      stub_config_cell({ enabled: false })
    end

    it 'does not register a worker-start hook' do
      expect(Gitlab::Cluster::LifecycleEvents).not_to receive(:on_worker_start)

      load_initializer
    end
  end

  context 'when in test environment' do
    before do
      stub_config_cell({ enabled: true, id: 1 })
    end

    it 'does not register a worker-start hook' do
      expect(Gitlab::Cluster::LifecycleEvents).not_to receive(:on_worker_start)

      load_initializer
    end
  end
end
