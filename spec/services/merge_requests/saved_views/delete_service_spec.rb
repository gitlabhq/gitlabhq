# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SavedViews::DeleteService, feature_category: :code_review_workflow do
  let_it_be(:owner) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let!(:saved_view) { create(:merge_request_saved_view, :with_filters, user: owner) }
  let(:current_user) { owner }

  subject(:execute) { described_class.new(saved_view, current_user: current_user).execute }

  context 'when the current user is authorized' do
    it 'destroys the saved view and returns it in the payload' do
      expect { execute }.to change { MergeRequests::SavedView.count }.by(-1)

      expect(execute).to be_success
      expect(execute.payload[:saved_view]).to be_destroyed
    end
  end

  context 'when the current user is not authorized' do
    let(:current_user) { other_user }

    it 'returns a forbidden error and does not delete the record' do
      expect { execute }.not_to change { MergeRequests::SavedView.count }

      expect(execute).to be_error
      expect(execute.reason).to eq(:forbidden)
      expect(execute.message).to eq('You do not have permission to delete this saved view.')
    end
  end

  context 'when destroy fails' do
    before do
      allow(saved_view).to receive_messages(
        destroy: false,
        errors: instance_double(ActiveModel::Errors, full_messages: ['Boom'])
      )
    end

    it 'returns an unprocessable_entity error' do
      expect(execute).to be_error
      expect(execute.reason).to eq(:unprocessable_entity)
      expect(execute.message).to eq(['Boom'])
    end
  end
end
