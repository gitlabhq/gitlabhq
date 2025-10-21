# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::ClaimService, feature_category: :cell do
  subject(:service) { described_class.instance }

  before do
    allow(Gitlab.config.cell).to receive(:enabled).and_return(true)
  end

  describe 'Singleton' do
    it 'includes Singleton module' do
      expect(described_class.ancestors).to include(Singleton)
    end

    it 'returns the same instance every time' do
      instance1 = described_class.instance
      instance2 = described_class.instance

      expect(instance1).to be(instance2)
      expect(instance1.object_id).to eq(instance2.object_id)
    end
  end

  describe 'method delegation' do
    let(:client_double) { instance_double(Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub) }
    let(:args) { { foo: 'bar' } }

    before do
      allow(service).to receive(:client).and_return(client_double)
    end

    it 'delegates #begin_update to the client' do
      expect(client_double).to receive(:begin_update).with(args)
      service.begin_update(args)
    end

    it 'delegates #commit_update to the client' do
      expect(client_double).to receive(:commit_update).with(args)
      service.commit_update(args)
    end

    it 'delegates #rollback_update to the client' do
      expect(client_double).to receive(:rollback_update).with(args)
      service.rollback_update(args)
    end
  end

  describe '#service_class' do
    it 'returns the correct gRPC stub class' do
      result = service.send(:service_class)
      expect(result).to eq(Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub)
    end
  end
end
