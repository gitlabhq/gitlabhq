# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::RetryFailedReassignmentService, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be_with_reload(:import_source_user) { create(:import_source_user, :failed) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:retry_attempts_key) { format(described_class::RETRY_ATTEMPTS_KEY, source_user_id: import_source_user.id) }

  subject(:service) { described_class.new(import_source_user, current_user: current_user) }

  describe '#execute' do
    before do
      import_source_user.namespace.add_owner(user)
      allow(Import::ReassignPlaceholderUserRecordsWorker).to receive(:perform_async)
    end

    it 'returns success' do
      expect(service.execute).to be_success
    end

    it 'updates the status to reassignment_in_progress' do
      service.execute

      expect(import_source_user.reload).to be_reassignment_in_progress
    end

    it 'resets the previous reassignment error' do
      expect { service.execute }.to change { import_source_user.reassignment_error }
        .from(an_instance_of(String)).to(nil)
    end

    it 'enqueues the job to reassign contributions' do
      expect(Import::ReassignPlaceholderUserRecordsWorker).to receive(:perform_async).with(import_source_user.id)

      service.execute
    end

    it 'tracks the retry reassignment event' do
      expect { service.execute }
        .to trigger_internal_events('retry_failed_placeholder_user_reassignment')
        .with(
          namespace: import_source_user.namespace,
          user: current_user,
          additional_properties: {
            label: Gitlab::GlobalAnonymousId.user_id(import_source_user.placeholder_user),
            property: Gitlab::GlobalAnonymousId.user_id(import_source_user.reassign_to_user),
            import_type: import_source_user.import_type,
            reassign_to_user_state: import_source_user.reassign_to_user.state
          }
        )
    end

    it 'limits retry attempts on consistently failing source users', :aggregate_failures do
      allow(Import::ReassignPlaceholderUserRecordsWorker).to receive(:perform_async).with(import_source_user.id)
        .and_invoke(->(_) { import_source_user.fail_reassignment })

      new_service = -> { described_class.new(import_source_user, current_user: current_user) }

      described_class::MAX_RETRY_ATTEMPTS.times do |i|
        travel_to((i + 1).minutes.from_now) { new_service.call.execute }
      end

      expect(Import::ReassignPlaceholderUserRecordsWorker).to have_received(:perform_async)
        .with(import_source_user.id)
        .exactly(described_class::MAX_RETRY_ATTEMPTS).times

      result = new_service.call.execute

      expect(result).to be_error
      expect(result.reason).to eq(:too_many_requests)
    end

    shared_examples 'an error response', :aggregate_failures do |error_message:, reason:|
      it 'returns an error response' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq(error_message)
        expect(result.reason).to eq(reason)
      end

      it 'does not enqueue the job to reassign contributions' do
        expect(Import::ReassignPlaceholderUserRecordsWorker).not_to receive(:perform_async).with(import_source_user.id)

        service.execute
      end

      it 'does not update the source user status and reassignment error' do
        expect { service.execute }
          .to not_change { import_source_user.status }
          .and not_change { import_source_user.reassignment_error }
      end

      it 'does not track retry reassignment event' do
        expect { service.execute }
          .not_to trigger_internal_events('retry_failed_placeholder_user_reassignment')
      end

      it 'does not record a retry attempt for the source user' do
        expect(Gitlab::Cache::Import::Caching).not_to receive(:set_add)

        service.execute
      end
    end

    context 'when import source user is not failed' do
      where(:status) do
        Import::SourceUser::STATUSES.keys.excluding(:failed)
      end

      with_them do
        before do
          import_source_user.update_column(:status, Import::SourceUser::STATUSES[status])
        end

        it_behaves_like 'an error response',
          error_message: 'Import source user has an invalid status for this operation',
          reason: :invalid_status
      end
    end

    context 'when retry attempts have been exceeded' do
      before do
        described_class::MAX_RETRY_ATTEMPTS.times do |i|
          Gitlab::Cache::Import::Caching.set_add(
            retry_attempts_key,
            (10.hours.ago + i.hours).to_i,
            timeout: described_class::RETRY_COOLDOWN
          )
        end
      end

      it_behaves_like 'an error response',
        error_message: "Reassignment retry has failed multiple times. " \
          "Repeated failures suggest an unexpected error that may need time to resolve. " \
          "Please try again in about 6 hours.",
        reason: :too_many_requests

      it 'reports wait time based on when the earliest retry falls outside the cooldown window' do
        result = service.execute

        expect(result.message).to match(/try again in about 6 hours/)
      end

      context 'and the source user is no longer failed after the last attempt' do
        it 'returns an invalid status error because retry limit is not relevant unless source user is failed' do
          import_source_user.update!(status: Import::SourceUser::STATUSES[:completed])

          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('Import source user has an invalid status for this operation')
          expect(result.reason).to eq(:invalid_status)
        end
      end
    end

    context 'when retry attempts exist but the earliest has aged out of the cooldown window' do
      before do
        Gitlab::Cache::Import::Caching.set_add(
          retry_attempts_key,
          17.hours.ago.to_i,
          timeout: described_class::RETRY_COOLDOWN
        )

        (described_class::MAX_RETRY_ATTEMPTS - 1).times do |i|
          Gitlab::Cache::Import::Caching.set_add(
            retry_attempts_key,
            (10.hours.ago + i.hours).to_i,
            timeout: described_class::RETRY_COOLDOWN
          )
        end
      end

      it 'allows the retry because only attempts within the cooldown window are counted' do
        expect(Import::ReassignPlaceholderUserRecordsWorker).to receive(:perform_async).with(import_source_user.id)

        result = service.execute

        expect(result).to be_success
      end
    end

    context 'when current user does not have permission' do
      let(:current_user) { create(:user) }

      it_behaves_like 'an error response',
        error_message: 'You have insufficient permissions to update the import source user',
        reason: :forbidden
    end

    context 'when an error occurs' do
      before do
        allow(import_source_user).to receive_messages(
          retry_reassignment: false,
          errors: instance_double(ActiveModel::Errors, full_messages: ['Error'])
        )
      end

      it_behaves_like 'an error response', error_message: ['Error'], reason: nil
    end
  end
end
