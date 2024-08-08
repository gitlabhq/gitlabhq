# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::AcceptReassignmentService, feature_category: :importers do
  let(:import_source_user) { create(:import_source_user, :awaiting_approval, :with_reassign_to_user) }
  let(:current_user) { import_source_user.reassign_to_user }
  let(:service) { described_class.new(import_source_user, current_user: current_user) }

  describe '#execute' do
    it 'returns success' do
      expect(service.execute).to be_success
    end

    it 'sets the source user to accepted' do
      service.execute

      expect(import_source_user.reload).to be_reassignment_in_progress
    end

    it 'enqueues the job to reassign contributions' do
      expect(Import::ReassignPlaceholderUserRecordsWorker).to receive(:perform_async).with(import_source_user.id)

      service.execute
    end

    shared_examples 'current user does not have permission to accept reassignment' do
      it 'returns error no permissions' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('You have insufficient permissions to update the import source user')
      end

      it 'does not enqueue the job to reassign contributions' do
        expect(Import::ReassignPlaceholderUserRecordsWorker).not_to receive(:perform_async)

        service.execute
      end
    end

    context 'when the current user is not the user to reassign contributions to' do
      let(:current_user) { create(:user) }

      it_behaves_like 'current user does not have permission to accept reassignment'
    end

    context 'when there is no user to reassign to' do
      before do
        import_source_user.update!(reassign_to_user: nil)
      end

      it_behaves_like 'current user does not have permission to accept reassignment'

      context 'and no current user is provided' do
        let(:current_user) { nil }

        it_behaves_like 'current user does not have permission to accept reassignment'
      end
    end
  end
end
