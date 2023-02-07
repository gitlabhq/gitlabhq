# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'Subscriptions::Notes::Created', feature_category: :team_planning do
  include GraphqlHelpers
  include Graphql::Subscriptions::Notes::Helper

  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:task) { create(:work_item, :task, project: project) }

  let(:current_user) { nil }
  let(:subscribe) { notes_subscription('workItemNoteCreated', task, current_user) }
  let(:response_note) { graphql_dig_at(graphql_data(response[:result]), :workItemNoteCreated) }
  let(:discussion) { graphql_dig_at(response_note, :discussion) }
  let(:discussion_notes) { graphql_dig_at(discussion, :notes, :nodes) }

  before do
    stub_const('GitlabSchema', Graphql::Subscriptions::ActionCable::MockGitlabSchema)
    Graphql::Subscriptions::ActionCable::MockActionCable.clear_mocks
    project.add_guest(guest)
    project.add_reporter(reporter)
  end

  subject(:response) do
    subscription_response do
      # this creates note defined with let lazily and triggers the subscription event
      new_note
    end
  end

  context 'when user is unauthorized' do
    let(:new_note) { create(:note, noteable: task, project: project, type: 'DiscussionNote') }

    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  context 'when user is authorized' do
    let(:current_user) { guest }
    let(:new_note) { create(:note, noteable: task, project: project, type: 'DiscussionNote') }

    it 'receives created note' do
      response
      note = Note.find(new_note.id)

      expect(response_note['id']).to eq(note.to_gid.to_s)
      expect(discussion['id']).to eq(note.discussion.to_gid.to_s)
      expect(discussion_notes.pluck('id')).to eq([note.to_gid.to_s])
    end

    context 'when a new note is created as a reply' do
      let_it_be(:note, refind: true) { create(:note, noteable: task, project: project, type: 'DiscussionNote') }

      let(:new_note) do
        create(:note, noteable: task, project: project, in_reply_to: note, discussion_id: note.discussion_id)
      end

      it 'receives created note' do
        response
        reply = Note.find(new_note.id)

        expect(response_note['id']).to eq(reply.to_gid.to_s)
        expect(discussion['id']).to eq(reply.discussion.to_gid.to_s)
        expect(discussion_notes.pluck('id')).to eq([note.to_gid.to_s, reply.to_gid.to_s])
      end
    end

    context 'when note is confidential' do
      let(:current_user) { reporter }
      let(:new_note) { create(:note, :confidential, noteable: task, project: project, type: 'DiscussionNote') }

      context 'and user has permission to read confidential notes' do
        it 'receives created note' do
          response
          confidential_note = Note.find(new_note.id)

          expect(response_note['id']).to eq(confidential_note.to_gid.to_s)
          expect(discussion['id']).to eq(confidential_note.discussion.to_gid.to_s)
          expect(discussion_notes.pluck('id')).to eq([confidential_note.to_gid.to_s])
        end

        context 'and replying' do
          let_it_be(:note, refind: true) do
            create(:note, :confidential, noteable: task, project: project, type: 'DiscussionNote')
          end

          let(:new_note) do
            create(:note, :confidential,
              noteable: task, project: project, in_reply_to: note, discussion_id: note.discussion_id)
          end

          it 'receives created note' do
            response
            reply = Note.find(new_note.id)

            expect(response_note['id']).to eq(reply.to_gid.to_s)
            expect(discussion['id']).to eq(reply.discussion.to_gid.to_s)
            expect(discussion_notes.pluck('id')).to eq([note.to_gid.to_s, reply.to_gid.to_s])
          end
        end
      end

      context 'and user does not have permission to read confidential notes' do
        let(:current_user) { guest }
        let(:new_note) { create(:note, :confidential, noteable: task, project: project, type: 'DiscussionNote') }

        it 'does not receive note data' do
          response
          expect(response_note).to be_nil
        end
      end
    end
  end
end
