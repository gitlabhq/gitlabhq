# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectPool::CreateWorker, feature_category: :shared do
  let(:pool) { create(:pool_repository, :scheduled) }

  subject { described_class.new }

  describe '#perform' do
    context 'when the pool creation is successful' do
      it 'marks the pool as ready' do
        subject.perform(pool.id)

        expect(pool.reload).to be_ready
      end
    end

    context 'when a the pool already exists' do
      before do
        pool.create_object_pool
      end

      it 'marks the pool as ready' do
        subject.perform(pool.id)

        expect(pool.reload).to be_ready
      end
    end

    context 'when the server raises an unknown error' do
      before do
        allow_any_instance_of(PoolRepository).to receive(:create_object_pool).and_raise(GRPC::Internal)
      end

      it 'marks the pool as failed' do
        expect do
          subject.perform(pool.id)
        end.to raise_error(GRPC::Internal)

        expect(pool.reload).to be_failed
      end
    end

    context 'when the pool creation failed before' do
      let(:pool) { create(:pool_repository, :failed) }

      it 'deletes the pool first' do
        expect_any_instance_of(PoolRepository).to receive(:delete_object_pool)

        subject.perform(pool.id)

        expect(pool.reload).to be_ready
      end
    end
  end
end
