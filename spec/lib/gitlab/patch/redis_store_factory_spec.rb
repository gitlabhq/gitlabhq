# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::RedisStoreFactory, feature_category: :redis do
  describe '#create' do
    let(:params) { { host: 'localhost' } }

    subject(:factory_create) { ::Redis::Store::Factory.create(params) } # rubocop:disable Rails/SaveBang -- redis-store does not implement create!

    context 'when using standalone Redis' do
      it 'does not create ClusterStore' do
        expect(Gitlab::Redis::ClusterStore).not_to receive(:new)

        factory_create
      end
    end

    context 'when using a Redis Cluster' do
      let(:params) { { nodes: ["redis://localhost:6001", "redis://localhost:6002"] } }

      it 'creates a ClusterStore' do
        expect(Gitlab::Redis::ClusterStore).to receive(:new).with(params.merge({ raw: false }))

        factory_create
      end
    end
  end
end
