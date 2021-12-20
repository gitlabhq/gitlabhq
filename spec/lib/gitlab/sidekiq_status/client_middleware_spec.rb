# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::SidekiqStatus::ClientMiddleware do
  describe '#call' do
    context 'when the job has status_expiration set' do
      it 'tracks the job in Redis with a value of 2' do
        expect(Gitlab::SidekiqStatus).to receive(:set).with('123', 1.hour.to_i, value: 2)

        described_class.new
          .call('Foo', { 'jid' => '123', 'status_expiration' => 1.hour.to_i }, double(:queue), double(:pool)) { nil }
      end
    end

    context 'when the job does not have status_expiration set' do
      it 'tracks the job in Redis with a value of 1' do
        expect(Gitlab::SidekiqStatus).to receive(:set).with('123', Gitlab::SidekiqStatus::DEFAULT_EXPIRATION, value: 1)

        described_class.new
          .call('Foo', { 'jid' => '123' }, double(:queue), double(:pool)) { nil }
      end
    end
  end
end
