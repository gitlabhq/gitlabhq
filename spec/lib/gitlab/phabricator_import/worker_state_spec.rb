# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PhabricatorImport::WorkerState, :clean_gitlab_redis_shared_state do
  subject(:state) { described_class.new('weird-project-id') }

  let(:key) { 'phabricator-import/jobs/project-weird-project-id/job-count' }

  describe '#add_job' do
    it 'increments the counter for jobs' do
      set_value(3)

      expect { state.add_job }.to change { get_value }.from('3').to('4')
    end
  end

  describe '#remove_job' do
    it 'decrements the counter for jobs' do
      set_value(3)

      expect { state.remove_job }.to change { get_value }.from('3').to('2')
    end
  end

  describe '#running_count' do
    it 'reads the value' do
      set_value(9)

      expect(state.running_count).to eq(9)
    end

    it 'returns 0 when nothing was set' do
      expect(state.running_count).to eq(0)
    end
  end

  def set_value(value)
    redis.with { |r| r.set(key, value) }
  end

  def get_value
    redis.with { |r| r.get(key) }
  end

  def redis
    Gitlab::Redis::SharedState
  end
end
