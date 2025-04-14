# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::StatActivity,
  :clean_gitlab_redis_shared_state, feature_category: :database do
  describe '.write' do
    it 'initialises and calls instance method #write' do
      expect_next_instance_of(described_class) do |inst|
        expect(inst).to receive(:write)
      end

      described_class.write(:main, [])
    end
  end

  describe '#write' do
    subject(:sampler) { described_class.new(:main) }

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

    let(:alt_response) do
      [
        { 'application' => 'sidekiq', 'endpoint' => 'WorkerA', 'database' => 'gitlabhq_test',
          'state' => 'active', 'count' => 20 },
        { 'application' => 'sidekiq', 'endpoint' => 'WorkerB', 'database' => 'gitlabhq_test',
          'state' => 'active', 'count' => 20 },
        { 'application' => 'sidekiq', 'endpoint' => 'WorkerB', 'database' => 'gitlabhq_test',
          'state' => 'idle', 'count' => 20 },
        { 'application' => 'sidekiq', 'endpoint' => 'WorkerA', 'database' => 'gitlabhq_test_ci',
          'state' => 'active', 'count' => 20 }
      ]
    end

    let(:hash_key) { "gitlab:pg_stat_sampler:main:sidekiq:samples" }

    it 'writes data into redis and prevents writes within the sampling window' do
      travel_to(Time.now.utc) do
        expect(sampler.write(response)).not_to be_nil
      end

      Gitlab::Redis::SharedState.with do |r|
        hash = r.hgetall(hash_key)
        expect(Gitlab::Json.parse(hash['gitlabhq_test']).pluck('payload'))
            .to match_array([{ 'WorkerA' => { 'active' => 10 }, 'WorkerB' => { 'active' => 10, 'idle' => 10 } }])

        expect(Gitlab::Json.parse(hash['gitlabhq_test_ci']).pluck('payload'))
            .to eq([{ 'WorkerA' => { 'active' => 10 } }])
      end
    end

    context 'when data already exists in the redis hash' do
      before do
        sampler.write(response)
      end

      it 'appends to existing data' do
        expect(sampler.write(alt_response)).not_to be_nil

        Gitlab::Redis::SharedState.with do |r|
          hash = r.hgetall(hash_key)

          expect(Gitlab::Json.parse(hash['gitlabhq_test']).pluck('payload'))
              .to match_array([
                { 'WorkerA' => { 'active' => 10 }, 'WorkerB' => { 'active' => 10, 'idle' => 10 } },
                { 'WorkerA' => { 'active' => 20 }, 'WorkerB' => { 'active' => 20, 'idle' => 20 } }
              ])

          expect(Gitlab::Json.parse(hash['gitlabhq_test_ci']).pluck('payload'))
              .to match_array([{ 'WorkerA' => { 'active' => 10 } }, { 'WorkerA' => { 'active' => 20 } }])
        end
      end

      it 'drops data outside of window' do
        travel_to(Time.now.utc + described_class::SAMPLING_WINDOW_SECONDS + 1) do
          expect(sampler.write(alt_response)).not_to be_nil
        end

        Gitlab::Redis::SharedState.with do |r|
          hash = r.hgetall(hash_key)

          expect(Gitlab::Json.parse(hash['gitlabhq_test']).pluck('payload'))
              .to match_array([{ 'WorkerA' => { 'active' => 20 }, 'WorkerB' => { 'active' => 20, 'idle' => 20 } }])

          expect(Gitlab::Json.parse(hash['gitlabhq_test_ci']).pluck('payload'))
              .to match_array([{ 'WorkerA' => { 'active' => 20 } }])
        end
      end
    end
  end

  describe '#non_idle_connections_by_db' do
    let(:connection_name) { :main }
    let(:hash_key) { "gitlab:pg_stat_sampler:main:sidekiq:samples" }
    let(:samples) do
      [
        {
          'created_at' => Time.now.utc.to_i - 60,
          'payload' => {
            'WorkerA' => { 'active' => 1, 'idle' => 1 },
            'WorkerB' => { 'active' => 5, 'idle in transaction' => 5 }
          }
        },
        {
          'created_at' => Time.now.utc.to_i - 45,
          'payload' => {
            'WorkerA' => { 'active' => 2, 'idle' => 1 },
            'WorkerB' => { 'active' => 5, 'idle in transaction' => 5 }
          }
        },
        {
          'created_at' => Time.now.utc.to_i - 30,
          'payload' => {
            'WorkerA' => { 'active' => 3, 'idle' => 1 },
            'WorkerB' => { 'active' => 5, 'idle in transaction' => 5 }
          }
        },
        {
          'created_at' => Time.now.utc.to_i - 15,
          'payload' => {
            'WorkerA' => { 'active' => 4, 'idle' => 1 },
            'WorkerB' => { 'active' => 5, 'idle in transaction' => 5 },
            'WorkerC' => { 'active' => 1 }
          }
        }
      ]
    end

    subject(:non_idle_connections_by_db) do
      described_class.new(connection_name).non_idle_connections_by_db(min_samples)
    end

    before do
      allow(Gitlab).to receive(:process_name).and_return('sidekiq')
      Gitlab::Redis::SharedState.with do |r|
        r.hset(hash_key, 'gitlabhq_test', ::Gitlab::Json.dump(samples))
      end
    end

    context 'with enough samples' do
      let(:min_samples) { 4 }
      let(:expected) do
        {
          'gitlabhq_test' => {
            'WorkerA' => 10, # ignores idle
            'WorkerB' => 40, # includes `idle in transaction`
            'WorkerC' => 1
          }
        }
      end

      it 'returns aggregated non-idle count' do
        expect(non_idle_connections_by_db).to eq(expected)
      end
    end

    context 'with not enough samples' do
      let(:min_samples) { 5 }
      let(:expected) { { 'gitlabhq_test' => {} } }

      it 'returns empty hash' do
        expect(non_idle_connections_by_db).to eq(expected)
      end
    end

    context 'with empty samples' do
      let(:min_samples) { 1 }
      let(:samples) { [] }
      let(:expected) { { 'gitlabhq_test' => {} } }

      it 'returns empty hash' do
        expect(non_idle_connections_by_db).to eq(expected)
      end
    end
  end
end
