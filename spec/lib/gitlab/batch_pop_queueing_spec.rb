# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BatchPopQueueing do
  include ExclusiveLeaseHelpers
  using RSpec::Parameterized::TableSyntax

  describe '#initialize' do
    where(:namespace, :queue_id, :expect_error, :error_type) do
      'feature'  | '1' | false  | nil
      :feature   | '1' | false  | nil
      nil        | '1' | true   | NoMethodError
      'feature'  | nil | true   | NoMethodError
      ''         | '1' | true   | ArgumentError
      'feature'  | ''  | true   | ArgumentError
      'feature'  | 1   | true   | NoMethodError
    end

    with_them do
      it do
        if expect_error
          expect { described_class.new(namespace, queue_id) }.to raise_error(error_type)
        else
          expect { described_class.new(namespace, queue_id) }.not_to raise_error
        end
      end
    end
  end

  describe '#safe_execute', :clean_gitlab_redis_queues do
    subject { queue.safe_execute(new_items, lock_timeout: lock_timeout) }

    let(:queue) { described_class.new(namespace, queue_id) }
    let(:namespace) { 'feature' }
    let(:queue_id) { '1' }
    let(:lock_timeout) { 10.minutes }
    let(:new_items) { %w[A B] }
    let(:lock_key) { queue.send(:lock_key) }
    let(:queue_key) { queue.send(:queue_key) }

    it 'enqueues new items always' do
      Gitlab::Redis::Queues.with do |redis|
        expect(redis).to receive(:sadd).with(queue_key, new_items)
        expect(redis).to receive(:expire).with(queue_key, (lock_timeout + described_class::EXTRA_QUEUE_EXPIRE_WINDOW).to_i)
      end

      subject
    end

    it 'yields the new items with exclusive lease' do
      uuid = 'test'
      expect_to_obtain_exclusive_lease(lock_key, uuid, timeout: lock_timeout)
      expect_to_cancel_exclusive_lease(lock_key, uuid)

      expect { |b| queue.safe_execute(new_items, lock_timeout: lock_timeout, &b) }
        .to yield_with_args(match_array(new_items))
    end

    it 'returns the result and no items in the queue' do
      expect(subject[:status]).to eq(:finished)
      expect(subject[:new_items]).to be_empty

      Gitlab::Redis::Queues.with do |redis|
        expect(redis.llen(queue_key)).to be(0)
      end
    end

    context 'when new items are enqueued during the process' do
      it 'returns the result with newly added items' do
        result = queue.safe_execute(new_items) do
          queue.safe_execute(['C'])
        end

        expect(result[:status]).to eq(:finished)
        expect(result[:new_items]).to eq(['C'])

        Gitlab::Redis::Queues.with do |redis|
          expect(redis.scard(queue_key)).to be(1)
        end
      end
    end

    context 'when interger items are enqueued' do
      let(:new_items) { [1, 2, 3] }

      it 'yields as String values' do
        expect { |b| queue.safe_execute(new_items, lock_timeout: lock_timeout, &b) }
          .to yield_with_args(%w[1 2 3])
      end
    end

    context 'when the queue key does not exist in Redis' do
      before do
        allow(queue).to receive(:enqueue) { }
      end

      it 'yields empty array' do
        expect { |b| queue.safe_execute(new_items, lock_timeout: lock_timeout, &b) }
          .to yield_with_args([])
      end
    end

    context 'when the other process has already been working on the queue' do
      before do
        stub_exclusive_lease_taken(lock_key, timeout: lock_timeout)
      end

      it 'does not yield the block' do
        expect { |b| queue.safe_execute(new_items, lock_timeout: lock_timeout, &b) }
          .not_to yield_control
      end

      it 'returns the result' do
        expect(subject[:status]).to eq(:enqueued)
      end
    end

    context 'when a duplicate item is enqueued' do
      it 'returns the poped items to the queue and raise an error' do
        expect { |b| queue.safe_execute(%w[1 1 2 2], &b) }
          .to yield_with_args(match_array(%w[1 2]))
      end
    end

    context 'when there are two queues' do
      it 'enqueues items to each queue' do
        queue_1 = described_class.new(namespace, '1')
        queue_2 = described_class.new(namespace, '2')

        result_2 = nil

        result_1 = queue_1.safe_execute(['A']) do |_|
          result_2 = queue_2.safe_execute(['B']) do |_|
            queue_1.safe_execute(['C'])
            queue_2.safe_execute(['D'])
          end
        end

        expect(result_1[:status]).to eq(:finished)
        expect(result_1[:new_items]).to eq(['C'])
        expect(result_2[:status]).to eq(:finished)
        expect(result_2[:new_items]).to eq(['D'])
      end
    end
  end
end
