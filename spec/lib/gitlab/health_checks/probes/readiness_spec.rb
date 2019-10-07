# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::HealthChecks::Probes::Readiness do
  let(:readiness) { described_class.new }

  describe '#call' do
    subject { readiness.execute }

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
end
