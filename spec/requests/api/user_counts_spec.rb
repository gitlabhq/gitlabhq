# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UserCounts, feature_category: :service_ping do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project, author: user, assignees: [user]) }
  let_it_be(:todo) { create(:todo, :pending, user: user, project: project) }

  let!(:merge_request) { create(:merge_request, :simple, author: user, assignees: [user], source_project: project, title: "Test") }

  describe 'GET /user_counts' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/user_counts')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns assigned issue counts for current_user' do
        get api('/user_counts', user)

        expect(json_response['assigned_issues']).to eq(1)
      end

      it 'returns assigned MR counts for current user' do
        get api('/user_counts', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a Hash
        expect(json_response['merge_requests']).to eq(1)
      end

      it 'updates the mr count when a new mr is assigned' do
        create(:merge_request, source_project: project, author: user, assignees: [user])

        get api('/user_counts', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a Hash
        expect(json_response['merge_requests']).to eq(2)
      end

      it 'returns pending todo counts for current_user' do
        get api('/user_counts', user)

        expect(json_response['todos']).to eq(1)
      end
    end
  end
end
