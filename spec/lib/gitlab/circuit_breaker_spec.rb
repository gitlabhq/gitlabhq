# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CircuitBreaker, :clean_gitlab_redis_rate_limiting, feature_category: :shared do
  let(:service_name) { 'DummyService' }
  let(:volume_threshold) { 5 }
  let(:circuit) do
    Circuitbox.circuit(service_name,
      { volume_threshold: volume_threshold, exceptions: [Gitlab::CircuitBreaker::InternalServerError] })
  end

  let(:dummy_class) do
    Class.new do
      def dummy_method
        Gitlab::CircuitBreaker.run_with_circuit('DummyService') do
          raise Gitlab::CircuitBreaker::InternalServerError
        end
      end

      def another_dummy_method
        Gitlab::CircuitBreaker.run_with_circuit('DummyService') do
          # Do nothing but successful.
        end
      end
    end
  end

  subject(:instance) { dummy_class.new }

  before do
    stub_const(service_name, dummy_class)
    allow(Circuitbox).to receive(:circuit).and_return(circuit)
  end

  # rubocop: disable RSpec/AnyInstanceOf -- the instance is defined by an initializer
  describe '#circuit' do
    it 'returns nil value' do
      expect(instance.dummy_method).to be_nil
    end

    it 'does not raise an error' do
      expect { instance.dummy_method }.not_to raise_error
    end

    context 'when failed multiple times below volume threshold' do
      it 'does not open the circuit' do
        expect_any_instance_of(Gitlab::CircuitBreaker::Notifier).to receive(:notify)
          .with(anything, 'failure')
          .exactly(4).times

        4.times do
          instance.dummy_method
        end

        expect(circuit).not_to be_open
      end
    end

    context 'when failed multiple times over volume threshold' do
      it 'allows the call 5 times, then opens the circuit and skips subsequent calls' do
        expect_any_instance_of(Gitlab::CircuitBreaker::Notifier).to receive(:notify)
          .with(anything, 'failure')
          .exactly(5).times

        expect_any_instance_of(Gitlab::CircuitBreaker::Notifier).to receive(:notify)
          .with(anything, 'open')
          .once

        expect_any_instance_of(Gitlab::CircuitBreaker::Notifier).to receive(:notify)
          .with(anything, 'skipped')
          .once

        6.times do
          instance.dummy_method
        end

        expect(circuit).to be_open
      end
    end

    context 'when circuit is previously open' do
      before do
        # Opens the circuit
        6.times do
          instance.dummy_method
        end

        # Deletes the open key
        circuit.try_close_next_time
      end

      context 'when does not fail again' do
        it 'closes the circuit' do
          instance.another_dummy_method

          expect(circuit).not_to be_open
        end
      end

      context 'when fails again' do
        it 'opens the circuit' do
          instance.dummy_method

          expect(circuit).to be_open
        end
      end
    end
  end
  # rubocop: enable RSpec/AnyInstanceOf

  describe '#run_with_circuit' do
    let(:block) { proc {} }

    it 'runs the code block within the Circuitbox circuit' do
      expect(circuit).to receive(:run).with(exception: false, &block)
      described_class.run_with_circuit('service', &block)
    end
  end
end
