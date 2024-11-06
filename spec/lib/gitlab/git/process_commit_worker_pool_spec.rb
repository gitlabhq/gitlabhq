# frozen_string_literal: true

require 'spec_helper'

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

      it 'calculates and increments a delay' do
        expect(pool.get_and_increment_delay).to eq(40)
        expect(pool.get_and_increment_delay).to eq(41)
      end
    end
  end
end
