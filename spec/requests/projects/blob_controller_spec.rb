# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects blob controller', feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  before do
    sign_in(user)
  end

  describe 'POST preview' do
    let(:content) { 'Some content' }

    def do_post(content)
      post namespace_project_preview_blob_path(
        namespace_id: project.namespace,
        project_id: project,
        id: 'master/CHANGELOG'
      ), params: { content: content }
    end

    context 'when content is within size limit' do
      it 'returns success and renders the preview' do
        do_post(content)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Type']).to include('text/html')
      end
    end

    context 'when content exceeds size limit' do
      before do
        stub_const('Projects::BlobController::MAX_PREVIEW_CONTENT', 1.byte)
      end

      it 'returns payload too large error' do
        do_post(content)

        expect(response).to have_gitlab_http_status(:payload_too_large)
        expect(json_response['errors']).to include('Preview content too large')
      end
    end
  end
end
