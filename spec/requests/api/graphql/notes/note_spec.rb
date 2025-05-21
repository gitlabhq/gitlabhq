# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.note(id)', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:reporter_user) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: reporter_user) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:note) { create(:note, noteable: issue, project: project) }
  let_it_be(:system_note) { create(:note, :system, noteable: issue, project: project) }

  let(:note_params) { { 'id' => global_id_of(note) } }
  let(:note_data) { graphql_data['note'] }
  let(:note_fields) { all_graphql_fields_for('Note'.classify) }

  let(:query) do
    graphql_query_for('note', note_params, note_fields)
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  context 'when the user does not have access to read the note' do
    it 'returns nil' do
      post_graphql(query, current_user: current_user)

      expect(note_data).to be_nil
    end

    context 'when it is a system note' do
      let(:note_params) { { 'id' => global_id_of(system_note) } }

      it 'returns nil' do
        post_graphql(query, current_user: current_user)

        expect(note_data).to be_nil
      end
    end
  end

  context 'when the user has access to read the note' do
    before_all do
      project.add_guest(current_user)
    end

    it 'returns note' do
      post_graphql(query, current_user: current_user)

      expect(note_data['id']).to eq(global_id_of(note).to_s)
    end

    context 'when it is a system note' do
      let(:note_params) { { 'id' => global_id_of(system_note) } }

      it 'returns note' do
        post_graphql(query, current_user: current_user)

        expect(note_data['id']).to eq(global_id_of(system_note).to_s)
      end

      context 'with issue_email_participants action' do
        let_it_be(:email) { 'user@example.com' }
        let_it_be(:note_text) { "added #{email}" }
        let_it_be(:issue_email_participants_system_note) do
          create(:note, :system,
            project: project, noteable: issue, author: Users::Internal.support_bot, note: note_text)
        end

        let_it_be(:system_note_metadata) do
          create(:system_note_metadata, note: issue_email_participants_system_note, action: :issue_email_participants)
        end

        let(:obfuscated_email) { 'us*****@e*****.c**' }
        let(:note_params) { { 'id' => global_id_of(issue_email_participants_system_note) } }

        it 'returns obfuscated email' do
          post_graphql(query, current_user: current_user)

          expect(note_data['id']).to eq(global_id_of(issue_email_participants_system_note).to_s)
          expect(note_data['body']).to include(obfuscated_email)
          expect(note_data['bodyHtml']).to include(obfuscated_email)
        end

        context 'when user has at least the reporter role in project' do
          it 'returns email' do
            post_graphql(query, current_user: reporter_user)

            expect(note_data['id']).to eq(global_id_of(issue_email_participants_system_note).to_s)
            expect(note_data['body']).to include(email)
            expect(note_data['bodyHtml']).to include(email)
          end
        end
      end
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

    context 'when note is internal' do
      let_it_be(:note) { create(:note, :confidential, noteable: issue, project: project) }

      it 'returns nil' do
        post_graphql(query, current_user: current_user)

        expect(note_data).to be_nil
      end

      context 'and user can read confidential notes' do
        let_it_be(:developer) { create(:user) }

        before do
          project.add_developer(developer)
        end

        it 'returns note' do
          post_graphql(query, current_user: developer)

          expect(note_data['id']).to eq(global_id_of(note).to_s)
        end
      end
    end
  end
end
