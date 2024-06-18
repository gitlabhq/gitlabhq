# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::SidekiqSignals do
  describe '.install' do
    let(:result) { Hash.new { |h, k| h[k] = 0 } }
    let(:int_handler) { ->(_) { result['INT'] += 1 } }
    let(:term_handler) { ->(_) { result['TERM'] += 1 } }
    let(:other_handler) { ->(_) { result['OTHER'] += 1 } }
    let(:signals) { { 'INT' => int_handler, 'TERM' => term_handler, 'OTHER' => other_handler } }

    context 'not a process group leader' do
      before do
        allow(Process).to receive(:getpgrp) { Process.pid * 2 }
      end

      it 'does nothing' do
        expect { described_class.install!(signals) }
          .not_to change { signals }
      end
    end

    context 'as a process group leader' do
      before do
        allow(Process).to receive(:getpgrp) { Process.pid }
      end

      it 'installs its own signal handlers for TERM and INT only' do
        described_class.install!(signals)

        expect(signals['INT']).not_to eq(int_handler)
        expect(signals['TERM']).not_to eq(term_handler)
        expect(signals['OTHER']).to eq(other_handler)
      end

      %w[INT TERM].each do |signal|
        it "installs a forwarding signal handler for #{signal}" do
          described_class.install!(signals)

          expect(described_class)
            .to receive(:trap)
            .with(signal, 'IGNORE')
            .and_return(:original_trap)
            .ordered

          expect(Process)
            .to receive(:kill)
            .with(signal, 0)
            .ordered

          expect(described_class)
            .to receive(:trap)
            .with(signal, :original_trap)
            .ordered

          signals[signal].call(:cli)

          expect(result[signal]).to eq(1)
        end

        it "raises if sidekiq no longer traps SIG#{signal}" do
          signals.delete(signal)

          expect { described_class.install!(signals) }
            .to raise_error(/Sidekiq should have registered/)
        end
      end
    end
  end
end
