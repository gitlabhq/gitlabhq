# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ImportGithubOauthWebhooks, feature_category: :importers do
  describe 'POST /projects/:id/github/webhooks' do
    it 'returns 404 when the project does not exist' do
      post api("/projects/#{non_existing_record_id}/github/webhooks")

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 for a real project with no GitHub OAuth webhook configured' do
      project = create(:project)

      post api("/projects/#{project.id}/github/webhooks")

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
