# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::ResendNotificationService, feature_category: :importers do
  let_it_be_with_reload(:import_source_user) { create(:import_source_user, :awaiting_approval) }
  let_it_be(:current_user) { import_source_user.namespace.owner }

  let(:service) { described_class.new(import_source_user, current_user: current_user) }

  describe '#execute' do
    context 'when notification is successfully sent' do
      it 'returns success' do
        expect(Notify).to receive_message_chain(:import_source_user_reassign, :deliver_now)

        result = service.execute

        expect(result).to be_success
        expect(result.payload.awaiting_approval?).to eq(true)
      end
    end

    context 'when current user does not have permission' do
      let(:current_user) { create(:user) }

      it 'returns error no permissions' do
        expect(Notify).not_to receive(:import_source_user_reassign)

        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('You have insufficient permissions to update the import source user')
      end
    end

    context 'when import source user does not have an awaiting_approval status' do
      before do
        import_source_user.accept!
      end

      it 'returns error invalid status' do
        expect(Notify).not_to receive(:import_source_user_reassign)

        result = service.execute
        expect(result).to be_error
        expect(result.message).to eq('Import source user has an invalid status for this operation')
      end
    end
  end
end
