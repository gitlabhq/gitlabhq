require 'spec_helper'

describe Gitlab::JobWaiter do
  describe '#wait' do
    let(:waiter) { described_class.new(%w(a)) }
    it 'returns when all jobs have been completed' do
      expect(Gitlab::SidekiqStatus).to receive(:all_completed?).with(%w(a)).
        and_return(true)

      expect(waiter).not_to receive(:sleep)

      waiter.wait
    end

    it 'sleeps between checking the job statuses' do
      expect(Gitlab::SidekiqStatus).to receive(:all_completed?).
        with(%w(a)).
        and_return(false, true)

      expect(waiter).to receive(:sleep).with(described_class::INTERVAL)

      waiter.wait
    end

    it 'returns when timing out' do
      expect(waiter).not_to receive(:sleep)
      waiter.wait(0)
    end
  end
end
