require 'spec_helper'

describe Gitlab::Unicorn::Hook do
  let(:canary) { double(:canary) }
  let(:server) { double(:server) }
  let(:worker) { double(:worker) }

  before do
    described_class.before_fork = nil
    described_class.after_fork = nil
  end

  describe '#run_before_fork' do
    context 'before_fork hook configured' do
      before do
        allow(canary).to receive(:trigger)

        described_class.before_fork do |server, worker|
          canary.trigger(server, worker)
        end
      end

      it 'runs before fork' do
        described_class.run_before_fork(server, worker)

        expect(canary).to have_received(:trigger).with(server, worker)
      end
    end

    context 'before_fork hook not configured' do
      before do
        allow(canary).to receive(:trigger)
      end

      it 'runs before fork' do
        described_class.run_before_fork(server, worker)

        expect(canary).not_to have_received(:trigger).with(server, worker)
      end
    end
  end

  describe '#run_after_fork' do
    context 'after_fork hook configured' do
      before do
        allow(canary).to receive(:trigger)

        described_class.after_fork do |server, worker|
          canary.trigger(server, worker)
        end
      end

      it 'runs before fork' do
        described_class.run_after_fork(server, worker)

        expect(canary).to have_received(:trigger).with(server, worker)
      end
    end

    context 'after_fork hook not configured' do
      before do
        allow(canary).to receive(:trigger)
      end

      it 'runs before fork' do
        described_class.run_after_fork(server, worker)

        expect(canary).not_to have_received(:trigger).with(server, worker)
      end
    end
  end
end
