# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::NotesController, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }

  describe '#index' do
    def get_notes
      get project_noteable_notes_path(project, target_type: 'issue', target_id: issue.id, format: :json),
        headers: { 'X-Last-Fetched-At': 0 }
    end

    it 'does not execute N+1 queries' do
      get_notes

      create(:note_on_issue, project: project, noteable: issue)

      control = ActiveRecord::QueryRecorder.new { get_notes }

      create(:note_on_issue, project: project, noteable: issue)

      expect { get_notes }.not_to exceed_query_limit(control)
    end
  end

  describe '#update' do
    let_it_be(:user) { create(:user) }
    let_it_be(:note) { create(:note_on_issue, project: project, noteable: issue, author: user) }

    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)
    end

    context 'with rapid_diffs parameter' do
      let(:note_params) { { note: 'Updated note content' } }

      def update_note
        put project_note_path(project, note, format: :json, rapid_diffs: true), params: { note: note_params }
      end

      it 'updates note and includes rapid diffs specific fields' do
        expect { update_note }.to change { note.reload.note }.to('Updated note content')
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['note']).to include(
          'id' => note.id.to_s,
          'discussion_id' => note.discussion_id,
          'is_noteable_author' => false,
          'is_contributor' => false,
          'current_user' => hash_including(
            'can_edit' => true,
            'can_award_emoji' => true
          )
        )
      end
    end
  end
end
