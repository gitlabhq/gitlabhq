# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RedundantPipelines::CandidateCache, :clean_gitlab_redis_shared_state,
  feature_category: :continuous_integration do
  subject(:cache) { described_class.for(project_id: 1, ref: 'main') }

  def key(pipeline_id, partition_id: 100)
    Gitlab::Ci::RedundantPipelines::PipelineKey.new(pipeline_id, partition_id)
  end

  describe '#register' do
    it 'offers the pipeline to later pipelines' do
      cache.register(key(10))

      expect(cache).to be_registered(key(10))
    end

    it 'is idempotent' do
      cache.register(key(10))
      cache.register(key(10))

      expect(cache.size).to eq(1)
    end

    it 'leaves the pipelines it does not supersede alone' do
      cache.register(key(20))
      cache.register(key(10))

      expect(cache).to be_registered(key(10))
      expect(cache).to be_registered(key(20))
    end

    it 'expires the pipelines it stores' do
      cache.register(key(10))

      redis_key = "ci:redundant_pipelines:1:#{Digest::SHA256.hexdigest('main')}:candidates"
      ttl = Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }

      expect(ttl).to be_between(1, described_class::TTL)
    end

    it 'uses a single redis call' do
      cache.register(key(5)) # warmup cache

      recorder = RedisCommands::Recorder.new { cache.register(key(10)) }

      expect(recorder.count).to eq(1)
    end

    context 'when a ref piles up more pipelines than the cache holds' do
      before do
        stub_const("#{described_class}::MAX_SIZE", 3)
      end

      it 'holds the cache at its maximum size' do
        1.upto(10) { |id| cache.register(key(id)) }

        expect(cache.size).to eq(3)
      end

      it 'drops the oldest pipelines and keeps the newest' do
        1.upto(5) { |id| cache.register(key(id)) }

        expect(cache).to be_registered(key(5))
        expect(cache).to be_registered(key(4))
        expect(cache).to be_registered(key(3))
        expect(cache).not_to be_registered(key(2))
        expect(cache).not_to be_registered(key(1))
      end

      it 'drops nothing while the ref stays within the maximum' do
        1.upto(3) { |id| cache.register(key(id)) }

        expect(cache.size).to eq(3)
        expect(cache).to be_registered(key(1))
      end
    end
  end

  describe '#claim_before' do
    it 'returns nothing for the first pipeline on a ref' do
      expect(cache.claim_before(key(10))).to be_empty
    end

    it 'claims older pipelines without registering the given one' do
      cache.register(key(10))

      expect(cache.claim_before(key(20))).to contain_exactly(key(10))
      expect(cache.size).to eq(0)
    end

    it 'claims each pipeline only once' do
      cache.register(key(10))
      cache.claim_before(key(20))

      expect(cache.claim_before(key(30))).to be_empty
    end

    it 'leaves newer pipelines alone when an older pipeline arrives late' do
      cache.register(key(20))

      expect(cache.claim_before(key(10))).to be_empty
      expect(cache).to be_registered(key(20))
    end

    it 'keeps the partition of every pipeline it returns' do
      cache.register(key(10, partition_id: 101))

      expect(cache.claim_before(key(20, partition_id: 102)))
        .to contain_exactly(key(10, partition_id: 101))
    end

    it 'claims the newest pipelines first, up to the given limit' do
      1.upto(3) { |id| cache.register(key(id * 10)) }

      expect(cache.claim_before(key(40), limit: 2))
        .to eq([key(30), key(20)])
    end

    it 'leaves the pipelines beyond the limit for a later pipeline' do
      1.upto(3) { |id| cache.register(key(id * 10)) }
      cache.claim_before(key(40), limit: 2)

      expect(cache.claim_before(key(50))).to contain_exactly(key(10))
    end

    it 'never gives the same pipeline to two callers' do
      1.upto(50) { |id| cache.register(key(id)) }

      claimed = [60, 61, 62].flat_map { |id| cache.claim_before(key(id)) }

      expect(claimed.uniq.size).to eq(claimed.size)
      expect(claimed).to include(key(1), key(50))
    end

    it 'uses a single redis call' do
      cache.register(key(10))
      cache.claim_before(key(1)) # warmup cache

      recorder = RedisCommands::Recorder.new { cache.claim_before(key(20)) }

      expect(recorder.count).to eq(1)
    end
  end

  describe '#delete' do
    it 'takes the pipeline out and lets it be registered again' do
      cache.register(key(10))
      cache.delete(key(10))

      cache.register(key(10))

      expect(cache).to be_registered(key(10))
    end

    it 'leaves other pipelines alone' do
      cache.register(key(10))
      cache.register(key(20))

      cache.delete(key(10))

      expect(cache).not_to be_registered(key(10))
      expect(cache).to be_registered(key(20))
    end
  end

  describe '#registered?' do
    it 'is false for a pipeline no one registered' do
      expect(cache).not_to be_registered(key(10))
    end

    it 'tells the partitions of one pipeline id apart' do
      cache.register(key(10, partition_id: 101))

      expect(cache).to be_registered(key(10, partition_id: 101))
      expect(cache).not_to be_registered(key(10, partition_id: 102))
    end
  end

  describe '#size' do
    it 'counts the pipelines on this project and ref' do
      cache.register(key(10))
      cache.register(key(20))

      expect(cache.size).to eq(2)
    end

    it 'is zero for a ref no pipeline has run on' do
      expect(cache.size).to eq(0)
    end
  end

  describe 'scoping' do
    it 'keeps refs of one project apart' do
      cache.register(key(10))

      other_ref = described_class.for(project_id: 1, ref: 'feature/a')

      expect(other_ref.claim_before(key(20))).to be_empty
    end

    it 'keeps projects using the same ref apart' do
      cache.register(key(10))

      other_project = described_class.for(project_id: 2, ref: 'main')

      expect(other_project.claim_before(key(20))).to be_empty
    end
  end

  context 'when the cached pipelines are gone' do
    it 'claims nothing and does not rebuild them' do
      cache.register(key(10))
      cache.register(key(20))

      Gitlab::Redis::SharedState.with(&:flushdb)

      expect(cache.claim_before(key(30))).to be_empty
      expect(cache.size).to eq(0)
    end
  end
end
