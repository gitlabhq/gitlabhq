# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HealthChecks::Probes::Collection do
  let(:readiness) { described_class.new(*checks) }

  describe '#execute' do
    subject { readiness.execute }

    context 'with all checks' do
      let(:checks) do
        [
          Gitlab::HealthChecks::DbCheck,
          *Gitlab::HealthChecks::Redis::ALL_INSTANCE_CHECKS,
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
          allow(Gitlab::HealthChecks::Redis::SharedStateCheck).to receive(:readiness).and_return(
            Gitlab::HealthChecks::Result.new('shared_state_check', false, "check error"))
        end

        it 'responds with failure' do
          expect(subject.http_status).to eq(503)

          expect(subject.json[:status]).to eq('failed')
          expect(subject.json['cache_check']).to contain_exactly(status: 'ok')
          expect(subject.json['shared_state_check']).to contain_exactly(
            status: 'failed', message: 'check error')
        end
      end

      context 'when check raises exception not handled inside the check' do
        before do
          expect(Gitlab::HealthChecks::Redis::CacheCheck).to receive(:readiness).and_raise(
            ::Redis::CannotConnectError, 'Redis down')
        end

        it 'responds with failure including the exception info' do
          expect(subject.http_status).to eq(500)

          expect(subject.json[:status]).to eq('failed')
          expect(subject.json[:message]).to eq('Redis::CannotConnectError : Redis down')
        end
      end

      context 'when some checks are not available' do
        before do
          allow(Gitlab::Runtime).to receive(:puma_in_clustered_mode?).and_return(false)
        end

        let(:checks) do
          [
            Gitlab::HealthChecks::MasterCheck
          ]
        end

        it 'asks for check availability' do
          expect(Gitlab::HealthChecks::MasterCheck).to receive(:available?)

          subject
        end

        it 'does not call `readiness` on checks that are not available' do
          expect(Gitlab::HealthChecks::MasterCheck).not_to receive(:readiness)

          subject
        end

        it 'does not fail collection check' do
          expect(subject.http_status).to eq(200)
          expect(subject.json[:status]).to eq('ok')
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
