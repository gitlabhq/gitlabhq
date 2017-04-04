require 'spec_helper'

describe Gitlab::SidekiqStatus::ClientMiddleware do
  describe '#call' do
    it 'tracks the job in Redis' do
      expect(Gitlab::SidekiqStatus).to receive(:set).with('123')

      described_class.new.
        call('Foo', { 'jid' => '123' }, double(:queue), double(:pool)) { nil }
    end
  end
end
