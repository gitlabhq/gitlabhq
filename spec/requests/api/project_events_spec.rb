require 'spec_helper'

describe API::ProjectEvents do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:non_member) { create(:user) }
  let(:private_project) { create(:project, :private, creator_id: user.id, namespace: user.namespace) }
  let(:closed_issue) { create(:closed_issue, project: private_project, author: user) }
  let!(:closed_issue_event) { create(:event, project: private_project, author: user, target: closed_issue, action: Event::CLOSED, created_at: Date.new(2016, 12, 30)) }

  describe 'GET /projects/:id/events' do
    context 'when unauthenticated ' do
      it 'returns 404 for private project' do
        get api("/projects/#{private_project.id}/events")

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns 200 status for a public project' do
        public_project = create(:project, :public)

        get api("/projects/#{public_project.id}/events")

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'with inaccessible events' do
      let(:public_project) { create(:project, :public, creator_id: user.id, namespace: user.namespace) }
      let(:confidential_issue) { create(:closed_issue, confidential: true, project: public_project, author: user) }
      let!(:confidential_event) { create(:event, project: public_project, author: user, target: confidential_issue, action: Event::CLOSED) }
      let(:public_issue) { create(:closed_issue, project: public_project, author: user) }
      let!(:public_event) { create(:event, project: public_project, author: user, target: public_issue, action: Event::CLOSED) }

      it 'returns only accessible events' do
        get api("/projects/#{public_project.id}/events", non_member)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.size).to eq(1)
      end

      it 'returns all events when the user has access' do
        get api("/projects/#{public_project.id}/events", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.size).to eq(2)
      end
    end

    context 'pagination' do
      let(:public_project) { create(:project, :public) }

      before do
        create(:event,
               project: public_project,
               target: create(:issue, project: public_project, title: 'Issue 1'),
               action: Event::CLOSED,
               created_at: Date.parse('2018-12-10'))
        create(:event,
               project: public_project,
               target: create(:issue, confidential: true, project: public_project, title: 'Confidential event'),
               action: Event::CLOSED,
               created_at: Date.parse('2018-12-11'))
        create(:event,
               project: public_project,
               target: create(:issue, project: public_project, title: 'Issue 2'),
               action: Event::CLOSED,
               created_at: Date.parse('2018-12-12'))
      end

      it 'correctly returns the second page without inaccessible events' do
        get api("/projects/#{public_project.id}/events", user), params: { per_page: 2, page: 2 }

        titles = json_response.map { |event| event['target_title'] }

        expect(titles.first).to eq('Issue 1')
        expect(titles).not_to include('Confidential event')
      end

      it 'correctly returns the first page without inaccessible events' do
        get api("/projects/#{public_project.id}/events", user), params: { per_page: 2, page: 1 }

        titles = json_response.map { |event| event['target_title'] }

        expect(titles.first).to eq('Issue 2')
        expect(titles).not_to include('Confidential event')
      end
    end

    context 'when not permitted to read' do
      it 'returns 404' do
        get api("/projects/#{private_project.id}/events", non_member)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when authenticated' do
      it 'returns project events' do
        get api("/projects/#{private_project.id}/events?action=closed&target_type=issue&after=2016-12-1&before=2016-12-31", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
      end

      it 'returns 404 if project does not exist' do
        get api("/projects/1234/events", user)

        expect(response).to have_gitlab_http_status(404)
      end

      context 'when the requesting token does not have "api" scope' do
        let(:token) { create(:personal_access_token, scopes: ['read_user'], user: user) }

        it 'returns a "403" response' do
          get api("/projects/#{private_project.id}/events", personal_access_token: token)

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context 'when exists some events' do
      let(:merge_request1) { create(:merge_request, :closed, author: user, assignees: [user], source_project: private_project, title: 'Test') }
      let(:merge_request2) { create(:merge_request, :closed, author: user, assignees: [user], source_project: private_project, title: 'Test') }

      before do
        create_event(merge_request1)
      end

      it 'avoids N+1 queries' do
        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get api("/projects/#{private_project.id}/events", user), params: { target_type: :merge_request }
        end.count

        create_event(merge_request2)

        expect do
          get api("/projects/#{private_project.id}/events", user), params: { target_type: :merge_request }
        end.not_to exceed_all_query_limit(control_count)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response.size).to eq(2)
        expect(json_response.map { |r| r['target_id'] }).to match_array([merge_request1.id, merge_request2.id])
      end

      def create_event(target)
        create(:event, project: private_project, author: user, target: target)
      end
    end
  end
end
