# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::HealthChecks::Probes::Collection do
  let(:readiness) { described_class.new(*checks) }

  describe '#execute' do
    subject { readiness.execute }

    context 'with all checks' do
      let(:checks) do
        [
          Gitlab::HealthChecks::DbCheck,
          Gitlab::HealthChecks::Redis::RedisCheck,
          Gitlab::HealthChecks::Redis::CacheCheck,
          Gitlab::HealthChecks::Redis::QueuesCheck,
          Gitlab::HealthChecks::Redis::SharedStateCheck,
          Gitlab::HealthChecks::GitalyCheck
        ]
      end

      it 'responds with readiness checks data' do
        expect(subject.http_status).to eq(200)

        expect(subject.json[:status]).to eq('ok')
        expect(subject.json['db_check']).to contain_exactly(status: 'ok')
        expect(subject.json['cache_check']).to contain_exactly(status: 'ok')
        expect(subject.json['queues_check']).to contain_exactly(status: 'ok')
        expect(subject.json['shared_state_check']).to contain_exactly(status: 'ok')
        expect(subject.json['gitaly_check']).to contain_exactly(
          status: 'ok', labels: { shard: 'default' })
      end

      context 'when Redis fails' do
        before do
          allow(Gitlab::HealthChecks::Redis::RedisCheck).to receive(:readiness).and_return(
            Gitlab::HealthChecks::Result.new('redis_check', false, "check error"))
        end

        it 'responds with failure' do
          expect(subject.http_status).to eq(503)

          expect(subject.json[:status]).to eq('failed')
          expect(subject.json['cache_check']).to contain_exactly(status: 'ok')
          expect(subject.json['redis_check']).to contain_exactly(
            status: 'failed', message: 'check error')
        end
      end
    end

    context 'without checks' do
      let(:checks) { [] }

      it 'responds with success' do
        expect(subject.http_status).to eq(200)

        expect(subject.json).to eq(status: 'ok')
      end
    end
  end
end
