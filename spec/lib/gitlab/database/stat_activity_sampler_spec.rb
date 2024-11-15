# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::StatActivitySampler,
  :clean_gitlab_redis_shared_state, feature_category: :database do
  let(:conn) { ActiveRecord::Base.connection }

  subject(:sampler) { described_class.new(conn) }

  describe '.sample' do
    it 'runs execute for each loadbalancer base model' do
      expect_next_instances_of(described_class, Gitlab::Database::LoadBalancing.base_models.size) do |inst|
        expect(inst).to receive(:execute)
      end

      described_class.sample
    end
  end

  describe '#execute' do
    let(:response) do
      [
        { 'application' => 'sidekiq', 'endpoint' => 'WorkerA', 'database' => 'gitlabhq_test',
          'state' => 'active', 'count' => 10 },
        { 'application' => 'sidekiq', 'endpoint' => 'WorkerB', 'database' => 'gitlabhq_test',
          'state' => 'active', 'count' => 10 },
        { 'application' => 'sidekiq', 'endpoint' => 'WorkerB', 'database' => 'gitlabhq_test',
          'state' => 'idle', 'count' => 10 },
        { 'application' => 'sidekiq', 'endpoint' => 'WorkerA', 'database' => 'gitlabhq_test_ci',
          'state' => 'active', 'count' => 10 }
      ]
    end

    let(:hash_key) { "gitlab:pg_stat_sampler:main:sidekiq:samples" }
    let(:lease_key) { "gitlab:exclusive_lease:#{sampler.instance_variable_get(:@lease_key)}" }

    before do
      allow(conn).to receive(:execute).and_return(response)
    end

    context 'when does not acquire exclusive lease' do
      before do
        sampler.try_obtain_lease { 'pass' }
      end

      it 'does not lookup table' do
        expect(conn).not_to receive(:execute)
        sampler.execute
      end
    end

    it 'writes data into redis and prevents writes within the sampling window' do
      travel_to(Time.now.utc) do
        expect(Gitlab::Database::StatActivity).to receive(:write).with(:main, response)
        sampler.execute
      end

      # 2nd immediate write fails since exclusive lease only release after 15s
      expect(Gitlab::Database::StatActivity).not_to receive(:write)
      sampler.execute
    end
  end
end
