require 'spec_helper'

describe Gitlab::Geo::LogCursor::Daemon, lib: true do
  describe '#run!' do
    before do
      allow(subject).to receive(:exit?) { true }
    end

    it 'traps signals' do
      allow(subject).to receive(:exit?) { true }
      expect(subject).to receive(:trap_signals)

      subject.run!
    end

    context 'when the command-line defines full_scan: true' do
      subject { described_class.new(full_scan: true) }

      it 'executes a full-scan' do
        expect(subject).to receive(:full_scan!)

        subject.run!
      end
    end
  end
end
