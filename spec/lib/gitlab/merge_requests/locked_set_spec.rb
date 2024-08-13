# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::LockedSet, :clean_gitlab_redis_shared_state, feature_category: :code_review_workflow do
  describe '.add' do
    it 'adds item to redis set' do
      expect { described_class.add(1) }
        .to change { described_class.all }
        .from([])
        .to(%w[1])
    end

    it 'adds collection to redis set' do
      expect { described_class.add([1, 2]) }
        .to change { described_class.all }
        .from([])
        .to(%w[1 2])
    end

    context 'when connection error occurs' do
      before do
        allow(Gitlab::Redis::SharedState)
          .to receive(:with)
          .and_raise(Redis::BaseConnectionError)
      end

      it 'does not raise an error' do
        expect { described_class.add(1) }.not_to raise_error
      end

      context 'when rescue_connection_error is set to false' do
        it 'raises an error' do
          expect { described_class.add(1, rescue_connection_error: false) }
            .to raise_error(Redis::BaseConnectionError)
        end
      end
    end
  end

  describe '.remove' do
    it 'removes item from redis set' do
      described_class.add(1)

      expect { described_class.remove(1) }
        .to change { described_class.all }
        .from(%w[1])
        .to([])
    end

    it 'removes collection from set' do
      described_class.add([1, 2])

      expect { described_class.remove([1, 2]) }
        .to change { described_class.all }
        .from(%w[1 2])
        .to([])
    end
  end

  describe '.all' do
    it 'returns items from redis set' do
      described_class.add([1, 2])

      expect(described_class.all).to eq(%w[1 2])
    end
  end

  describe '.each_batch' do
    it 'iterates items in set in batches' do
      described_class.add([*1..20])

      total = 0

      described_class.each_batch(2) { |batch| total += batch.size }

      expect(total).to eq(20)
    end
  end
end
