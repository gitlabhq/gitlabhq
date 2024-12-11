# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ReassignPlaceholderUserRecordsWorker, feature_category: :importers do
  let(:import_source_user) do
    create(:import_source_user, :with_reassign_to_user, :reassignment_in_progress)
  end

  let(:job_args) { import_source_user.id }

  describe '#perform' do
    before do
      allow(Import::ReassignPlaceholderUserRecordsService).to receive(:new).and_call_original
    end

    it_behaves_like 'an idempotent worker' do
      it 'enqueues service to map records to real users' do
        expect(Import::ReassignPlaceholderUserRecordsService).to receive(:new).once

        perform_multiple(job_args)
      end

      shared_examples 'an invalid source user' do
        it 'does not enqueue service to map records to real users' do
          expect(Import::ReassignPlaceholderUserRecordsService).not_to receive(:new)

          perform_multiple(job_args)
        end

        it 'logs a warning that the reassignment process was not started' do
          expect(::Import::Framework::Logger).to receive(:warn).with({
            message: 'Unable to begin reassignment because Import source user has an invalid status or does not exist',
            source_user_id: import_source_user&.id
          }).twice

          perform_multiple(job_args)
        end
      end

      context 'when import source user is not reassignment_in_progress status' do
        let(:import_source_user) { create(:import_source_user, :awaiting_approval) }

        it_behaves_like 'an invalid source user'
      end

      context 'when import source user does not exist' do
        let(:import_source_user) { nil }
        let(:job_args) { [-1] }

        it_behaves_like 'an invalid source user'
      end

      it 'queues a DeletePlaceholderUserWorker with the source user ID' do
        expect(Import::DeletePlaceholderUserWorker)
          .to receive(:perform_async).with(import_source_user.id)

        perform_multiple(job_args)
      end
    end
  end

  context 'when database is unhealthy' do
    let(:service_response) { ServiceResponse.new(status: :success, reason: :db_health_check_failed) }
    let(:backoff_period) { described_class::BACKOFF_PERIOD }

    before do
      allow_next_instance_of(Import::ReassignPlaceholderUserRecordsService) do |service|
        allow(service).to receive(:execute).and_return(service_response)
      end
    end

    it 're-enqueues the job' do
      expect(described_class).to receive(:perform_in).with(backoff_period, import_source_user.id, {})

      described_class.new.perform(import_source_user.id)
    end
  end

  describe '#sidekiq_retries_exhausted' do
    it 'logs the failure and sets the source user status to failed', :aggregate_failures do
      exception = StandardError.new('Some error')

      expect(::Import::Framework::Logger).to receive(:error).with({
        message: 'Failed to reassign placeholder user',
        error: exception.message,
        source_user_id: import_source_user.id
      })

      described_class.sidekiq_retries_exhausted_block.call({ 'args' => job_args }, exception)

      expect(import_source_user.reload).to be_failed
    end
  end
end
