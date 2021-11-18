# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IssuesController do
  let_it_be(:issue) { create(:issue) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { issue.project }
  let_it_be(:user) { issue.author }

  before do
    login_as(user)
  end

  describe 'GET #discussions' do
    let_it_be(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }
    let_it_be(:discussion_reply) { create(:discussion_note_on_issue, noteable: issue, project: issue.project, in_reply_to: discussion) }
    let_it_be(:state_event) { create(:resource_state_event, issue: issue) }
    let_it_be(:discussion_2) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }
    let_it_be(:discussion_3) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }

    context 'pagination' do
      def get_discussions(**params)
        get discussions_project_issue_path(project, issue, params: params.merge(format: :json))
      end

      it 'returns paginated notes and cursor based on per_page param' do
        get_discussions(per_page: 2)

        discussions = Gitlab::Json.parse(response.body)
        notes = discussions.flat_map { |d| d['notes'] }

        expect(discussions.count).to eq(2)
        expect(notes).to match([
          a_hash_including('id' => discussion.id.to_s),
          a_hash_including('id' => discussion_reply.id.to_s),
          a_hash_including('type' => 'StateNote')
        ])

        cursor = response.header['X-Next-Page-Cursor']
        expect(cursor).to be_present

        get_discussions(per_page: 1, cursor: cursor)

        discussions = Gitlab::Json.parse(response.body)
        notes = discussions.flat_map { |d| d['notes'] }

        expect(discussions.count).to eq(1)
        expect(notes).to match([
          a_hash_including('id' => discussion_2.id.to_s)
        ])
      end

      context 'when paginated_issue_discussions is disabled' do
        before do
          stub_feature_flags(paginated_issue_discussions: false)
        end

        it 'returns all discussions and ignores per_page param' do
          get_discussions(per_page: 2)

          discussions = Gitlab::Json.parse(response.body)
          notes = discussions.flat_map { |d| d['notes'] }

          expect(discussions.count).to eq(4)
          expect(notes.count).to eq(5)
        end
      end
    end
  end
end
