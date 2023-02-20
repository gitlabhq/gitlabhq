# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'Subscriptions::Notes::Updated', feature_category: :team_planning do
  include GraphqlHelpers
  include Graphql::Subscriptions::Notes::Helper

  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:task) { create(:work_item, :task, project: project) }
  let_it_be(:note, refind: true) { create(:note, noteable: task, project: task.project, type: 'DiscussionNote') }

  let(:current_user) { nil }
  let(:subscribe) { note_subscription('workItemNoteUpdated', task, current_user) }
  let(:updated_note) { graphql_dig_at(graphql_data(response[:result]), :workItemNoteUpdated) }

  before do
    stub_const('GitlabSchema', Graphql::Subscriptions::ActionCable::MockGitlabSchema)
    Graphql::Subscriptions::ActionCable::MockActionCable.clear_mocks
    project.add_guest(guest)
    project.add_reporter(reporter)
  end

  subject(:response) do
    subscription_response do
      note.update!(note: 'changing the note body')
    end
  end

  context 'when user is unauthorized' do
    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  context 'when user is authorized' do
    let(:current_user) { reporter }

    it 'receives updated note data' do
      expect(updated_note['id']).to eq(note.to_gid.to_s)
      expect(updated_note['body']).to eq('changing the note body')
    end

    context 'when note is confidential' do
      let_it_be(:note, refind: true) do
        create(:note, :confidential, noteable: task, project: task.project, type: 'DiscussionNote')
      end

      context 'and user has permission to read confidential notes' do
        it 'receives updated note data' do
          expect(updated_note['id']).to eq(note.to_gid.to_s)
          expect(updated_note['body']).to eq('changing the note body')
        end
      end

      context 'and user does not have permission to read confidential notes' do
        let(:current_user) { guest }

        it 'does not receive updated note data' do
          expect(updated_note).to be_nil
        end
      end
    end
  end
end
