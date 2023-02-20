# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'Subscriptions::Notes::Deleted', feature_category: :team_planning do
  include GraphqlHelpers
  include Graphql::Subscriptions::Notes::Helper

  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:task) { create(:work_item, :task, project: project) }
  let_it_be(:note, refind: true) { create(:note, noteable: task, project: project, type: 'DiscussionNote') }
  let_it_be(:reply_note, refind: true) do
    create(:note, noteable: task, project: project, in_reply_to: note, discussion_id: note.discussion_id)
  end

  let(:current_user) { nil }
  let(:subscribe) { notes_subscription('workItemNoteDeleted', task, current_user) }
  let(:deleted_note) { graphql_dig_at(graphql_data(response[:result]), :workItemNoteDeleted) }

  before do
    stub_const('GitlabSchema', Graphql::Subscriptions::ActionCable::MockGitlabSchema)
    Graphql::Subscriptions::ActionCable::MockActionCable.clear_mocks
    project.add_guest(guest)
    project.add_reporter(reporter)
  end

  subject(:response) do
    subscription_response do
      note.destroy!
    end
  end

  context 'when user is unauthorized' do
    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  context 'when user is authorized' do
    let(:current_user) { guest }

    it 'receives note id that is removed' do
      expect(deleted_note['id']).to eq(note.to_gid.to_s)
      expect(deleted_note['discussionId']).to eq(note.discussion.to_gid.to_s)
      expect(deleted_note['lastDiscussionNote']).to be false
    end

    context 'when last discussion note is deleted' do
      let_it_be(:note, refind: true) { create(:note, noteable: task, project: project, type: 'DiscussionNote') }

      it 'receives note id that is removed' do
        expect(deleted_note['id']).to eq(note.to_gid.to_s)
        expect(deleted_note['discussionId']).to eq(note.discussion.to_gid.to_s)
        expect(deleted_note['lastDiscussionNote']).to be true
      end
    end

    context 'when note is confidential' do
      let_it_be(:note, refind: true) do
        create(:note, :confidential, noteable: task, project: project, type: 'DiscussionNote')
      end

      it 'receives note id that is removed' do
        expect(deleted_note['id']).to eq(note.to_gid.to_s)
        expect(deleted_note['discussionId']).to eq(note.discussion.to_gid.to_s)
        expect(deleted_note['lastDiscussionNote']).to be true
      end
    end
  end
end
