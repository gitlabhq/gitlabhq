# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Capture::Task, :aggregate_failures, feature_category: :database do
  context 'with capture' do
    let(:database_name) { 'main' }
    let(:chunk_max_statements) { 10 }
    let(:client_identifier) { 'f583dbe0' }

    subject(:capture_task) do
      described_class.new(database_name: database_name).tap do |instance|
        # We need to override chunk_max_statements to 10
        allow(instance).to receive(:chunk_max_statements).and_return(chunk_max_statements)
      end
    end

    before do
      stub_const("#{described_class}::DEFAULT_SLEEP_TIME_SECONDS", 0.001)
      allow(Socket).to receive(:gethostname).and_return('localhost')
      allow(Process).to receive(:pid).and_return(123456)
      allow(ApplicationRecord.connection.load_balancer).to receive(:primary_write_location).and_return('0/0')
      allow(Gitlab::Database::Capture::Storage).to receive(:upload)
      allow(Gitlab::AppLogger).to receive(:info)
    end

    describe '#call' do
      it 'logs the correct events' do
        expect(Gitlab::AppLogger).to receive(:info).with({
          message: 'database capture task started',
          client_identifier: client_identifier,
          database_name: database_name
        }).once

        expect(Gitlab::AppLogger).to receive(:info).with({
          message: 'database capture processing a chunk',
          client_identifier: client_identifier,
          database_name: database_name,
          chunk_id: "v1-#{database_name}-#{client_identifier}-0-0/0",
          statements: 10
        }).once

        expect(Gitlab::AppLogger).to receive(:info).with({
          message: 'database capture processing a chunk',
          client_identifier: client_identifier,
          database_name: database_name,
          chunk_id: "v1-#{database_name}-#{client_identifier}-1-0/0",
          statements: 1
        }).once

        expect(Gitlab::AppLogger).to receive(:info).with({
          message: 'database capture task stopped',
          client_identifier: client_identifier,
          database_name: database_name,
          stop_reason: 'background task stopped'
        }).once

        (chunk_max_statements + 1).times do
          capture_task.push({ 'raw' => 'item' })
        end

        capture_task.stop
        capture_task.call
      end

      context 'when the queue is empty' do
        it 'does not process an empty chunk' do
          expect(Gitlab::AppLogger).to receive(:info).with({
            message: 'database capture task started',
            client_identifier: client_identifier,
            database_name: database_name
          }).once

          expect(Gitlab::AppLogger).to receive(:info).with({
            message: 'database capture task stopped',
            client_identifier: client_identifier,
            database_name: database_name,
            stop_reason: 'background task stopped'
          }).once

          # No chunk processing logs expected
          expect(Gitlab::AppLogger).not_to receive(:info)
            .with(hash_including(message: 'database capture processing a chunk'))

          capture_task.stop
          capture_task.call
        end

        it 'does not read the primary write location' do
          capture_task.stop

          expect(ApplicationRecord.connection.load_balancer).not_to receive(:primary_write_location)

          capture_task.call
        end
      end

      it 'skips nil items returned by a queue pop timeout' do
        capture_task.push({ 'raw' => 'item1' })
        capture_task.stop

        # The first pop simulates a queue timeout returning nil; the loop
        # must skip it rather than buffer it into the chunk
        calls = 0
        allow(capture_task.queue).to receive(:pop).and_wrap_original do |original, **kwargs|
          (calls += 1) == 1 ? nil : original.call(**kwargs)
        end

        expect(Gitlab::AppLogger).to receive(:info).with(hash_including(
          message: 'database capture processing a chunk',
          statements: 1
        )).once

        # The nil was skipped, not serialized into the chunk
        expect(Gitlab::Database::Capture::Storage).to receive(:upload)
          .with(anything, %({"raw":"item1"}))

        capture_task.call
      end

      it 'uploads the chunk statements as NDJSON with a sanitized filename' do
        capture_task.push({ 'raw' => 'SELECT 1', 'connection_id' => 4242 })
        capture_task.push({ 'raw' => 'SELECT 2', 'connection_id' => 4243 })
        capture_task.stop

        expect(Gitlab::Database::Capture::Storage).to receive(:upload).with(
          "v1-#{database_name}-#{client_identifier}-0-0-0.ndjson",
          %({"raw":"SELECT 1","connection_id":4242}\n{"raw":"SELECT 2","connection_id":4243})
        )

        capture_task.call
      end

      it 'reads the primary write location once per chunk' do
        capture_task.push({ 'raw' => 'SELECT 1' })
        capture_task.push({ 'raw' => 'SELECT 2' })
        capture_task.stop

        expect(ApplicationRecord.connection.load_balancer)
          .to receive(:primary_write_location).once.and_return('0/0')

        capture_task.call
      end

      context 'when the upload fails' do
        before do
          allow(Gitlab::Database::Capture::Storage).to receive(:upload).and_raise(StandardError, 'upload boom')
        end

        it 'tracks the exception and keeps processing' do
          capture_task.push({ 'raw' => 'SELECT 1' })
          capture_task.stop

          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            an_instance_of(StandardError),
            chunk_id: "v1-#{database_name}-#{client_identifier}-0-0/0",
            database_name: database_name
          )

          expect(Gitlab::AppLogger).to receive(:info).with(hash_including(
            message: 'database capture processing a chunk',
            statements: 1
          )).once

          expect { capture_task.call }.not_to raise_error
        end
      end

      context 'when a statement cannot be serialized' do
        it 'drops only that statement and uploads the rest of the chunk' do
          capture_task.push({ 'raw' => 'SELECT 1' })
          capture_task.push({ 'raw' => "\xFF\x00".b })
          capture_task.push({ 'raw' => 'SELECT 2' })
          capture_task.stop

          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            kind_of(EncodingError),
            database_name: database_name
          ).once

          expect(Gitlab::Database::Capture::Storage).to receive(:upload)
            .with(anything, %({"raw":"SELECT 1"}\n{"raw":"SELECT 2"}))

          capture_task.call
        end
      end

      context 'when fetching the primary write location fails transiently' do
        before do
          calls = 0
          allow(ApplicationRecord.connection.load_balancer).to receive(:primary_write_location) do
            (calls += 1) == 1 ? raise(ActiveRecord::ConnectionNotEstablished) : '0/0'
          end
        end

        it 'tracks the exception and ships the buffered statements on retry' do
          capture_task.push({ 'raw' => 'SELECT 1' })
          capture_task.stop

          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            an_instance_of(ActiveRecord::ConnectionNotEstablished),
            database_name: database_name
          ).once
          expect(capture_task).to receive(:sleep).with(described_class::DEFAULT_SLEEP_TIME_SECONDS)

          # The buffered statement survives the failed attempt and is
          # uploaded when the LSN read succeeds in the final flush
          expect(Gitlab::Database::Capture::Storage).to receive(:upload)
            .with(anything, %({"raw":"SELECT 1"}))

          expect { capture_task.call }.not_to raise_error
        end
      end

      context 'when fetching the primary write location fails persistently' do
        before do
          allow(ApplicationRecord.connection.load_balancer)
            .to receive(:primary_write_location).and_raise(ActiveRecord::ConnectionNotEstablished)
        end

        it 'tracks the exception in the loop and raises from the final flush' do
          capture_task.push({ 'raw' => 'SELECT 1' })
          capture_task.stop

          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            an_instance_of(ActiveRecord::ConnectionNotEstablished),
            database_name: database_name
          ).once

          # The final flush deliberately propagates: BackgroundTask#stop
          # rescues and tracks the error rethrown by Thread#join
          expect { capture_task.call }.to raise_error(ActiveRecord::ConnectionNotEstablished)

          expect(Gitlab::Database::Capture::Storage).not_to have_received(:upload)
        end
      end
    end

    describe '#push' do
      it 'adds to the queue' do
        expect { capture_task.push({ 'raw' => 'item' }) }.to change { capture_task.queue.length }.by(1)
      end

      context 'when the sized queue is full' do
        before do
          5_000.times { capture_task.push({ 'raw' => 'item' }) }
        end

        it 'logs a queue full message' do
          expect(Gitlab::AppLogger).to receive(:warn).with({
            message: 'database capture task encountered queue full',
            client_identifier: client_identifier,
            database_name: database_name
          }).once

          capture_task.push({ 'raw' => 'item' })
        end

        it 'does not log multiple times when queue remains full' do
          expect(Gitlab::AppLogger).to receive(:warn).with({
            message: 'database capture task encountered queue full',
            client_identifier: client_identifier,
            database_name: database_name
          }).once

          # First push triggers the warning
          capture_task.push({ 'raw' => 'item' })
          # Second push should not trigger another warning
          capture_task.push({ 'raw' => 'item' })
        end
      end

      context 'when the queue is closed' do
        before do
          capture_task.queue.close
        end

        it 'ignores the event' do
          expect { capture_task.push({ 'raw' => 'item' }) }.not_to raise_error
        end
      end
    end

    describe '#chunk_max_statements' do
      before do
        allow(capture_task).to receive(:chunk_max_statements).and_call_original
      end

      it 'returns the default value' do
        expect(capture_task.chunk_max_statements).to eq 10_000
      end
    end

    describe '#stop' do
      it 'closes the queue and records the stop reason' do
        expect(capture_task.queue).not_to be_closed

        capture_task.stop

        expect(capture_task.queue).to be_closed
        expect(capture_task.instance_variable_get(:@stop_reason)).to eq 'background task stopped'
      end

      it 'does not change state when already stopped' do
        capture_task.stop
        initial_stop_reason = capture_task.instance_variable_get(:@stop_reason)

        # Try to stop again with a different reason
        capture_task.send(:stop_working, reason: 'another reason')

        # Stop reason should not change
        expect(capture_task.instance_variable_get(:@stop_reason)).to eq initial_stop_reason
      end
    end

    describe 'flush_chunk' do
      it 'does nothing when no statements are buffered' do
        expect(Gitlab::AppLogger).not_to receive(:info)
          .with(hash_including(message: 'database capture processing a chunk'))
        expect(ApplicationRecord.connection.load_balancer).not_to receive(:primary_write_location)

        capture_task.send(:flush_chunk)
      end
    end
  end
end
