# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SavedViews::UpdateService, feature_category: :code_review_workflow do
  let_it_be(:owner) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let(:saved_view) { create(:merge_request_saved_view, :with_filters, user: owner, name: 'Original') }
  let(:current_user) { owner }
  let(:params) { { name: 'Renamed', filters: { 'state' => 'closed' } } }

  subject(:execute) { described_class.new(saved_view, current_user: current_user, params: params).execute }

  context 'when the update is valid' do
    it 'updates the allowed attributes and returns the saved view in the payload' do
      expect(execute).to be_success
      expect(execute.payload[:saved_view]).to eq(saved_view)

      saved_view.reload
      expect(saved_view.name).to eq('Renamed')
      expect(saved_view.filters).to eq({ 'state' => 'closed' })
    end

    context 'when filters use symbol keys' do
      let(:params) { { filters: { state: 'closed' } } }

      it 'normalizes filters to string keys' do
        expect(execute.payload[:saved_view].filters).to eq({ 'state' => 'closed' })
      end
    end

    context 'when params are empty' do
      let(:params) { {} }

      it 'succeeds as a no-op' do
        expect(execute).to be_success
        expect(saved_view.reload.name).to eq('Original')
      end
    end

    context 'when unknown params are supplied' do
      let(:params) { { name: 'Renamed', user_id: other_user.id } }

      it 'ignores them' do
        expect(execute).to be_success
        expect(saved_view.reload.user).to eq(owner)
      end
    end

    context 'when the owner is already at the per-user limit' do
      before do
        saved_view
        create_list(:merge_request_saved_view, MergeRequests::SavedView.views_limit - 1, user: owner)
      end

      it 'still succeeds, since the limit validation only runs on create' do
        expect(execute).to be_success
      end
    end
  end

  context 'when the current user is not authorized' do
    let(:current_user) { other_user }

    it 'returns a forbidden error and does not update the record' do
      expect(execute).to be_error
      expect(execute.reason).to eq(:forbidden)
      expect(execute.message).to eq('You do not have permission to update this saved view.')
      expect(saved_view.reload.name).to eq('Original')
    end
  end

  context 'when validation fails' do
    let(:params) { { name: '' } }

    it 'returns an unprocessable_entity error' do
      expect(execute).to be_error
      expect(execute.reason).to eq(:unprocessable_entity)
      expect(execute.message).to include("Name can't be blank")
    end
  end
end
