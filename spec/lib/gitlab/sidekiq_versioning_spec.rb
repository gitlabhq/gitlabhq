# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqVersioning, :clean_gitlab_redis_queues do
  before do
    allow(Gitlab::SidekiqConfig).to receive(:worker_queues).and_return(%w[foo bar])
  end

  describe '.install!' do
    it 'registers all versionless and versioned queues with Redis' do
      described_class.install!

      queues = Sidekiq::Queue.all.map(&:name)
      expect(queues).to include('foo')
      expect(queues).to include('bar')
    end
  end
end
