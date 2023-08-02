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
end
