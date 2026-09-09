# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectPool::DestroyWorker, feature_category: :source_code_management do
  describe '#perform' do
    context 'when no pool is in the database' do
      it "doesn't raise an error" do
        expect do
          described_class.new.perform(987654321)
        end.not_to raise_error
      end
    end

    context 'when a pool is present' do
      let(:pool) { create(:pool_repository, :obsolete) }

      subject { described_class.new }

      it 'requests Gitaly to remove the object pool' do
        expect(Gitlab::GitalyClient).to receive(:call).with(
          pool.shard_name,
          :object_pool_service,
          :delete_object_pool,
          Object,
          timeout: Gitlab::GitalyClient.long_timeout
        )

        subject.perform(pool.id)
      end

      it 'destroys the pool' do
        subject.perform(pool.id)

        expect(PoolRepository.find_by_id(pool.id)).to be_nil
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [pool.id] }

        it 'destroys the pool' do
          perform_multiple(job_args)

          expect(PoolRepository.find_by_id(pool.id)).to be_nil
        end
      end

      context 'when the Gitaly call fails' do
        before do
          allow_next_instance_of(Gitlab::GitalyClient::ObjectPoolService) do |service|
            allow(service).to receive(:delete).and_raise(GRPC::Unavailable)
          end
        end

        it 'does not destroy the pool record' do
          expect { subject.perform(pool.id) }.to raise_error(GRPC::Unavailable)

          expect(PoolRepository.find_by_id(pool.id)).to eq(pool)
        end
      end
    end
  end
end
