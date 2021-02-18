# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project noteable notes' do
  describe '#index' do
    let_it_be(:merge_request) { create(:merge_request) }

    let(:etag_store) { Gitlab::EtagCaching::Store.new }
    let(:notes_path) { project_noteable_notes_path(project, target_type: merge_request.class.name.underscore, target_id: merge_request.id) }
    let(:project) { merge_request.project }
    let(:user) { project.owner }

    let(:response_etag) { response.headers['ETag'] }
    let(:stored_etag) { "W/\"#{etag_store.get(notes_path)}\"" }

    before do
      login_as(user)
    end

    it 'does not set a Gitlab::EtagCaching ETag if there is a note' do
      create(:note_on_merge_request, noteable: merge_request, project: merge_request.project)

      get notes_path

      expect(response).to have_gitlab_http_status(:ok)

      # Rack::ETag will set an etag based on the body digest, but that doesn't
      # interfere with notes pagination
      expect(response_etag).not_to eq(stored_etag)
    end

    it 'sets a Gitlab::EtagCaching ETag if there is no note' do
      get notes_path

      expect(response).to have_gitlab_http_status(:ok)
      expect(response_etag).to eq(stored_etag)
    end
  end
end
