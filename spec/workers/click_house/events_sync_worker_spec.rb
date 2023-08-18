# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::EventsSyncWorker, feature_category: :value_stream_management do
  let(:databases) { { main: :some_db } }
  let(:worker) { described_class.new }

  before do
    allow(ClickHouse::Client.configuration).to receive(:databases).and_return(databases)
  end

  include_examples 'an idempotent worker' do
    context 'when the event_sync_worker_for_click_house feature flag is on' do
      before do
        stub_feature_flags(event_sync_worker_for_click_house: true)
      end

      it 'returns true' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { status: :processed })

        worker.perform
      end

      context 'when no ClickHouse databases are configured' do
        let(:databases) { {} }

        it 'skips execution' do
          expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { status: :disabled })

          worker.perform
        end
      end

      context 'when exclusive lease error happens' do
        it 'skips execution' do
          expect(worker).to receive(:in_lock).and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { status: :skipped })

          worker.perform
        end
      end
    end

    context 'when the event_sync_worker_for_click_house feature flag is off' do
      before do
        stub_feature_flags(event_sync_worker_for_click_house: false)
      end

      it 'skips execution' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { status: :disabled })

        worker.perform
      end
    end
  end
end
