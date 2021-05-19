# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Issues do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public, :repository, creator_id: user.id, namespace: user.namespace) }
  let_it_be(:private_mrs_project) do
    create(:project, :public, :repository, creator_id: user.id, namespace: user.namespace, merge_requests_access_level: ProjectFeature::PRIVATE)
  end

  let(:user2)             { create(:user) }
  let(:non_member)        { create(:user) }
  let_it_be(:guest)       { create(:user) }
  let_it_be(:author)      { create(:author) }
  let_it_be(:assignee)    { create(:assignee) }
  let(:admin)             { create(:user, :admin) }
  let(:issue_title)       { 'foo' }
  let(:issue_description) { 'closed' }
  let!(:closed_issue) do
    create :closed_issue,
           author: user,
           assignees: [user],
           project: project,
           state: :closed,
           milestone: milestone,
           created_at: generate(:past_time),
           updated_at: 3.hours.ago,
           closed_at: 1.hour.ago
  end

  let!(:confidential_issue) do
    create :issue,
           :confidential,
           project: project,
           author: author,
           assignees: [assignee],
           created_at: generate(:past_time),
           updated_at: 2.hours.ago
  end

  let!(:issue) do
    create :issue,
           author: user,
           assignees: [user],
           project: project,
           milestone: milestone,
           created_at: generate(:past_time),
           updated_at: 1.hour.ago,
           title: issue_title,
           description: issue_description
  end

  let_it_be(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end

  let!(:label_link) { create(:label_link, label: label, target: issue) }
  let(:milestone) { create(:milestone, title: '1.0.0', project: project) }
  let_it_be(:empty_milestone) do
    create(:milestone, title: '2.0.0', project: project)
  end

  let!(:note) { create(:note_on_issue, author: user, project: project, noteable: issue) }

  let(:no_milestone_title) { 'None' }
  let(:any_milestone_title) { 'Any' }

  before_all do
    project.add_reporter(user)
    project.add_guest(guest)
    private_mrs_project.add_reporter(user)
    private_mrs_project.add_guest(guest)
  end

  before do
    stub_licensed_features(multiple_issue_assignees: false, issue_weights: false)
  end

  shared_examples 'issues statistics' do
    it 'returns issues statistics' do
      get api("/issues_statistics", user), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['statistics']).not_to be_nil
      expect(json_response['statistics']['counts']['all']).to eq counts[:all]
      expect(json_response['statistics']['counts']['closed']).to eq counts[:closed]
      expect(json_response['statistics']['counts']['opened']).to eq counts[:opened]
    end
  end

  describe 'GET /issues/:id' do
    context 'when unauthorized' do
      it 'returns unauthorized' do
        get api("/issues/#{issue.id}" )

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authorized' do
      context 'as a normal user' do
        it 'returns forbidden' do
          get api("/issues/#{issue.id}", user )

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'as an admin' do
        context 'when issue exists' do
          it 'returns the issue' do
            get api("/issues/#{issue.id}", admin)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.dig('author', 'id')).to eq(issue.author.id)
            expect(json_response['description']).to eq(issue.description)
            expect(json_response['issue_type']).to eq('issue')
          end
        end

        context 'when issue does not exist' do
          it 'returns 404' do
            get api("/issues/0", admin)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'GET /issues' do
    context 'when unauthenticated' do
      it 'returns an array of all issues' do
        get api('/issues'), params: { scope: 'all' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
      end

      it 'returns authentication error without any scope' do
        get api('/issues')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns authentication error when scope is assigned-to-me' do
        get api('/issues'), params: { scope: 'assigned-to-me' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns authentication error when scope is created-by-me' do
        get api('/issues'), params: { scope: 'created-by-me' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns an array of issues matching state in milestone' do
        get api('/issues'), params: { milestone: 'foo', scope: 'all' }

        expect(response).to have_gitlab_http_status(:ok)
        expect_paginated_array_response([])
      end

      it 'returns an array of issues matching state in milestone' do
        get api('/issues'), params: { milestone: milestone.title, scope: 'all' }

        expect(response).to have_gitlab_http_status(:ok)
        expect_paginated_array_response([issue.id, closed_issue.id])
      end

      it 'responds with a 401 instead of the specified issue' do
        get api("/issues/#{issue.id}")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      context 'issues_statistics' do
        it 'returns authentication error without any scope' do
          get api('/issues_statistics')

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        it 'returns authentication error when scope is assigned_to_me' do
          get api('/issues_statistics'), params: { scope: 'assigned_to_me' }

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        it 'returns authentication error when scope is created_by_me' do
          get api('/issues_statistics'), params: { scope: 'created_by_me' }

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        context 'no state is treated as all state' do
          let(:params) { {} }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'statistics when all state is passed' do
          let(:params) { { state: :all } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'closed state is treated as all state' do
          let(:params) { { state: :closed } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'opened state is treated as all state' do
          let(:params) { { state: :opened } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'when filtering by milestone and no state treated as all state' do
          let(:params) { { milestone: milestone.title } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'when filtering by milestone and all state' do
          let(:params) { { milestone: milestone.title, state: :all } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'when filtering by milestone and closed state treated as all state' do
          let(:params) { { milestone: milestone.title, state: :closed } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'when filtering by milestone and opened state treated as all state' do
          let(:params) { { milestone: milestone.title, state: :opened } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'sort does not affect statistics ' do
          let(:params) { { state: :opened, order_by: 'updated_at' } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end
      end
    end

    context 'when authenticated' do
      it 'returns an array of issues' do
        get api('/issues', user)

        expect_paginated_array_response([issue.id, closed_issue.id])
        expect(json_response.first['title']).to eq(issue.title)
        expect(json_response.last).to have_key('web_url')
        # Calculating the value of subscribed field triggers Markdown
        # processing. We can't do that for multiple issues / merge
        # requests in a single API request.
        expect(json_response.last).not_to have_key('subscribed')
      end

      it 'returns an array of closed issues' do
        get api('/issues', user), params: { state: :closed }

        expect_paginated_array_response(closed_issue.id)
      end

      it 'returns an array of opened issues' do
        get api('/issues', user), params: { state: :opened }

        expect_paginated_array_response(issue.id)
      end

      it 'returns an array of all issues' do
        get api('/issues', user), params: { state: :all }

        expect_paginated_array_response([issue.id, closed_issue.id])
      end

      it 'returns issues assigned to me' do
        issue2 = create(:issue, assignees: [user2], project: project)

        get api('/issues', user2), params: { scope: 'assigned_to_me' }

        expect_paginated_array_response(issue2.id)
      end

      it 'returns issues assigned to me (kebab-case)' do
        issue2 = create(:issue, assignees: [user2], project: project)

        get api('/issues', user2), params: { scope: 'assigned-to-me' }

        expect_paginated_array_response(issue2.id)
      end

      it 'returns issues authored by the given author id' do
        issue2 = create(:issue, author: user2, project: project)

        get api('/issues', user), params: { author_id: user2.id, scope: 'all' }

        expect_paginated_array_response(issue2.id)
      end

      it 'returns issues assigned to the given assignee id' do
        issue2 = create(:issue, assignees: [user2], project: project)

        get api('/issues', user), params: { assignee_id: user2.id, scope: 'all' }

        expect_paginated_array_response(issue2.id)
      end

      it 'returns issues authored by the given author id and assigned to the given assignee id' do
        issue2 = create(:issue, author: user2, assignees: [user2], project: project)

        get api('/issues', user), params: { author_id: user2.id, assignee_id: user2.id, scope: 'all' }

        expect_paginated_array_response(issue2.id)
      end

      it 'returns issues with no assignee' do
        issue2 = create(:issue, author: user2, project: project)

        get api('/issues', user), params: { assignee_id: 'None', scope: 'all' }

        expect_paginated_array_response(issue2.id)
      end

      it 'returns issues with any assignee' do
        # This issue without assignee should not be returned
        create(:issue, author: user2, project: project)

        get api('/issues', user), params: { assignee_id: 'Any', scope: 'all' }

        expect_paginated_array_response([issue.id, confidential_issue.id, closed_issue.id])
      end

      it 'returns only confidential issues' do
        get api('/issues', user), params: { confidential: true, scope: 'all' }

        expect_paginated_array_response(confidential_issue.id)
      end

      it 'returns only public issues' do
        get api('/issues', user), params: { confidential: false }

        expect_paginated_array_response([issue.id, closed_issue.id])
      end

      it 'returns issues reacted by the authenticated user' do
        issue2 = create(:issue, project: project, author: user, assignees: [user])
        create(:award_emoji, awardable: issue2, user: user2, name: 'star')
        create(:award_emoji, awardable: issue, user: user2, name: 'thumbsup')

        get api('/issues', user2), params: { my_reaction_emoji: 'Any', scope: 'all' }

        expect_paginated_array_response([issue2.id, issue.id])
      end

      it 'returns issues not reacted by the authenticated user' do
        issue2 = create(:issue, project: project, author: user, assignees: [user])
        create(:award_emoji, awardable: issue2, user: user2, name: 'star')

        get api('/issues', user2), params: { my_reaction_emoji: 'None', scope: 'all' }

        expect_paginated_array_response([issue.id, closed_issue.id])
      end

      it 'returns issues with a given issue_type' do
        issue2 = create(:incident, project: project)

        get api('/issues', user), params: { issue_type: 'incident' }

        expect_paginated_array_response(issue2.id)
      end

      it 'returns issues matching given search string for title' do
        get api('/issues', user), params: { search: issue.title }

        expect_paginated_array_response(issue.id)
      end

      it 'returns issues matching given search string for title and scoped in title' do
        get api('/issues', user), params: { search: issue.title, in: 'title' }

        expect_paginated_array_response(issue.id)
      end

      it 'returns an empty array if no issue matches given search string for title and scoped in description' do
        get api('/issues', user), params: { search: issue.title, in: 'description' }

        expect_paginated_array_response([])
      end

      it 'returns issues matching given search string for description' do
        get api('/issues', user), params: { search: issue.description }

        expect_paginated_array_response(issue.id)
      end

      context 'filtering before a specific date' do
        let!(:issue2) { create(:issue, project: project, author: user, created_at: Date.new(2000, 1, 1), updated_at: Date.new(2000, 1, 1)) }

        it 'returns issues created before a specific date' do
          get api('/issues?created_before=2000-01-02T00:00:00.060Z', user)

          expect_paginated_array_response(issue2.id)
        end

        it 'returns issues updated before a specific date' do
          get api('/issues?updated_before=2000-01-02T00:00:00.060Z', user)

          expect_paginated_array_response(issue2.id)
        end
      end

      context 'filtering after a specific date' do
        let!(:issue2) { create(:issue, project: project, author: user, created_at: 1.week.from_now, updated_at: 1.week.from_now) }

        it 'returns issues created after a specific date' do
          get api("/issues?created_after=#{issue2.created_at}", user)

          expect_paginated_array_response(issue2.id)
        end

        it 'returns issues updated after a specific date' do
          get api("/issues?updated_after=#{issue2.updated_at}", user)

          expect_paginated_array_response(issue2.id)
        end
      end

      context 'filtering by due date' do
        # This date chosen because it is the beginning of a week + near the beginning of a month
        let_it_be(:frozen_time) { DateTime.parse('2020-08-03 12:00') }

        let_it_be(:issue2) { create(:issue, project: project, author: user, due_date: frozen_time + 3.days) }
        let_it_be(:issue3) { create(:issue, project: project, author: user, due_date: frozen_time + 10.days) }
        let_it_be(:issue4) { create(:issue, project: project, author: user, due_date: frozen_time + 34.days) }
        let_it_be(:issue5) { create(:issue, project: project, author: user, due_date: frozen_time - 8.days) }

        before do
          travel_to(frozen_time)
        end

        after do
          travel_back
        end

        it 'returns them all when argument is empty' do
          get api('/issues?due_date=', user)

          expect_paginated_array_response(issue5.id, issue4.id, issue3.id, issue2.id, issue.id, closed_issue.id)
        end

        it 'returns issues without due date' do
          get api('/issues?due_date=0', user)

          expect_paginated_array_response(issue.id, closed_issue.id)
        end

        it 'returns issues due for this week' do
          get api('/issues?due_date=week', user)

          expect_paginated_array_response(issue2.id)
        end

        it 'returns issues due for this month' do
          get api('/issues?due_date=month', user)

          expect_paginated_array_response(issue3.id, issue2.id)
        end

        it 'returns issues that are due previous two weeks and next month' do
          get api('/issues?due_date=next_month_and_previous_two_weeks', user)

          expect_paginated_array_response(issue5.id, issue4.id, issue3.id, issue2.id)
        end

        it 'returns issues that are overdue' do
          get api('/issues?due_date=overdue', user)

          expect_paginated_array_response(issue5.id)
        end
      end

      context 'filter by labels or label_name param' do
        context 'N+1' do
          let(:label_b) { create(:label, title: 'foo', project: project) }
          let(:label_c) { create(:label, title: 'bar', project: project) }

          before do
            create(:label_link, label: label_b, target: issue)
            create(:label_link, label: label_c, target: issue)
          end
          it 'tests N+1' do
            control = ActiveRecord::QueryRecorder.new do
              get api('/issues', user), params: { labels: [label.title, label_b.title, label_c.title] }
            end

            label_d = create(:label, title: 'dar', project: project)
            label_e = create(:label, title: 'ear', project: project)
            create(:label_link, label: label_d, target: issue)
            create(:label_link, label: label_e, target: issue)

            expect do
              get api('/issues', user), params: { labels: [label.title, label_b.title, label_c.title] }
            end.not_to exceed_query_limit(control)
            expect(issue.labels.count).to eq(5)
          end
        end

        it 'returns an array of labeled issues' do
          get api('/issues', user), params: { labels: label.title }

          expect_paginated_array_response(issue.id)
          expect(json_response.first['labels']).to eq([label.title])
        end

        it 'returns an array of labeled issues with labels param as array' do
          get api('/issues', user), params: { labels: [label.title] }

          expect_paginated_array_response(issue.id)
          expect(json_response.first['labels']).to eq([label.title])
        end

        context 'with labeled issues' do
          let(:label_b) { create(:label, title: 'foo', project: project) }
          let(:label_c) { create(:label, title: 'bar', project: project) }
          let(:issue2) { create(:issue, author: user, project: project) }

          before do
            create(:label_link, label: label, target: issue2)
            create(:label_link, label: label_b, target: issue)
            create(:label_link, label: label_b, target: issue2)
            create(:label_link, label: label_c, target: issue)

            get api('/issues', user), params: params
          end

          it_behaves_like 'labeled issues with labels and label_name params'
        end

        it 'returns an empty array if no issue matches labels' do
          get api('/issues', user), params: { labels: 'foo,bar' }

          expect_paginated_array_response([])
        end

        it 'returns an empty array if no issue matches labels with labels param as array' do
          get api('/issues', user), params: { labels: %w(foo bar) }

          expect_paginated_array_response([])
        end

        it 'returns an array of labeled issues matching given state' do
          get api('/issues', user), params: { labels: label.title, state: :opened }

          expect_paginated_array_response(issue.id)
          expect(json_response.first['labels']).to eq([label.title])
          expect(json_response.first['state']).to eq('opened')
        end

        it 'returns an array of labeled issues matching given state with labels param as array' do
          get api('/issues', user), params: { labels: [label.title], state: :opened }

          expect_paginated_array_response(issue.id)
          expect(json_response.first['labels']).to eq([label.title])
          expect(json_response.first['state']).to eq('opened')
        end

        it 'returns an empty array if no issue matches labels and state filters' do
          get api('/issues', user), params: { labels: label.title, state: :closed }

          expect_paginated_array_response([])
        end

        it 'returns an array of issues with any label' do
          get api('/issues', user), params: { labels: IssuableFinder::Params::FILTER_ANY }

          expect_paginated_array_response(issue.id)
        end

        it 'returns an array of issues with any label with labels param as array' do
          get api('/issues', user), params: { labels: [IssuableFinder::Params::FILTER_ANY] }

          expect_paginated_array_response(issue.id)
        end

        it 'returns an array of issues with no label' do
          get api('/issues', user), params: { labels: IssuableFinder::Params::FILTER_NONE }

          expect_paginated_array_response(closed_issue.id)
        end

        it 'returns an array of issues with no label with labels param as array' do
          get api('/issues', user), params: { labels: [IssuableFinder::Params::FILTER_NONE] }

          expect_paginated_array_response(closed_issue.id)
        end
      end

      context 'filter by milestone' do
        it 'returns an empty array if no issue matches milestone' do
          get api("/issues?milestone=#{empty_milestone.title}", user)

          expect_paginated_array_response([])
        end

        it 'returns an empty array if milestone does not exist' do
          get api('/issues?milestone=foo', user)

          expect_paginated_array_response([])
        end

        it 'returns an array of issues in given milestone' do
          get api("/issues?milestone=#{milestone.title}", user)

          expect_paginated_array_response([issue.id, closed_issue.id])
        end

        it 'returns an array of issues in given milestone_title param' do
          get api("/issues?milestone_title=#{milestone.title}", user)

          expect_paginated_array_response([issue.id, closed_issue.id])
        end

        it 'returns an array of issues matching state in milestone' do
          get api("/issues?milestone=#{milestone.title}&state=closed", user)

          expect_paginated_array_response(closed_issue.id)
        end

        it 'returns an array of issues with no milestone' do
          get api("/issues?milestone=#{no_milestone_title}", author)

          expect_paginated_array_response(confidential_issue.id)
        end

        it 'returns an array of issues with no milestone using milestone_title param' do
          get api("/issues?milestone_title=#{no_milestone_title}", author)

          expect_paginated_array_response(confidential_issue.id)
        end

        context 'negated' do
          it 'returns all issues if milestone does not exist' do
            get api('/issues?not[milestone]=foo', user)

            expect_paginated_array_response([issue.id, closed_issue.id])
          end

          it 'returns all issues that do not belong to a milestone but have a milestone' do
            get api("/issues?not[milestone]=#{empty_milestone.title}", user)

            expect_paginated_array_response([issue.id, closed_issue.id])
          end

          it 'returns an array of issues with any milestone' do
            get api("/issues?not[milestone]=#{no_milestone_title}", user)

            expect_paginated_array_response([issue.id, closed_issue.id])
          end

          it 'returns an array of issues matching state not in milestone' do
            get api("/issues?not[milestone]=#{empty_milestone.title}&state=closed", user)

            expect_paginated_array_response(closed_issue.id)
          end
        end
      end

      it 'returns an array of issues found by iids' do
        get api('/issues', user), params: { iids: [closed_issue.iid] }

        expect_paginated_array_response(closed_issue.id)
      end

      it 'returns an empty array if iid does not exist' do
        get api('/issues', user), params: { iids: [0] }

        expect_paginated_array_response([])
      end

      context 'without sort params' do
        it 'sorts by created_at descending by default' do
          get api('/issues', user)

          expect_paginated_array_response([issue.id, closed_issue.id])
        end

        context 'with 2 issues with same created_at' do
          let!(:closed_issue2) do
            create :closed_issue,
                   author: user,
                   assignees: [user],
                   project: project,
                   milestone: milestone,
                   created_at: closed_issue.created_at,
                   updated_at: 1.hour.ago,
                   title: issue_title,
                   description: issue_description
          end

          it 'page breaks first page correctly' do
            get api('/issues?per_page=2', user)

            expect_paginated_array_response([issue.id, closed_issue2.id])
          end

          it 'page breaks second page correctly' do
            get api('/issues?per_page=2&page=2', user)

            expect_paginated_array_response([closed_issue.id])
          end
        end
      end

      it 'sorts ascending when requested' do
        get api('/issues?sort=asc', user)

        expect_paginated_array_response([closed_issue.id, issue.id])
      end

      it 'sorts by updated_at descending when requested' do
        get api('/issues?order_by=updated_at', user)

        issue.touch(:updated_at)

        expect_paginated_array_response([issue.id, closed_issue.id])
      end

      it 'sorts by updated_at ascending when requested' do
        get api('/issues?order_by=updated_at&sort=asc', user)

        issue.touch(:updated_at)

        expect_paginated_array_response([closed_issue.id, issue.id])
      end

      context 'with issues list sort options' do
        it 'accepts only predefined order by params' do
          API::Helpers::IssuesHelpers.sort_options.each do |sort_opt|
            get api('/issues', user), params: { order_by: sort_opt, sort: 'asc' }
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        it 'fails to sort with non predefined options' do
          %w(milestone title abracadabra).each do |sort_opt|
            get api('/issues', user), params: { order_by: sort_opt, sort: 'asc' }
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      it 'matches V4 response schema' do
        get api('/issues', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/issues')
      end

      it 'returns a related merge request count of 0 if there are no related merge requests' do
        get api('/issues', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/issues')
        expect(json_response.first).to include('merge_requests_count' => 0)
      end

      it 'returns a related merge request count > 0 if there are related merge requests' do
        create(:merge_requests_closing_issues, issue: issue)

        get api('/issues', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/issues')
        expect(json_response.first).to include('merge_requests_count' => 1)
      end

      context 'issues_statistics' do
        context 'no state is treated as all state' do
          let(:params) { {} }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'statistics when all state is passed' do
          let(:params) { { state: :all } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'closed state is treated as all state' do
          let(:params) { { state: :closed } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'opened state is treated as all state' do
          let(:params) { { state: :opened } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'when filtering by milestone and no state treated as all state' do
          let(:params) { { milestone: milestone.title } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'when filtering by milestone and all state' do
          let(:params) { { milestone: milestone.title, state: :all } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'when filtering by milestone and closed state treated as all state' do
          let(:params) { { milestone: milestone.title, state: :closed } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'when filtering by milestone and opened state treated as all state' do
          let(:params) { { milestone: milestone.title, state: :opened } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end

        context 'sort does not affect statistics ' do
          let(:params) { { state: :opened, order_by: 'updated_at' } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'issues statistics'
        end
      end

      context 'filtering by assignee_username' do
        let(:another_assignee) { create(:assignee) }
        let!(:issue1) { create(:issue, author: user2, project: project, created_at: 3.days.ago) }
        let!(:issue2) { create(:issue, author: user2, project: project, created_at: 2.days.ago) }
        let!(:issue3) { create(:issue, author: user2, assignees: [assignee, another_assignee], project: project, created_at: 1.day.ago) }

        it 'returns issues with by assignee_username' do
          get api("/issues", user), params: { assignee_username: [assignee.username], scope: 'all' }

          expect(issue3.reload.assignees.pluck(:id)).to match_array([assignee.id, another_assignee.id])
          expect_paginated_array_response([confidential_issue.id, issue3.id])
        end

        it 'returns issues by assignee_username as string' do
          get api("/issues", user), params: { assignee_username: assignee.username, scope: 'all' }

          expect(issue3.reload.assignees.pluck(:id)).to match_array([assignee.id, another_assignee.id])
          expect_paginated_array_response([confidential_issue.id, issue3.id])
        end

        it 'returns error when multiple assignees are passed' do
          get api("/issues", user), params: { assignee_username: [assignee.username, another_assignee.username], scope: 'all' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response["error"]).to include("allows one value, but found 2")
        end

        it 'returns error when assignee_username and assignee_id are passed together' do
          get api("/issues", user), params: { assignee_username: [assignee.username], assignee_id: another_assignee.id, scope: 'all' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response["error"]).to include("mutually exclusive")
        end
      end

      context 'filtering by non_archived' do
        let_it_be(:archived_project) { create(:project, :archived, creator_id: user.id, namespace: user.namespace) }
        let_it_be(:archived_issue) { create(:issue, author: user, project: archived_project) }
        let_it_be(:active_issue) { create(:issue, author: user, project: project) }

        it 'returns issues from non archived projects by default' do
          get api('/issues', user)

          expect_paginated_array_response(active_issue.id, issue.id, closed_issue.id)
        end

        it 'returns issues from archived project with non_archived set as false' do
          get api("/issues", user), params: { non_archived: false }

          expect_paginated_array_response(active_issue.id, archived_issue.id, issue.id, closed_issue.id)
        end
      end
    end

    context "when returns issue merge_requests_count for different access levels" do
      let!(:merge_request1) do
        create(:merge_request,
               :simple,
               author: user,
               source_project: private_mrs_project,
               target_project: private_mrs_project,
               description: "closes #{issue.to_reference(private_mrs_project)}")
      end

      let!(:merge_request2) do
        create(:merge_request,
               :simple,
               author: user,
               source_project: project,
               target_project: project,
               description: "closes #{issue.to_reference}")
      end

      it_behaves_like 'accessible merge requests count' do
        let(:api_url) { "/issues" }
        let(:target_issue) { issue }
      end
    end
  end

  describe 'GET /projects/:id/issues/:issue_iid' do
    it 'exposes full reference path' do
      get api("/projects/#{project.id}/issues/#{issue.iid}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['references']['short']).to eq("##{issue.iid}")
      expect(json_response['references']['relative']).to eq("##{issue.iid}")
      expect(json_response['references']['full']).to eq("#{project.parent.path}/#{project.path}##{issue.iid}")
    end
  end

  describe "POST /projects/:id/issues" do
    it 'creates a new project issue' do
      post api("/projects/#{project.id}/issues", user), params: { title: 'new issue' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['issue_type']).to eq('issue')
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid' do
    it_behaves_like 'issuable update endpoint' do
      let(:entity) { issue }
    end

    describe 'updated_at param' do
      let(:fixed_time) { Time.new(2001, 1, 1) }
      let(:updated_at) { Time.new(2000, 1, 1) }

      before do
        travel_to fixed_time
      end

      it 'allows admins to set the timestamp' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", admin), params: { labels: 'label1', updated_at: updated_at }

        expect(response).to have_gitlab_http_status(:ok)
        expect(Time.parse(json_response['updated_at'])).to be_like_time(updated_at)
        expect(ResourceLabelEvent.last.created_at).to be_like_time(updated_at)
      end

      it 'does not allow other users to set the timestamp' do
        reporter = create(:user)
        project.add_developer(reporter)

        put api("/projects/#{project.id}/issues/#{issue.iid}", reporter), params: { labels: 'label1', updated_at: updated_at }

        expect(response).to have_gitlab_http_status(:ok)
        expect(Time.parse(json_response['updated_at'])).to be_like_time(fixed_time)
        expect(ResourceLabelEvent.last.created_at).to be_like_time(fixed_time)
      end
    end

    describe 'issue_type param' do
      it 'allows issue type to be converted' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user), params: { issue_type: 'incident' }

        expect(issue.reload.incident?).to be(true)
      end
    end
  end

  describe 'DELETE /projects/:id/issues/:issue_iid' do
    it 'rejects a non member from deleting an issue' do
      delete api("/projects/#{project.id}/issues/#{issue.iid}", non_member)
      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'rejects a developer from deleting an issue' do
      delete api("/projects/#{project.id}/issues/#{issue.iid}", author)
      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'when the user is project owner' do
      let(:owner)     { create(:user) }
      let(:project)   { create(:project, namespace: owner.namespace) }

      it 'deletes the issue if an admin requests it' do
        delete api("/projects/#{project.id}/issues/#{issue.iid}", owner)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/issues/#{issue.iid}", owner) }
      end
    end

    context 'when issue does not exist' do
      it 'returns 404 when trying to delete an issue' do
        delete api("/projects/#{project.id}/issues/123", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'returns 404 when using the issue ID instead of IID' do
      delete api("/projects/#{project.id}/issues/#{issue.id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'time tracking endpoints' do
    let(:issuable) { issue }

    include_examples 'time tracking endpoints', 'issue'
  end

  describe 'PUT /projects/:id/issues/:issue_iid/reorder' do
    let_it_be(:project) { create(:project) }
    let_it_be(:issue1) { create(:issue, project: project, relative_position: 10) }
    let_it_be(:issue2) { create(:issue, project: project, relative_position: 20) }
    let_it_be(:issue3) { create(:issue, project: project, relative_position: 30) }

    context 'when user has access' do
      before do
        project.add_developer(user)
      end

      context 'with valid params' do
        it 'reorders issues and returns a successful 200 response' do
          put api("/projects/#{project.id}/issues/#{issue1.iid}/reorder", user), params: { move_after_id: issue2.id, move_before_id: issue3.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(issue1.reload.relative_position)
                .to be_between(issue2.reload.relative_position, issue3.reload.relative_position)
        end
      end

      context 'with invalid params' do
        it 'returns a unprocessable entity 422 response for invalid move ids' do
          put api("/projects/#{project.id}/issues/#{issue1.iid}/reorder", user), params: { move_after_id: issue2.id, move_before_id: non_existing_record_id }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end

        it 'returns a not found 404 response for invalid issue id' do
          put api("/projects/#{project.id}/issues/#{non_existing_record_iid}/reorder", user), params: { move_after_id: issue2.id, move_before_id: issue3.id }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        project.add_guest(user)
      end

      it 'responds with 403 forbidden' do
        put api("/projects/#{project.id}/issues/#{issue1.iid}/reorder", user), params: { move_after_id: issue2.id, move_before_id: issue3.id }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
