# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Git::ProcessCommitWorkerPool, feature_category: :source_code_management do
  describe '#get_and_increment_delay' do
    let(:pool) { described_class.new(jobs_enqueued: jobs_enqueued) }

    context 'when under JOBS_THRESHOLD' do
      let(:jobs_enqueued) { 1999 }

      it 'does not return a delay' do
        expect(pool.get_and_increment_delay).to eq(0)
      end
    end

    context 'when over JOBS_THRESHHOLD' do
      let(:jobs_enqueued) { 3000 }

      it 'returns a delay' do
        expect(pool.get_and_increment_delay).to eq(60)
      end
    end

    context 'when called multiple times' do
      let(:jobs_enqueued) { 2049 }

      it 'calculates and increments a delay', :aggregate_failures do
        expect(pool.get_and_increment_delay).to eq(40)
        expect(pool.get_and_increment_delay).to eq(41)
      end
    end
  end

  describe '#try_schedule_commit' do
    let(:pool) { described_class.new }
    let(:sha) { 'abc123' }

    context 'when the SHA has not been scheduled yet' do
      it 'schedules and returns true for default: true' do
        expect(pool.try_schedule_commit(sha, default: true)).to be(true)
      end

      it 'schedules and returns true for default: false' do
        expect(pool.try_schedule_commit(sha, default: false)).to be(true)
      end
    end

    context 'when the SHA was already scheduled with default: true' do
      before do
        pool.try_schedule_commit(sha, default: true)
      end

      it 'returns false for a subsequent default: true' do
        expect(pool.try_schedule_commit(sha, default: true)).to be(false)
      end

      it 'returns false for a subsequent default: false' do
        expect(pool.try_schedule_commit(sha, default: false)).to be(false)
      end
    end

    context 'when the SHA was scheduled with default: false' do
      before do
        pool.try_schedule_commit(sha, default: false)
      end

      it 'returns false for a subsequent default: false' do
        expect(pool.try_schedule_commit(sha, default: false)).to be(false)
      end

      it 'returns true for default: true' do
        expect(pool.try_schedule_commit(sha, default: true)).to be(true)
      end
    end

    context 'when the SHA was upgraded from default: false to default: true' do
      before do
        pool.try_schedule_commit(sha, default: false)
        pool.try_schedule_commit(sha, default: true)
      end

      it 'returns false for a subsequent default: true' do
        expect(pool.try_schedule_commit(sha, default: true)).to be(false)
      end

      it 'returns false for a subsequent default: false' do
        expect(pool.try_schedule_commit(sha, default: false)).to be(false)
      end
    end
  end
end
