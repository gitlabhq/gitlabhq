# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SavedViews::CreateService, feature_category: :code_review_workflow do
  let_it_be(:current_user) { create(:user) }

  let(:filters) { { 'state' => 'opened', 'assignee_usernames' => ['root'] } }
  let(:params) { { name: 'My view', filters: filters } }

  subject(:execute) { described_class.new(current_user: current_user, params: params).execute }

  context 'when the params are valid' do
    it 'creates a saved view owned by the current user' do
      expect { execute }.to change { MergeRequests::SavedView.count }.by(1)

      saved_view = execute.payload[:saved_view]

      expect(execute).to be_success
      expect(saved_view).to be_persisted
      expect(saved_view.user).to eq(current_user)
      expect(saved_view.name).to eq('My view')
      expect(saved_view.filters).to eq(filters)
    end

    it 'locks the user, so that concurrent creates cannot exceed the views limit', :lock_recorder do
      expect { execute }.to lock_rows(current_user => 'FOR UPDATE')
    end

    context 'when filters use symbol keys' do
      let(:filters) { { state: 'opened' } }

      it 'normalizes filters to string keys' do
        expect(execute.payload[:saved_view].filters).to eq({ 'state' => 'opened' })
      end
    end

    context 'when filters is absent' do
      let(:params) { { name: 'My view' } }

      it 'defaults filters to an empty hash' do
        expect(execute.payload[:saved_view].filters).to eq({})
      end
    end

    context 'when unknown params are supplied' do
      let(:params) { { name: 'My view', filters: filters, user_id: create(:user).id, id: non_existing_record_id } }

      it 'ignores them' do
        saved_view = execute.payload[:saved_view]

        expect(saved_view.user).to eq(current_user)
        expect(saved_view.id).not_to eq(non_existing_record_id)
      end
    end
  end

  context 'when the current user is not authorized' do
    let(:current_user) { nil }

    it 'returns a forbidden error and creates no record' do
      expect { execute }.not_to change { MergeRequests::SavedView.count }

      expect(execute).to be_error
      expect(execute.reason).to eq(:forbidden)
      expect(execute.message).to eq('You do not have permission to create saved views.')
    end
  end

  context 'when validation fails' do
    let(:params) { { name: '', filters: filters } }

    it 'returns an unprocessable_entity error and creates no record' do
      expect { execute }.not_to change { MergeRequests::SavedView.count }

      expect(execute).to be_error
      expect(execute.reason).to eq(:unprocessable_entity)
      expect(execute.message).to include("Name can't be blank")
    end
  end
end
