# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::MultiStoreConnectionPool, feature_category: :scalability do
  describe '#with' do
    let(:conn_a) { Redis.new(url: 'redis://localhost:6379') }
    let(:conn_b) { Redis.new(url: 'redis://localhost:6380') }
    let(:pool_a) { ConnectionPool.new(size: 2) { conn_a } }
    let(:pool_b) { ConnectionPool.new(size: 2) { conn_b } }
    let(:multistore) { Gitlab::Redis::MultiStore.create_using_pool(pool_a, pool_b, 'test') }
    let(:multistore_pool) { described_class.new(size: 2) { multistore } }

    before do
      skip_default_enabled_yaml_check
    end

    it 'extends ConnectionPool' do
      expect(multistore_pool.is_a?(::ConnectionPool)).to eq(true)
    end

    shared_examples 'handles connection borrowing' do
      it 'yields a multistore with already borrowed connections' do
        multistore_pool.with do |ms|
          expect(ms).to be_an_instance_of(Gitlab::Redis::MultiStore)
          expect(ms.primary_store).to eq(conn_a)
          expect(ms.secondary_store).to eq(conn_b)
        end
      end
    end

    context 'with both feature flags enabled' do
      before do
        stub_feature_flags(use_primary_store_as_default_for_test: true,
          use_primary_and_secondary_stores_for_test: true)
      end

      it_behaves_like 'handles connection borrowing'
    end

    context 'with use_primary_and_secondary_stores_for_test disabled' do
      before do
        stub_feature_flags(use_primary_store_as_default_for_test: true,
          use_primary_and_secondary_stores_for_test: false)
      end

      it_behaves_like 'handles connection borrowing'
    end

    context 'with use_primary_store_as_default_for_test disabled' do
      before do
        stub_feature_flags(use_primary_store_as_default_for_test: false,
          use_primary_and_secondary_stores_for_test: true)
      end

      it_behaves_like 'handles connection borrowing'
    end

    context 'with feature flags disabled' do
      before do
        stub_feature_flags(use_primary_store_as_default_for_test: false,
          use_primary_and_secondary_stores_for_test: false)
      end

      it_behaves_like 'handles connection borrowing'
    end

    context 'when non-MultiStore is provided' do
      let(:multistore) { conn_a }

      it 'passes connection through without errors' do
        multistore_pool.with do |c|
          expect(c).to eq(conn_a)
        end
      end
    end
  end
end
