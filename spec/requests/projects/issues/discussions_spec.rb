# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issue discussions', feature_category: :team_planning do
  describe 'GET /:namespace/:project/-/issues/:iid/discussions' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:note_author) { create(:user) }
    let_it_be(:notes) { create_list(:note, 5, project: project, noteable: issue, author: note_author) }

    before_all do
      project.add_maintainer(user)
    end

    context 'HTTP caching' do
      def get_discussions
        get discussions_namespace_project_issue_path(namespace_id: project.namespace, project_id: project, id: issue.iid), headers: {
          'If-None-Match' => @etag
        }

        @etag = response.etag
      end

      before do
        sign_in(user)

        get_discussions
      end

      it 'returns 304 without serializing JSON' do
        expect(DiscussionSerializer).not_to receive(:new)

        get_discussions

        expect(response).to have_gitlab_http_status(:not_modified)
      end

      shared_examples 'cache miss' do
        it 'returns 200 and serializes JSON' do
          expect(DiscussionSerializer).to receive(:new).and_call_original

          get_discussions

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when user role changes' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'cache miss'
      end

      context 'when emoji is awarded to a note' do
        before do
          travel_to(1.minute.from_now) { create(:award_emoji, awardable: notes.first) }
        end

        it_behaves_like 'cache miss'
      end

      context 'when note author name changes' do
        before do
          note_author.update!(name: 'New name')
        end

        it_behaves_like 'cache miss'
      end

      context 'when note author status changes' do
        before do
          Users::SetStatusService.new(note_author, message: "updated status").execute
        end

        it_behaves_like 'cache miss'
      end

      context 'when note author role changes' do
        before do
          project.add_developer(note_author)
        end

        it_behaves_like 'cache miss'
      end

      context 'when note is added' do
        before do
          create(:note, project: project, noteable: issue)
        end

        it_behaves_like 'cache miss'
      end

      context 'when note is modified' do
        before do
          notes.first.update!(note: 'edited text')
        end

        it_behaves_like 'cache miss'
      end

      context 'when note is deleted' do
        before do
          notes.first.destroy!
        end

        it_behaves_like 'cache miss'
      end
    end
  end
end
