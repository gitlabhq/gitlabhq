# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::UndoKeepAsPlaceholderService, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let(:import_source_user) { create(:import_source_user, :keep_as_placeholder) }

  let(:current_user) { user }
  let(:service) { described_class.new(import_source_user, current_user: current_user) }
  let(:result) { service.execute }

  before do
    import_source_user.namespace.add_owner(user)
  end

  describe '#execute' do
    context 'when operation is successful' do
      it 'returns success' do
        expect { result }
          .to trigger_internal_events('undo_keep_as_placeholder')
          .with(
            namespace: import_source_user.namespace,
            user: current_user,
            additional_properties: {
              label: Gitlab::GlobalAnonymousId.user_id(import_source_user.placeholder_user),
              property: Gitlab::GlobalAnonymousId.user_id(import_source_user.placeholder_user),
              import_type: import_source_user.import_type,
              reassign_to_user_state: import_source_user.placeholder_user.state
            }
          )

        expect(result).to be_success
        expect(result.payload.reload).to eq(import_source_user)
        expect(result.payload.reassigned_by_user).to be_nil
        expect(result.payload.reassign_to_user).to be_nil
        expect(result.payload.pending_reassignment?).to be(true)
      end
    end

    context 'when current user does not have permission' do
      let(:current_user) { create(:user) }

      it 'returns error no permissions' do
        expect(result).to be_error
        expect(result.message).to eq('You have insufficient permissions to update the import source user')
      end
    end

    context 'when import source user does not have keep_as_placeholder status' do
      before do
        allow(import_source_user).to receive(:keep_as_placeholder?).and_return(false)
      end

      it 'returns error invalid status' do
        expect(result).to be_error
        expect(result.message).to eq('Import source user has an invalid status for this operation')
      end
    end

    context 'when an error occurs' do
      before do
        allow(import_source_user).to receive_messages(
          undo_keep_as_placeholder: false,
          errors: instance_double(ActiveModel::Errors, full_messages: ['Error'])
        )
      end

      it 'returns an error' do
        expect(result).to be_error
        expect(result.message).to eq(['Error'])
      end
    end
  end
end
