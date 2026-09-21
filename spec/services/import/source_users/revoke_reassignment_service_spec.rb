# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::RevokeReassignmentService, feature_category: :importers do
  let(:import_source_user) { create(:import_source_user, :completed) }
  let(:current_user) { import_source_user.reassign_to_user }
  let(:service) { described_class.new(import_source_user, current_user: current_user) }

  let(:result) { service.execute }

  describe '#execute' do
    it 'returns success' do
      expect { result }
        .to trigger_internal_events('revoke_placeholder_user_reassignment')
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
      expect(result).to be_success
    end

    it 'sets the source user to revoked' do
      service.execute
      expect(import_source_user.reload).to be_revoked
    end

    shared_examples 'current user does not have permission to revoke reassignment' do
      it 'returns error no permissions' do
        expect(result).to be_error
        expect(result.message).to eq('You have insufficient permissions to update the import source user')
      end
    end

    context 'when current user is not the assigned user' do
      let(:current_user) { create(:user) }

      it_behaves_like 'current user does not have permission to revoke reassignment'
    end

    context 'when current user is nil' do
      let(:current_user) { nil }

      it_behaves_like 'current user does not have permission to revoke reassignment'
    end

    context 'when import source user does not have a revocable status' do
      let(:import_source_user) { create(:import_source_user, :reassignment_in_progress) }

      it 'returns error invalid status' do
        expect(result).to be_error
        expect(result.message).to eq("Import source user has an invalid status for this operation")
      end
    end

    context 'when an error occurs' do
      before do
        allow(import_source_user).to receive_messages(revoke: false, errors: instance_double(ActiveModel::Errors,
          full_messages: ['Error']))
      end

      it 'returns an error' do
        expect(result).to be_error
        expect(result.message).to eq(['Error'])
      end
    end
  end
end
