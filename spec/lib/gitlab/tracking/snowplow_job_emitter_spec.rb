# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::SnowplowJobEmitter, feature_category: :product_analytics do
  let(:endpoint) { 'localhost' }
  let(:options) { { buffer_size: 1, on_success: -> {}, on_failure: -> {} } }

  subject(:emitter) { described_class.new(endpoint: endpoint, options: options) }

  describe '#initialize' do
    context 'with callbacks in the options param' do
      it 'removes on_success callback from options' do
        expect(emitter.options['on_success']).to be_nil
      end

      it 'removes on_failure callback from options' do
        expect(emitter.options['on_failure']).to be_nil
      end
    end
  end

  describe '#flush' do
    before do
      allow(Analytics::SnowplowEmitterWorker).to receive(:perform_async)
    end

    context 'when buffer is empty' do
      it 'does not call SnowplowEmitterWorker' do
        emitter.instance_variable_set(:@buffer, [])

        emitter.flush

        expect(Analytics::SnowplowEmitterWorker).not_to have_received(:perform_async)
      end
    end

    context 'with events in buffer' do
      let(:events) { [{ 'event' => 'test_event1' }, { 'event' => 'test_event2' }] }

      before do
        emitter.instance_variable_set(:@buffer, events)
      end

      context 'when not inside a database transaction' do
        before do
          allow(ApplicationRecord).to receive(:inside_transaction?).and_return(false)
        end

        it 'sends all events to the worker immediately' do
          emitter.flush

          expect(Analytics::SnowplowEmitterWorker).to have_received(:perform_async).twice
        end
      end

      context 'when inside a database transaction' do
        before do
          allow(ApplicationRecord).to receive(:inside_transaction?).and_return(true)
        end

        it 'does not call perform_async synchronously inside the transaction' do
          fake_transaction = instance_double(ActiveRecord::ConnectionAdapters::Transaction)
          allow(ApplicationRecord.connection).to receive(:current_transaction).and_return(fake_transaction)
          allow(fake_transaction).to receive(:after_commit)

          emitter.flush

          expect(Analytics::SnowplowEmitterWorker).not_to have_received(:perform_async)
        end

        it 'defers worker enqueue via after_commit callback' do
          fake_transaction = instance_double(ActiveRecord::ConnectionAdapters::Transaction)
          allow(ApplicationRecord.connection).to receive(:current_transaction).and_return(fake_transaction)

          after_commit_blocks = []
          allow(fake_transaction).to receive(:after_commit) { |&block| after_commit_blocks << block }

          emitter.flush

          expect(after_commit_blocks.size).to eq(2)

          after_commit_blocks.each(&:call)

          expect(Analytics::SnowplowEmitterWorker).to have_received(:perform_async).twice
        end
      end
    end
  end
end
