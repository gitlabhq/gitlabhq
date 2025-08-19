# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::Throttling::Decider, feature_category: :scalability do
  let(:worker_name) { 'TestWorker' }

  subject(:decider) { described_class.new(worker_name) }

  describe '#execute' do
    let(:resource_usage_limiter) { instance_double(Gitlab::ResourceUsageLimiter) }

    before do
      allow(Gitlab::ResourceUsageLimiter).to receive(:new).with(worker_name: worker_name)
                                                          .and_return(resource_usage_limiter)
    end

    context 'when DB duration has not exceeded quota' do
      before do
        allow(resource_usage_limiter).to receive(:exceeded_limits?).and_return(false)
      end

      it 'returns a decision to not throttle' do
        decision = decider.execute

        expect(decision.needs_throttle).to be false
        expect(decision.strategy).to eq(Gitlab::SidekiqMiddleware::Throttling::Strategy::None)
      end
    end

    context 'when DB duration has exceeded quota' do
      before do
        allow(resource_usage_limiter).to receive(:exceeded_limits?).and_return(true)
      end

      context 'when worker is dominant in pg_stat_activity' do
        before do
          allow(Gitlab::Database::LoadBalancing).to receive(:base_models).and_return([ApplicationRecord])
          allow_next_instance_of(Gitlab::Database::StatActivity) do |stat_activity|
            allow(stat_activity).to receive(:non_idle_connections_by_db).and_return(
              {
                'main' => {
                  'TestWorker' => 5,
                  'OtherWorker' => 2
                }
              }
            )
          end
        end

        it 'returns a decision to hard throttle' do
          decision = decider.execute

          expect(decision.needs_throttle).to be true
          expect(decision.strategy).to eq(Gitlab::SidekiqMiddleware::Throttling::Strategy::HardThrottle)
        end
      end

      context 'when worker is not dominant in pg_stat_activity' do
        before do
          allow(Gitlab::Database::LoadBalancing).to receive(:base_models).and_return([ApplicationRecord])
          allow_next_instance_of(Gitlab::Database::StatActivity) do |stat_activity|
            allow(stat_activity).to receive(:non_idle_connections_by_db).and_return(
              {
                'main' => {
                  'TestWorker' => 2,
                  'OtherWorker' => 5
                }
              }
            )
          end
        end

        it 'returns a decision to soft throttle' do
          decision = decider.execute

          expect(decision.needs_throttle).to be true
          expect(decision.strategy).to eq(Gitlab::SidekiqMiddleware::Throttling::Strategy::SoftThrottle)
        end
      end

      context 'when there are no non-idle connections' do
        before do
          allow(Gitlab::Database::LoadBalancing).to receive(:base_models).and_return([ApplicationRecord])
          allow_next_instance_of(Gitlab::Database::StatActivity) do |stat_activity|
            allow(stat_activity).to receive(:non_idle_connections_by_db).and_return({})
          end
        end

        it 'returns a decision to soft throttle' do
          decision = decider.execute

          expect(decision.needs_throttle).to be true
          expect(decision.strategy).to eq(Gitlab::SidekiqMiddleware::Throttling::Strategy::SoftThrottle)
        end
      end
    end
  end
end
