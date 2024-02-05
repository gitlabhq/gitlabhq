# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectEvents, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:private_project) { create(:project, :private, creator_id: user.id, namespace: user.namespace) }
  let_it_be(:closed_issue) { create(:closed_issue, project: private_project, author: user) }
  let_it_be(:closed_issue_event) { create(:closed_issue_event, project: private_project, author: user, target: closed_issue, created_at: Date.new(2016, 12, 30)) }

  describe 'GET /projects/:id/events' do
    context 'when unauthenticated ' do
      it 'returns 404 for private project' do
        get api("/projects/#{private_project.id}/events")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 200 status for a public project' do
        public_project = create(:project, :public)

        get api("/projects/#{public_project.id}/events")

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with inaccessible events' do
      let_it_be(:public_project) { create(:project, :public, creator_id: user.id, namespace: user.namespace) }
      let_it_be(:confidential_issue) { create(:closed_issue, :confidential, project: public_project, author: user) }
      let_it_be(:confidential_event) { create(:closed_issue_event, project: public_project, author: user, target: confidential_issue) }
      let_it_be(:public_issue) { create(:closed_issue, project: public_project, author: user) }
      let_it_be(:public_event) { create(:closed_issue_event, project: public_project, author: user, target: public_issue) }

      it 'returns only accessible events' do
        get api("/projects/#{public_project.id}/events", non_member)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(1)
      end

      it 'returns all events when the user has access' do
        get api("/projects/#{public_project.id}/events", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(2)
      end
    end

    context 'pagination' do
      let(:public_project) { create(:project, :public) }

      before do
        create(
          :event,
          :closed,
          project: public_project,
          target: create(:issue, project: public_project, title: 'Issue 1'),
          created_at: Date.parse('2018-12-10')
        )
        create(
          :event,
          :closed,
          project: public_project,
          target: create(:issue, confidential: true, project: public_project, title: 'Confidential event'),
          created_at: Date.parse('2018-12-11')
        )
        create(
          :event,
          :closed,
          project: public_project,
          target: create(:issue, project: public_project, title: 'Issue 2'),
          created_at: Date.parse('2018-12-12')
        )
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

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when authenticated' do
      it 'returns project events' do
        get api("/projects/#{private_project.id}/events?action=closed&target_type=issue&after=2016-12-1&before=2016-12-31", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
      end

      it 'returns 404 if project does not exist' do
        get api("/projects/#{non_existing_record_id}/events", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when the requesting token does not have "api" scope' do
        let(:token) { create(:personal_access_token, scopes: ['read_user'], user: user) }

        it 'returns a "403" response' do
          get api("/projects/#{private_project.id}/events", personal_access_token: token)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when exists some events' do
      let_it_be(:merge_request1) { create(:closed_merge_request, author: user, assignees: [user], source_project: private_project) }
      let_it_be(:merge_request2) { create(:closed_merge_request, author: user, assignees: [user], source_project: private_project) }

      let_it_be(:token) { create(:personal_access_token, user: user) }

      before do
        create_event(merge_request1)
      end

      it 'avoids N+1 queries' do
        # Warmup, e.g. users#last_activity_on
        get api("/projects/#{private_project.id}/events", personal_access_token: token), params: { target_type: :merge_request }

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get api("/projects/#{private_project.id}/events", personal_access_token: token), params: { target_type: :merge_request }
        end

        create_event(merge_request2)

        expect do
          get api("/projects/#{private_project.id}/events", personal_access_token: token), params: { target_type: :merge_request }
        end.to issue_same_number_of_queries_as(control).with_threshold(1)
        # The extra threshold is because we need to fetch `project` for the 2nd
        # event. This is because in `app/policies/issuable_policy.rb`, we fetch
        # the `project` for the `target` for the `event`. It is non-trivial to
        # re-use the original `project` object from `lib/api/project_events.rb`
        #
        # https://gitlab.com/gitlab-org/gitlab/-/issues/432823

        expect(response).to have_gitlab_http_status(:ok)
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
