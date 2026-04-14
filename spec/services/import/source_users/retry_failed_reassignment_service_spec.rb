# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::RetryFailedReassignmentService, feature_category: :importers do
  let_it_be_with_reload(:import_source_user) { create(:import_source_user, :failed) }
  let(:user) { create(:user) }
  let(:current_user) { user }

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

    shared_examples 'an error response', :aggregate_failures do |error_message:, reason:|
      it 'returns error invalid status' do
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

      it 'returns an error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq(['Error'])
      end
    end
  end
end
