# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Artifacts::BucketManager, :clean_gitlab_redis_shared_state,
  feature_category: :job_artifacts do
  describe '.claim_bucket' do
    context 'when buckets are available' do
      let(:buckets) { [0, 1, 2] }

      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.sadd(described_class::AVAILABLE_BUCKETS_KEY, buckets.map(&:to_s))
        end
      end

      it 'atomically claims a bucket and tracks it in occupied set' do
        claimed_bucket = described_class.claim_bucket

        Gitlab::Redis::SharedState.with do |redis|
          available = redis.smembers(described_class::AVAILABLE_BUCKETS_KEY).map(&:to_i)
          occupied = redis.zrange(described_class::OCCUPIED_BUCKETS_KEY, 0, -1).map(&:to_i)

          expect(available).not_to include(claimed_bucket)
          expect(available.size).to eq(2)
          expect(occupied).to contain_exactly(claimed_bucket)
          expect(buckets).to include(claimed_bucket)
        end
      end

      it 'logs bucket claim info immediately' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Bucket claimed for bulk artifact deletion',
            claimed_bucket: an_instance_of(Integer),
            available_buckets_before: an_instance_of(Array),
            available_buckets_after: an_instance_of(Array),
            occupied_buckets_after: an_instance_of(Array)
          )
        )

        described_class.claim_bucket
      end
    end

    context 'when no buckets are available' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.del(described_class::AVAILABLE_BUCKETS_KEY)
        end
      end

      it 'returns nil' do
        expect(described_class.claim_bucket).to be_nil
      end

      it 'does not log' do
        expect(Gitlab::AppLogger).not_to receive(:info)
        described_class.claim_bucket
      end
    end
  end

  describe '.release_bucket' do
    let(:bucket) { 0 }
    let(:max_buckets) { 5 }

    before do
      Gitlab::Redis::SharedState.with do |redis|
        redis.zadd(described_class::OCCUPIED_BUCKETS_KEY, Time.current.to_i, bucket.to_s)
      end
    end

    it 'releases the bucket back to available set' do
      described_class.release_bucket(bucket, max_buckets: max_buckets)

      Gitlab::Redis::SharedState.with do |redis|
        available = redis.smembers(described_class::AVAILABLE_BUCKETS_KEY)
        occupied = redis.zrange(described_class::OCCUPIED_BUCKETS_KEY, 0, -1)

        expect(available).to contain_exactly(bucket.to_s)
        expect(occupied).to be_empty
      end
    end

    context 'when bucket is invalid due to scale-down' do
      let(:bucket) { 7 }
      let(:max_buckets) { 5 }

      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.zadd(described_class::OCCUPIED_BUCKETS_KEY, Time.current.to_i, bucket.to_s)
        end
      end

      it 'does not re-add invalid bucket to available after scale-down' do
        described_class.release_bucket(bucket, max_buckets: max_buckets)

        Gitlab::Redis::SharedState.with do |redis|
          available = redis.smembers(described_class::AVAILABLE_BUCKETS_KEY)
          occupied = redis.zrange(described_class::OCCUPIED_BUCKETS_KEY, 0, -1)

          # Bucket 7 should not be in either set after scale-down to max 5
          expect(available).not_to include(bucket.to_s)
          expect(occupied).not_to include(bucket.to_s)
        end
      end
    end
  end

  describe '.recover_stale_buckets' do
    let(:stale_bucket) { 3 }
    let(:active_bucket) { 4 }

    before do
      Gitlab::Redis::SharedState.with do |redis|
        redis.zadd(
          described_class::OCCUPIED_BUCKETS_KEY,
          15.minutes.ago.to_i,
          stale_bucket.to_s
        )
        redis.zadd(
          described_class::OCCUPIED_BUCKETS_KEY,
          1.minute.ago.to_i,
          active_bucket.to_s
        )
      end
    end

    it 'recovers stale buckets and moves them to available' do
      expect(described_class.recover_stale_buckets).to eq(['3'])
      Gitlab::Redis::SharedState.with do |redis|
        available = redis.smembers(described_class::AVAILABLE_BUCKETS_KEY).map(&:to_i)
        occupied = redis.zrange(described_class::OCCUPIED_BUCKETS_KEY, 0, -1).map(&:to_i)

        expect(available).to include(stale_bucket)
        expect(occupied).not_to include(stale_bucket)
        expect(occupied).to include(active_bucket)
      end
    end
  end

  describe '.enqueue_missing_buckets' do
    let(:max_buckets) { 5 }

    it 'enqueues all buckets when none exist' do
      expect(described_class.enqueue_missing_buckets(max_buckets: max_buckets)).to eq(
        {
          available: [],
          missing: [0, 1, 2, 3, 4],
          occupied: []
        }
      )

      Gitlab::Redis::SharedState.with do |redis|
        buckets = redis.smembers(described_class::AVAILABLE_BUCKETS_KEY).map(&:to_i)
        expect(buckets).to match_array((0...max_buckets).to_a)
      end
    end

    context 'when some buckets are already available' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.sadd(described_class::AVAILABLE_BUCKETS_KEY, [0, 1])
        end
      end

      it 'only adds missing buckets' do
        described_class.enqueue_missing_buckets(max_buckets: max_buckets)

        Gitlab::Redis::SharedState.with do |redis|
          buckets = redis.smembers(described_class::AVAILABLE_BUCKETS_KEY).map(&:to_i)
          expect(buckets).to match_array((0...max_buckets).to_a)
        end
      end
    end

    context 'when some buckets are occupied' do
      let(:occupied_bucket) { 2 }

      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.zadd(
            described_class::OCCUPIED_BUCKETS_KEY,
            Time.current.to_i,
            occupied_bucket.to_s
          )
        end
      end

      it 'only enqueues unoccupied buckets' do
        described_class.enqueue_missing_buckets(max_buckets: max_buckets)

        Gitlab::Redis::SharedState.with do |redis|
          available = redis.smembers(described_class::AVAILABLE_BUCKETS_KEY).map(&:to_i)
          occupied = redis.zrange(described_class::OCCUPIED_BUCKETS_KEY, 0, -1).map(&:to_i)

          expect(available).not_to include(occupied_bucket)
          expect(occupied).to include(occupied_bucket)
          expect(available.size).to eq(max_buckets - 1)
        end
      end
    end

    context 'when all buckets are occupied' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          (0...max_buckets).each do |bucket|
            redis.zadd(
              described_class::OCCUPIED_BUCKETS_KEY,
              Time.current.to_i,
              bucket.to_s
            )
          end
        end
      end

      it 'does not enqueue any buckets' do
        described_class.enqueue_missing_buckets(max_buckets: max_buckets)

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.scard(described_class::AVAILABLE_BUCKETS_KEY)).to eq(0)
        end
      end
    end
  end
end
