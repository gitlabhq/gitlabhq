# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedisMigrationWorker, :clean_gitlab_redis_shared_state, feature_category: :redis do
  describe '.fetch_migrator!' do
    it 'raise error if class does not exist' do
      expect { described_class.fetch_migrator!('UnknownClass') }.to raise_error(NotImplementedError)
    end

    context 'when class exists' do
      it 'returns an instance' do
        expect(
          described_class.fetch_migrator!('BackfillProjectPipelineStatusTtl')
        ).to be_a Gitlab::BackgroundMigration::Redis::BackfillProjectPipelineStatusTtl
      end
    end
  end

  describe '#perform' do
    let(:job_class_name) { 'SampleJob' }
    let(:migrator_class) do
      Class.new do
        def perform(keys)
          keys.each { |key| redis.set(key, "adjusted", ex: 10) }
        end

        def scan_match_pattern
          'sample:*:pattern'
        end

        def redis
          ::Gitlab::Redis::Cache.redis
        end
      end
    end

    let(:migrator) { migrator_class.new }

    before do
      allow(described_class).to receive(:fetch_migrator!).with(job_class_name).and_return(migrator)

      100.times do |i|
        migrator.redis.set("sample:#{i}:pattern", i)
      end
    end

    it 'runs migration logic on scanned keys' do
      expect(migrator).to receive(:perform).at_least(:once)

      subject.perform(job_class_name, '0')
    end

    context 'when job exceeds deadline' do
      before do
        # stub Time.now to force the 3rd invocation to timeout
        now = Time.now # rubocop:disable Rails/TimeZone
        allow(Time).to receive(:now).and_return(now, now, now + 5.minutes)
      end

      it 'enqueues another job and returns' do
        expect(described_class).to receive(:perform_async)

        # use smaller scan_size to ensure multiple scans are required
        subject.perform(job_class_name, '0', { scan_size: 10 })
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [job_class_name, '0'] }
    end
  end
end
