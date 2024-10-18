# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Issues, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public, :repository, creator_id: user.id, namespace: user.namespace, reporters: user) }
  let_it_be(:private_mrs_project) do
    create(:project, :public, :repository, creator_id: user.id, namespace: user.namespace, merge_requests_access_level: ProjectFeature::PRIVATE, reporters: user)
  end

  let_it_be(:user2) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:guest)       { create(:user, guest_of: [project, private_mrs_project]) }
  let_it_be(:author)      { create(:author) }
  let_it_be(:assignee)    { create(:assignee) }
  let_it_be(:admin) { create(:user, :admin) }

  let_it_be(:milestone) { create(:milestone, title: '1.0.0', project: project) }
  let_it_be(:empty_milestone) { create(:milestone, title: '2.0.0', project: project) }
  let_it_be(:objective) { create(:issue, :objective, author: user, project: project) }

  let_it_be(:closed_issue) do
    create(
      :closed_issue,
      author: user,
      assignees: [user],
      project: project,
      state: :closed,
      milestone: milestone,
      created_at: generate(:past_time),
      updated_at: 3.hours.ago,
      closed_at: 1.hour.ago
    )
  end

  let_it_be(:confidential_issue) do
    create(
      :issue,
      :confidential,
      project: project,
      author: author,
      assignees: [assignee],
      created_at: generate(:past_time),
      updated_at: 2.hours.ago
    )
  end

  let_it_be(:issue) do
    create(
      :issue,
      author: user,
      assignees: [user],
      project: project,
      milestone: milestone,
      created_at: generate(:past_time),
      updated_at: 1.hour.ago,
      title: 'foo',
      description: 'bar'
    )
  end

  let_it_be(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end

  let_it_be(:label_link) { create(:label_link, label: label, target: issue) }
  let_it_be(:note) { create(:note_on_issue, author: user, project: project, noteable: issue) }

  let(:no_milestone_title) { 'None' }
  let(:any_milestone_title) { 'Any' }

  before do
    stub_licensed_features(multiple_issue_assignees: false, issue_weights: false)
  end

  shared_examples 'issues statistics' do
    it 'returns issues statistics', :aggregate_failures do
      get api("/issues_statistics", user), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['statistics']).not_to be_nil
      expect(json_response['statistics']['counts']['all']).to eq counts[:all]
      expect(json_response['statistics']['counts']['closed']).to eq counts[:closed]
      expect(json_response['statistics']['counts']['opened']).to eq counts[:opened]
    end
  end

  describe 'GET /issues/:id' do
    let(:path) { "/issues/#{issue.id}" }

    it_behaves_like 'GET request permissions for admin mode'

    context 'when unauthorized' do
      it 'returns unauthorized' do
        get api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authorized' do
      context 'as a normal user' do
        it 'returns forbidden' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'as an admin' do
        context 'when issue exists' do
          it 'returns the issue', :aggregate_failures do
            get api(path, admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.dig('author', 'id')).to eq(issue.author.id)
            expect(json_response['description']).to eq(issue.description)
            expect(json_response['issue_type']).to eq('issue')
          end
        end

        context 'when issue does not exist' do
          it 'returns 404' do
            get api("/issues/#{non_existing_record_id}", admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'GET /issues' do
    context 'when unauthenticated' do
      it 'returns an array of all issues', :aggregate_failures do
        get api('/issues'), params: { scope: 'all' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
      end

      it_behaves_like 'issuable API rate-limited search' do
        let(:url) { '/issues' }
        let(:issuable) { issue }
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

      it 'returns an array of issues matching state in milestone', :aggregate_failures do
        get api('/issues'), params: { milestone: 'foo', scope: 'all' }

        expect(response).to have_gitlab_http_status(:ok)
        expect_paginated_array_response([])
      end

      it 'returns an array of issues matching state in milestone', :aggregate_failures do
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

        context 'with search param' do
          let(:params) { { scope: 'all', search: 'foo' } }
          let(:counts) { { all: 1, closed: 0, opened: 1 } }

          it_behaves_like 'issues statistics'
        end
      end
    end

    context 'when authenticated' do
      it 'returns an array of issues', :aggregate_failures do
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
        create(:award_emoji, awardable: issue, user: user2, name: AwardEmoji::THUMBS_UP)

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
        let_it_be(:issue6) { create(:issue, project: project, author: user, due_date: frozen_time) }
        let_it_be(:issue7) { create(:issue, project: project, author: user, due_date: frozen_time + 1.day) }

        before do
          travel_to(frozen_time)
        end

        after do
          travel_back
        end

        it 'returns them all when argument is empty' do
          get api('/issues?due_date=', user)

          expect_paginated_array_response(issue7.id, issue6.id, issue5.id, issue4.id, issue3.id, issue2.id, issue.id, closed_issue.id)
        end

        it 'returns issues with due date' do
          get api('/issues?due_date=any', user)

          expect_paginated_array_response(issue7.id, issue6.id, issue5.id, issue4.id, issue3.id, issue2.id)
        end

        it 'returns issues without due date' do
          get api('/issues?due_date=0', user)

          expect_paginated_array_response(issue.id, closed_issue.id)
        end

        it 'returns issues due for this week' do
          get api('/issues?due_date=week', user)

          expect_paginated_array_response(issue7.id, issue6.id, issue2.id)
        end

        it 'returns issues due for this month' do
          get api('/issues?due_date=month', user)

          expect_paginated_array_response(issue7.id, issue6.id, issue3.id, issue2.id)
        end

        it 'returns issues that are due previous two weeks and next month' do
          get api('/issues?due_date=next_month_and_previous_two_weeks', user)

          expect_paginated_array_response(issue7.id, issue6.id, issue5.id, issue4.id, issue3.id, issue2.id)
        end

        it 'returns issues that are due today' do
          get api('/issues?due_date=today', user)

          expect_paginated_array_response(issue6.id)
        end

        it 'returns issues that are due tomorrow' do
          get api('/issues?due_date=tomorrow', user)

          expect_paginated_array_response(issue7.id)
        end

        it 'returns issues that are overdue' do
          get api('/issues?due_date=overdue', user)

          expect_paginated_array_response(issue5.id)
        end
      end

      context 'with incident issues' do
        let_it_be(:incident) { create(:incident, project: project) }

        it 'avoids N+1 queries', :aggregate_failures do
          get api('/issues', user) # warm up

          control = ActiveRecord::QueryRecorder.new do
            get api('/issues', user)
          end

          create(:incident, project: project)
          create(:incident, project: project)

          expect do
            get api('/issues', user)
          end.not_to exceed_query_limit(control)
          # 2 pre-existed issues + 3 incidents
          expect(json_response.count).to eq(5)
        end
      end

      context 'with issues closed as duplicates' do
        let_it_be(:dup_issue_1) { create(:issue, :closed_as_duplicate, project: project) }

        it 'avoids N+1 queries', :aggregate_failures do
          get api('/issues', user) # warm up

          control = ActiveRecord::QueryRecorder.new do
            get api('/issues', user)
          end

          create(:issue, :closed_as_duplicate, project: project)

          expect do
            get api('/issues', user)
          end.not_to exceed_query_limit(control)
          # 2 pre-existed issues + 2 duplicated incidents (2 closed, 2 new)
          expect(json_response.count).to eq(6)
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
          get api('/issues', user), params: { labels: %w[foo bar] }

          expect_paginated_array_response([])
        end

        it 'returns an array of labeled issues matching given state', :aggregate_failures do
          get api('/issues', user), params: { labels: label.title, state: :opened }

          expect_paginated_array_response(issue.id)
          expect(json_response.first['labels']).to eq([label.title])
          expect(json_response.first['state']).to eq('opened')
        end

        it 'returns an array of labeled issues matching given state with labels param as array', :aggregate_failures do
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

      context 'filtering by milestone_id' do
        let_it_be(:upcoming_milestone) { create(:milestone, project: project, title: "upcoming milestone", start_date: 1.day.ago, due_date: 1.day.from_now) }
        let_it_be(:started_milestone) { create(:milestone, project: project, title: "started milestone", start_date: 2.days.ago, due_date: 1.day.ago) }
        let_it_be(:future_milestone) { create(:milestone, project: project, title: "future milestone", start_date: 7.days.from_now, due_date: 14.days.from_now) }
        let_it_be(:issue_upcoming) { create(:issue, project: project, state: :opened, milestone: upcoming_milestone) }
        let_it_be(:issue_started) { create(:issue, project: project, state: :opened, milestone: started_milestone) }
        let_it_be(:issue_future) { create(:issue, project: project, state: :opened, milestone: future_milestone) }
        let_it_be(:issue_none) { create(:issue, project: project, state: :opened) }

        let(:wildcard_started) { 'Started' }
        let(:wildcard_upcoming) { 'Upcoming' }
        let(:wildcard_any) { 'Any' }
        let(:wildcard_none) { 'None' }

        where(:milestone_id, :not_milestone, :expected_issues) do
          ref(:wildcard_none)     | nil | lazy { [issue_none.id] }
          ref(:wildcard_any)      | nil | lazy { [issue_future.id, issue_started.id, issue_upcoming.id, issue.id, closed_issue.id] }
          ref(:wildcard_started)  | nil | lazy { [issue_started.id, issue_upcoming.id] }
          ref(:wildcard_upcoming) | nil | lazy { [issue_upcoming.id] }
          ref(:wildcard_any)      | "upcoming milestone" | lazy { [issue_future.id, issue_started.id, issue.id, closed_issue.id] }
          ref(:wildcard_upcoming) | "upcoming milestone" | []
        end

        with_them do
          it "returns correct issues when filtering with 'milestone_id' and optionally negated 'milestone'" do
            get api('/issues', user), params: { milestone_id: milestone_id, not: not_milestone ? { milestone: not_milestone } : {} }

            expect_paginated_array_response(expected_issues)
          end
        end

        context 'negated filtering' do
          where(:not_milestone_id, :expected_issues) do
            ref(:wildcard_started)  | lazy { [issue_future.id] }
            ref(:wildcard_upcoming) | lazy { [issue_started.id] }
          end

          with_them do
            it "returns correct issues when filtering with negated 'milestone_id'" do
              get api('/issues', user), params: { not: { milestone_id: not_milestone_id } }

              expect_paginated_array_response(expected_issues)
            end
          end
        end

        context 'when mutually exclusive params are passed' do
          where(:params) do
            [
              [lazy { { milestone: "foo", milestone_id: wildcard_any } }],
              [lazy { { not: { milestone: "foo", milestone_id: wildcard_any } } }]
            ]
          end

          with_them do
            it "raises an error", :aggregate_failures do
              get api('/issues', user), params: params

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response["error"]).to include("mutually exclusive")
            end
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
            create(
              :closed_issue,
              author: user,
              assignees: [user],
              project: project,
              milestone: milestone,
              created_at: closed_issue.created_at,
              updated_at: 1.hour.ago,
              title: 'foo',
              description: 'bar'
            )
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

      it 'sorts by title asc when requested' do
        get api('/issues', user), params: { order_by: :title, sort: :asc }

        expect_paginated_array_response([issue.id, closed_issue.id])
      end

      it 'sorts by title desc when requested' do
        get api('/issues', user), params: { order_by: :title, sort: :desc }

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
          %w[milestone abracadabra].each do |sort_opt|
            get api('/issues', user), params: { order_by: sort_opt, sort: 'asc' }
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      it 'matches V4 response schema', :aggregate_failures do
        get api('/issues', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/issues')
      end

      it 'returns a related merge request count of 0 if there are no related merge requests', :aggregate_failures do
        get api('/issues', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/issues')
        expect(json_response.first).to include('merge_requests_count' => 0)
      end

      it 'returns a related merge request count > 0 if there are related merge requests', :aggregate_failures do
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

        it 'returns issues with by assignee_username', :aggregate_failures do
          get api("/issues", user), params: { assignee_username: [assignee.username], scope: 'all' }

          expect(issue3.reload.assignees.pluck(:id)).to match_array([assignee.id, another_assignee.id])
          expect_paginated_array_response([confidential_issue.id, issue3.id])
        end

        it 'returns issues by assignee_username as string', :aggregate_failures do
          get api("/issues", user), params: { assignee_username: assignee.username, scope: 'all' }

          expect(issue3.reload.assignees.pluck(:id)).to match_array([assignee.id, another_assignee.id])
          expect_paginated_array_response([confidential_issue.id, issue3.id])
        end

        it 'returns error when multiple assignees are passed', :aggregate_failures do
          get api("/issues", user), params: { assignee_username: [assignee.username, another_assignee.username], scope: 'all' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response["error"]).to include("allows one value, but found 2")
        end

        it 'returns error when assignee_username and assignee_id are passed together', :aggregate_failures do
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
        create(
          :merge_request,
          :simple,
          author: user,
          source_project: private_mrs_project,
          target_project: private_mrs_project,
          description: "closes #{issue.to_reference(private_mrs_project)}"
        )
      end

      let!(:merge_request2) do
        create(
          :merge_request,
          :simple,
          author: user,
          source_project: project,
          target_project: project,
          description: "closes #{issue.to_reference}"
        )
      end

      it_behaves_like 'accessible merge requests count' do
        let(:api_url) { "/issues" }
        let(:target_issue) { issue }
      end
    end

    context 'when authenticated with a token that has the ai_workflows scope' do
      let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

      subject(:get_issues) { get api('/issues', oauth_access_token: oauth_token) }

      it 'is successful' do
        get_issues

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET /projects/:id/issues' do
    context 'when authenticated with a token that has the ai_workflows scope' do
      let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

      subject(:get_project_issues) { get api("/projects/#{project.id}/issues", oauth_access_token: oauth_token) }

      it 'is successful' do
        get_project_issues

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET /projects/:id/issues/:issue_iid' do
    it 'exposes full reference path', :aggregate_failures do
      get api("/projects/#{project.id}/issues/#{issue.iid}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['references']['short']).to eq("##{issue.iid}")
      expect(json_response['references']['relative']).to eq("##{issue.iid}")
      expect(json_response['references']['full']).to eq("#{project.parent.path}/#{project.path}##{issue.iid}")
    end

    context 'when issue is closed as duplicate' do
      let(:new_issue) { create(:issue) }
      let!(:issue_closed_as_dup) { create(:issue, project: project, duplicated_to: new_issue) }

      before do
        project.add_developer(user)
      end

      context 'user does not have permission to view new issue' do
        it 'does not return the issue as closed_as_duplicate_of', :aggregate_failures do
          get api("/projects/#{project.id}/issues/#{issue_closed_as_dup.iid}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.dig('_links', 'closed_as_duplicate_of')).to eq(nil)
        end
      end

      context 'when user has access to new issue' do
        before do
          new_issue.project.add_guest(user)
        end

        it 'returns the issue as closed_as_duplicate_of', :aggregate_failures do
          get api("/projects/#{project.id}/issues/#{issue_closed_as_dup.iid}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expected_url = expose_url(api_v4_project_issue_path(id: new_issue.project_id, issue_iid: new_issue.iid))
          expect(json_response.dig('_links', 'closed_as_duplicate_of')).to eq(expected_url)
        end
      end
    end
  end

  describe "POST /projects/:id/issues" do
    it 'creates a new project issue', :aggregate_failures do
      post api("/projects/#{project.id}/issues", user), params: { title: 'new issue' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['issue_type']).to eq('issue')
    end

    context 'when confidential is null' do
      it 'responds with 400 error', :aggregate_failures do
        post api("/projects/#{project.id}/issues", user), params: { title: 'issue', confidential: nil }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('confidential is empty')
      end
    end

    context 'when issue create service returns an unrecoverable error' do
      before do
        allow_next_instance_of(Issues::CreateService) do |create_service|
          allow(create_service).to receive(:execute).and_return(ServiceResponse.error(message: 'some error', http_status: 403))
        end
      end

      it 'returns and error message and status code from the service', :aggregate_failures do
        post api("/projects/#{project.id}/issues", user), params: { title: 'new issue' }

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('some error')
      end
    end

    context 'when authenticated with a token that has the ai_workflows scope' do
      let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

      subject(:create_issue) { post api("/projects/#{project.id}/issues", oauth_access_token: oauth_token), params: { title: 'new issue' } }

      it 'is successful' do
        create_issue

        expect(response).to have_gitlab_http_status(:created)
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid' do
    it_behaves_like 'issuable update endpoint' do
      let(:entity) { issue }
    end

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:path) { "/projects/#{project.id}/issues/#{issue.iid}" }
      let(:params) { { labels: 'label1', updated_at: Time.new(2000, 1, 1) } }
    end

    describe 'updated_at param' do
      let(:fixed_time) { Time.new(2001, 1, 1) }
      let(:updated_at) { Time.new(2000, 1, 1) }

      before do
        travel_to fixed_time
      end

      it 'allows admins to set the timestamp', :aggregate_failures do
        put api("/projects/#{project.id}/issues/#{issue.iid}", admin, admin_mode: true), params: { labels: 'label1', updated_at: updated_at }

        expect(response).to have_gitlab_http_status(:ok)
        expect(Time.parse(json_response['updated_at'])).to be_like_time(updated_at)
        expect(ResourceLabelEvent.last.created_at).to be_like_time(updated_at)
      end

      it 'does not allow other users to set the timestamp', :aggregate_failures do
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

        expect(issue.reload.work_item_type.incident?).to be(true)
      end
    end

    context 'when authenticated with a token that has the ai_workflows scope' do
      let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

      subject(:update_issue) { put api("/projects/#{project.id}/issues/#{issue.iid}", oauth_access_token: oauth_token), params: { title: 'updated issue' } }

      it 'is successful' do
        update_issue

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'DELETE /projects/:id/issues/:issue_iid' do
    let(:issue_for_deletion) { create(:issue, author: user, assignees: [user], project: project) }

    it 'rejects a non member from deleting an issue' do
      delete api("/projects/#{project.id}/issues/#{issue_for_deletion.iid}", non_member)
      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'rejects a developer from deleting an issue' do
      delete api("/projects/#{project.id}/issues/#{issue_for_deletion.iid}", author)
      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'when the user is project owner' do
      let(:owner)     { create(:user) }
      let(:project)   { create(:project, namespace: owner.namespace) }

      it 'deletes the issue if an admin requests it' do
        delete api("/projects/#{project.id}/issues/#{issue_for_deletion.iid}", owner)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/issues/#{issue_for_deletion.iid}", owner) }
      end
    end

    context 'when issue does not exist' do
      it 'returns 404 when trying to delete an issue' do
        delete api("/projects/#{project.id}/issues/123", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'returns 404 when using the issue ID instead of IID' do
      delete api("/projects/#{project.id}/issues/#{issue_for_deletion.id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'time tracking endpoints' do
    let(:issuable) { issue }

    include_examples 'time tracking endpoints', 'issue'
  end

  describe 'PUT /projects/:id/issues/:issue_iid/reorder' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue1) { create(:issue, project: project, relative_position: 10) }
    let_it_be(:issue2) { create(:issue, project: project, relative_position: 20) }
    let_it_be(:issue3) { create(:issue, project: project, relative_position: 30) }

    context 'when user has access' do
      before_all do
        group.add_developer(user)
      end

      context 'with valid params' do
        it 'reorders issues and returns a successful 200 response', :aggregate_failures do
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

      context 'with issue in different project' do
        let(:other_project) { create(:project, group: group) }
        let(:other_issue) { create(:issue, project: other_project, relative_position: 80) }

        it 'reorders issues and returns a successful 200 response', :aggregate_failures do
          put api("/projects/#{other_project.id}/issues/#{other_issue.iid}/reorder", user), params: { move_after_id: issue2.id, move_before_id: issue3.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(other_issue.reload.relative_position)
                .to be_between(issue2.reload.relative_position, issue3.reload.relative_position)
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
