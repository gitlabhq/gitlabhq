# frozen_string_literal: true

# This can use fast_spec_helper when the feature flag stubbing is removed.
require 'spec_helper'

RSpec.describe Gitlab::SidekiqStatus::ClientMiddleware, :clean_gitlab_redis_queues do
  describe '#call' do
    context 'when opt_in_sidekiq_status is disabled' do
      before do
        stub_feature_flags(opt_in_sidekiq_status: false)
      end

      context 'when the job has status_expiration set' do
        it 'tracks the job in Redis' do
          expect(Gitlab::SidekiqStatus).to receive(:set).with('123', 1.hour.to_i).and_call_original

          described_class.new
            .call('Foo', { 'jid' => '123', 'status_expiration' => 1.hour.to_i }, double(:queue), double(:pool)) { nil }

          expect(Gitlab::SidekiqStatus.num_running(['123'])).to eq(1)
        end
      end

      context 'when the job does not have status_expiration set' do
        it 'tracks the job in Redis' do
          expect(Gitlab::SidekiqStatus).to receive(:set).with('123', 30.minutes.to_i).and_call_original

          described_class.new
            .call('Foo', { 'jid' => '123' }, double(:queue), double(:pool)) { nil }

          expect(Gitlab::SidekiqStatus.num_running(['123'])).to eq(1)
        end
      end
    end

    context 'when opt_in_sidekiq_status is enabled' do
      before do
        stub_feature_flags(opt_in_sidekiq_status: true)
      end

      context 'when the job has status_expiration set' do
        it 'tracks the job in Redis' do
          expect(Gitlab::SidekiqStatus).to receive(:set).with('123', 1.hour.to_i).and_call_original

          described_class.new
            .call('Foo', { 'jid' => '123', 'status_expiration' => 1.hour.to_i }, double(:queue), double(:pool)) { nil }

          expect(Gitlab::SidekiqStatus.num_running(['123'])).to eq(1)
        end
      end

      context 'when the job does not have status_expiration set' do
        it 'does not track the job in Redis' do
          described_class.new
            .call('Foo', { 'jid' => '123' }, double(:queue), double(:pool)) { nil }

          expect(Gitlab::SidekiqStatus.num_running(['123'])).to be_zero
        end
      end
    end
  end
end
