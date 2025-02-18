# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.synthetic_note(noteable_id, sha)', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:label_event, refind: true) do
    create(:resource_label_event, user: current_user, issue: issue, label: label, action: 'add', created_at: 2.days.ago)
  end

  let(:label_note) { LabelNote.from_events([label_event]) }
  let(:global_id) { ::Gitlab::GlobalId.build(label_note, model_name: LabelNote.to_s, id: label_note.discussion_id) }
  let(:note_params) { { sha: label_note.discussion_id, noteable_id: global_id_of(issue) } }
  let(:note_data) { graphql_data['syntheticNote'] }
  let(:note_fields) { all_graphql_fields_for('Note'.classify) }

  let(:query) do
    graphql_query_for('synthetic_note', note_params, note_fields)
  end

  context 'when the user does not have access to read the note' do
    it 'returns nil' do
      post_graphql(query, current_user: current_user)

      expect(note_data).to be_nil
    end
  end

  context 'when the user has access to read the note' do
    before do
      project.add_guest(current_user)
    end

    it 'returns synthetic note' do
      post_graphql(query, current_user: current_user)

      expect(note_data['id']).to eq(global_id.to_s)
    end

    context 'and notes widget is not available' do
      before do
        WorkItems::Type.default_by_type(:issue).widget_definitions
          .find_by_widget_type(:notes).update!(disabled: true)
      end

      it 'returns nil' do
        post_graphql(query, current_user: current_user)

        expect(note_data).to be_nil
      end
    end
  end
end
