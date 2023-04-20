# frozen_string_literal: true

RSpec.describe ObjectPool::DestroyWorker, feature_category: :shared do
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
    end
  end
end
