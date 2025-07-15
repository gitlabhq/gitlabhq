# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobRedisState, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let(:job) { build_stubbed(:ci_build) }

  describe '.new' do
    it { expect(described_class.new(enqueue_immediately: true)).to have_attributes(enqueue_immediately: true) }
    it { expect(described_class.new(enqueue_immediately: false)).to have_attributes(enqueue_immediately: false) }
    it { expect(described_class.new).to have_attributes(enqueue_immediately: false) }
  end

  describe '.find_or_initialize_by' do
    it 'returns a new record' do
      record = described_class.find_or_initialize_by(job: job)

      expect(record).to be_an_instance_of(described_class)
    end

    context 'when a record already exists in Redis' do
      it 'returns existing data' do
        record = described_class.new(job: job, enqueue_immediately: true)
        expect(record.save).to be(true)

        found_record = described_class.find_or_initialize_by(job: job)

        expect(found_record.attributes).to match(record.attributes)
      end
    end
  end

  describe '#save' do
    it 'persists the record' do
      record = described_class.new(job: job, enqueue_immediately: true)

      expect(record.save).to be(true)

      described_class.with_redis do |redis|
        key = described_class.redis_key(job.project_id, job.id)

        expect(redis.hgetall(key)).to eq({ 'enqueue_immediately' => '_b:1' })
        expect(redis.ttl(key)).to be_between(0, described_class::REDIS_TTL)
      end
    end

    context 'when trying to save for a not persisted job' do
      it 'raises an error' do
        expect(job).to receive(:persisted?).and_return(false)
        record = described_class.new(job: job)

        expect { record.save }.to raise_error(described_class::UnpersistedJobError) # rubocop:disable Rails/SaveBang -- Not Rails
      end
    end
  end

  describe '#update' do
    it 'updates the record' do
      record = described_class.new(job: job, enqueue_immediately: true)
      key = described_class.redis_key(job.project_id, job.id)

      expect(record.save).to be(true)

      described_class.with_redis do |redis|
        expect(redis.hgetall(key)).to eq({ 'enqueue_immediately' => '_b:1' })
      end

      expect(record.update(enqueue_immediately: false)).to be(true)

      described_class.with_redis do |redis|
        expect(redis.hgetall(key)).to eq({ 'enqueue_immediately' => '_b:0' })
      end
    end

    it 'does not accept job argument' do
      expect { described_class.new.update(job: job) }.to raise_error(ActiveModel::UnknownAttributeError) # rubocop:disable Rails/SaveBang -- Not Rails
    end
  end

  context 'when persisting processable records' do
    let(:job) { build(:ci_build) }

    it 'auto saves after the job is persisted' do
      record = job.redis_state
      record.enqueue_immediately = true

      expect(described_class.find_or_initialize_by(job: job).enqueue_immediately).to be(false)
      expect(job.save!).to be_truthy
      expect(described_class.find_or_initialize_by(job: job).enqueue_immediately).to be(true)
    end
  end
end
