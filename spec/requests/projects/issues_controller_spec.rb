# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IssuesController, feature_category: :team_planning do
  let_it_be(:issue) { create(:issue) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { issue.project }
  let_it_be(:user) { issue.author }

  describe 'GET #new' do
    before do
      login_as(user)
    end

    it_behaves_like "observability csp policy", described_class do
      let(:tested_path) do
        new_project_issue_path(project)
      end
    end
  end

  describe 'GET #show' do
    before do
      login_as(user)
    end

    it_behaves_like "observability csp policy", described_class do
      let(:tested_path) do
        project_issue_path(project, issue)
      end
    end
  end

  describe 'GET #index.json' do
    let_it_be(:public_project) { create(:project, :public) }

    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
      let_it_be(:current_user) { create(:user) }

      before do
        sign_in current_user
      end

      def request
        get project_issues_path(public_project, format: :json), params: { scope: 'all', search: 'test' }
      end
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit_unauthenticated do
      def request
        get project_issues_path(public_project, format: :json), params: { scope: 'all', search: 'test' }
      end
    end
  end

  describe 'GET #discussions' do
    before do
      login_as(user)
    end

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

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: false, ignore_metrics: true do
        let(:url) { project_issues_url(private_project, format: :atom) }

        before do
          private_project.add_maintainer(user)
        end
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'calendar ics', public_resource: false, ignore_metrics: true do
        let(:url) { project_issues_url(private_project, format: :ics) }

        before do
          private_project.add_maintainer(user)
        end
      end
    end
  end
end
