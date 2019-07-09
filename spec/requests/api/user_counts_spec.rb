# frozen_string_literal: true

require 'spec_helper'

describe API::UserCounts do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  let!(:merge_request) { create(:merge_request, :simple, author: user, assignees: [user], source_project: project, title: "Test") }

  describe 'GET /user_counts' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/user_counts')

        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      it 'returns open counts for current user' do
        get api('/user_counts', user)

        expect(response.status).to eq(200)
        expect(json_response).to be_a Hash
        expect(json_response['merge_requests']).to eq(1)
      end

      it 'updates the mr count when a new mr is assigned' do
        create(:merge_request, source_project: project, author: user, assignees: [user])

        get api('/user_counts', user)

        expect(response.status).to eq(200)
        expect(json_response).to be_a Hash
        expect(json_response['merge_requests']).to eq(2)
      end
    end
  end
end
