# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IssuesController, feature_category: :team_planning do
  let_it_be(:issue) { create(:issue) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { issue.project }
  let_it_be(:user) { issue.author }

  shared_context 'group project issue' do
    let_it_be(:project) { create :project, group: group }
    let_it_be(:issue) { create :issue, project: project }
    let_it_be(:user) { create(:user) }
  end

  describe 'GET #show' do
    before do
      group.add_developer(user)
      login_as(user)
    end

    describe 'incident tabs' do
      let_it_be(:incident) { create(:incident, project: project) }

      it 'redirects to the issues route for non-incidents' do
        get incident_issue_project_issue_path(project, issue, 'timeline')
        expect(response).to redirect_to project_issue_path(project, issue)
      end

      it 'responds with selected tab for incidents' do
        get incident_issue_project_issue_path(project, incident, 'timeline')
        expect(response.body).to match(/&quot;currentTab&quot;:&quot;timeline&quot;/)
      end
    end
  end

  describe 'GET #discussions' do
    before do
      login_as(user)
    end

    let_it_be(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }
    let_it_be(:discussion_reply) do
      create(:discussion_note_on_issue, noteable: issue, project: issue.project, in_reply_to: discussion)
    end

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
        expect(notes).to match(
          [
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
        expect(notes).to match([a_hash_including('id' => discussion_2.id.to_s)])
      end
    end
  end

  context 'token authentication' do
    context 'when public project' do
      let_it_be(:public_project) { create(:project, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: true do
        let(:url) { project_issues_url(public_project, format: :atom) }
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'calendar ics', public_resource: true do
        let(:url) { project_issues_url(public_project, format: :ics) }
      end
    end

    context 'when private project' do
      let_it_be(:private_project) { create(:project, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom',
        public_resource: false,
        ignore_metrics: true do
        let(:url) { project_issues_url(private_project, format: :atom) }

        before do
          private_project.add_maintainer(user)
        end
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'calendar ics',
        public_resource: false,
        ignore_metrics: true do
        let(:url) { project_issues_url(private_project, format: :ics) }

        before do
          private_project.add_maintainer(user)
        end
      end
    end
  end
end
