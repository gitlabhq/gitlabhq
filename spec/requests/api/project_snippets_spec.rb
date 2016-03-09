require 'rails_helper'

describe API::API, api: true do
  include ApiHelpers

  describe 'GET /projects/:project_id/snippets/:id' do
    # TODO (rspeicher): Deprecated; remove in 9.0
    it 'always exposes expires_at as nil' do
      admin = create(:admin)
      snippet = create(:project_snippet, author: admin)

      get api("/projects/#{snippet.project.id}/snippets/#{snippet.id}", admin)

      expect(json_response).to have_key('expires_at')
      expect(json_response['expires_at']).to be_nil
    end
  end
end
