# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::DataRetention::AuthenticationEventArchiveWorker, feature_category: :system_access do
  describe '#perform', :freeze_time do
    subject(:worker) { described_class.new }

    let(:cutoff_time) { Time.current.beginning_of_day - AuthenticationEvent::RETENTION_PERIOD }

    let!(:before_cutoff_record) do
      create(:authentication_event, created_at: cutoff_time - 1.hour)
    end

    let!(:on_cutoff_record) do
      create(:authentication_event, created_at: cutoff_time)
    end

    let!(:after_cutoff_record) do
      create(:authentication_event, created_at: cutoff_time + 1.hour)
    end

    # The `authentication_event_archived_records` table is only used by the archive jobs. We want to discourage its
    # use throughout the app as it is meant to be a temporary table and will be removed from the codebase soon. Rather
    # than define a full ActiveRecord model with factory and spec, let's just mock a model class for test purposes.
    let(:authentication_event_archived_record_model) do
      Class.new(ApplicationRecord) do
        self.table_name = 'authentication_event_archived_records'

        enum :result, {
          failed: 0,
          success: 1
        }
      end
    end

    it_behaves_like 'an idempotent worker'

    it 'deletes records from the operational authentication_events table' do
      expect { worker.perform }.to change { AuthenticationEvent.count }.by(-2)

      expect(AuthenticationEvent.pluck(:id)).to contain_exactly(after_cutoff_record.id)
    end

    it 'archives records from the operational table to the archived records table' do
      expect { worker.perform }.to change { authentication_event_archived_record_model.count }.by(2)

      expect(authentication_event_archived_record_model.pluck(:id))
        .to contain_exactly(before_cutoff_record.id, on_cutoff_record.id)
    end

    it 'sets attributes correctly in archive table' do
      original_attributes = before_cutoff_record.serializable_hash

      worker.perform

      archived_attributes = authentication_event_archived_record_model.find(before_cutoff_record.id).serializable_hash

      expect(archived_attributes.except("archived_at")).to match(original_attributes.except("organization_id"))
      expect(archived_attributes["archived_at"]).to be_present
    end

    it 'logs the per-batch archived count' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        class: described_class.name,
        message: "Archived 2 authentication events",
        cutoff_time: cutoff_time
      )

      worker.perform
    end

    it 'logs the total archived count' do
      expect(worker)
        .to receive(:log_extra_metadata_on_done)
              .with(:result, hash_including(
                over_time: false,
                total_archived: 2,
                cutoff_time: cutoff_time
              ))

      worker.perform
    end

    context 'with a large batch of archivable records' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)
        stub_const("#{described_class}::SUB_BATCH_SIZE", 1)

        create_list(:authentication_event, 2, created_at: cutoff_time - 1.hour)
      end

      it 'processes events in batches' do
        expect(ApplicationRecord.connection)
          .to receive(:execute)
                .with(a_string_matching(/WITH batch AS MATERIALIZED/))
                .at_least(4)
                .and_call_original

        expect { worker.perform }.to change { AuthenticationEvent.where(created_at: ..cutoff_time).count }.from(4).to(0)
      end
    end

    context 'when the runtime limit is reached' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)
        stub_const("#{described_class}::SUB_BATCH_SIZE", 1)

        allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
          allow(runtime_limiter).to receive_messages(over_time?: true, was_over_time?: true)
        end

        create(:authentication_event, created_at: cutoff_time - 1.hour)
      end

      it 'reschedules the worker' do
        expect(described_class).to receive(:perform_in).with(3.minutes, an_instance_of(Integer))

        worker.perform
      end

      it 'stops processing when limit reached' do
        worker.perform

        remaining = AuthenticationEvent.where(created_at: ..cutoff_time).count
        expect(remaining).to be 1
      end

      it 'logs the fact that the runtime limit was reached' do
        expect(worker)
          .to receive(:log_extra_metadata_on_done)
                .with(:result, hash_including(
                  over_time: true,
                  total_archived: 2
                ))

        worker.perform
      end
    end
  end
end
