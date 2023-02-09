# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project noteable notes', feature_category: :team_planning do
  describe '#index' do
    let_it_be(:merge_request) { create(:merge_request) }

    let(:etag_store) { Gitlab::EtagCaching::Store.new }
    let(:notes_path) { project_noteable_notes_path(project, target_type: merge_request.class.name.underscore, target_id: merge_request.id) }
    let(:project) { merge_request.project }
    let(:user) { project.first_owner }

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

    it "instruments cache hits correctly" do
      etag_store.touch(notes_path)

      expect(Gitlab::Metrics::RailsSlis.request_apdex).to(
        receive(:increment).with(
          labels: {
            request_urgency: :medium,
            feature_category: "team_planning",
            endpoint_id: "Projects::NotesController#index"
          },
          success: be_in([true, false])
        )
      )
      allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original

      expect(ActiveSupport::Notifications).to(
        receive(:instrument).with(
          'process_action.action_controller',
          a_hash_including(
            {
              request_urgency: :medium,
              target_duration_s: 0.5,
              metadata: a_hash_including({
                'meta.feature_category' => 'team_planning',
                'meta.caller_id' => "Projects::NotesController#index"
              })
            }
          )
        )
      )

      get notes_path, headers: { "if-none-match": stored_etag }

      expect(response).to have_gitlab_http_status(:not_modified)
    end
  end
end
