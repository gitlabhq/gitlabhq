require 'spec_helper'

describe API::Issues do
  set(:user) { create(:user) }
  set(:project) do
    create(:project, :public, creator_id: user.id, namespace: user.namespace)
  end

  let(:user2)       { create(:user) }
  let(:non_member)  { create(:user) }
  set(:guest)       { create(:user) }
  set(:author)      { create(:author) }
  set(:assignee)    { create(:assignee) }
  let(:admin)       { create(:user, :admin) }
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
  set(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end
  let!(:label_link) { create(:label_link, label: label, target: issue) }
  set(:milestone) { create(:milestone, title: '1.0.0', project: project) }
  set(:empty_milestone) do
    create(:milestone, title: '2.0.0', project: project)
  end
  let!(:note) { create(:note_on_issue, author: user, project: project, noteable: issue) }

  let(:no_milestone_title) { URI.escape(Milestone::None.title) }

  before(:all) do
    project.add_reporter(user)
    project.add_guest(guest)
  end

  describe "GET /issues" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/issues")

        expect(response).to have_gitlab_http_status(401)
      end
    end
    context "when authenticated" do
      let(:first_issue) { json_response.first }

      it "returns an array of issues" do
        get api("/issues", user)

        expect_paginated_array_response(size: 2)
        expect(json_response.first['title']).to eq(issue.title)
        expect(json_response.last).to have_key('web_url')
      end

      it 'returns an array of closed issues' do
        get api('/issues', user), state: :closed

        expect_paginated_array_response(size: 1)
        expect(first_issue['id']).to eq(closed_issue.id)
      end

      it 'returns an array of opened issues' do
        get api('/issues', user), state: :opened

        expect_paginated_array_response(size: 1)
        expect(first_issue['id']).to eq(issue.id)
      end

      it 'returns an array of all issues' do
        get api('/issues', user), state: :all

        expect_paginated_array_response(size: 2)
        expect(first_issue['id']).to eq(issue.id)
        expect(json_response.second['id']).to eq(closed_issue.id)
      end

      it 'returns issues assigned to me' do
        issue2 = create(:issue, assignees: [user2], project: project)

        get api('/issues', user2), scope: 'assigned-to-me'

        expect_paginated_array_response(size: 1)
        expect(first_issue['id']).to eq(issue2.id)
      end

      it 'returns issues authored by the given author id' do
        issue2 = create(:issue, author: user2, project: project)

        get api('/issues', user), author_id: user2.id, scope: 'all'

        expect_paginated_array_response(size: 1)
        expect(first_issue['id']).to eq(issue2.id)
      end

      it 'returns issues assigned to the given assignee id' do
        issue2 = create(:issue, assignees: [user2], project: project)

        get api('/issues', user), assignee_id: user2.id, scope: 'all'

        expect_paginated_array_response(size: 1)
        expect(first_issue['id']).to eq(issue2.id)
      end

      it 'returns issues authored by the given author id and assigned to the given assignee id' do
        issue2 = create(:issue, author: user2, assignees: [user2], project: project)

        get api('/issues', user), author_id: user2.id, assignee_id: user2.id, scope: 'all'

        expect_paginated_array_response(size: 1)
        expect(first_issue['id']).to eq(issue2.id)
      end

      it 'returns issues reacted by the authenticated user by the given emoji' do
        issue2 = create(:issue, project: project, author: user, assignees: [user])
        award_emoji = create(:award_emoji, awardable: issue2, user: user2, name: 'star')

        get api('/issues', user2), my_reaction_emoji: award_emoji.name, scope: 'all'

        expect_paginated_array_response(size: 1)
        expect(first_issue['id']).to eq(issue2.id)
      end

      it 'returns issues matching given search string for title' do
        get api("/issues", user), search: issue.title

        expect_paginated_array_response(size: 1)
        expect(json_response.first['id']).to eq(issue.id)
      end

      it 'returns issues matching given search string for description' do
        get api("/issues", user), search: issue.description

        expect_paginated_array_response(size: 1)
        expect(first_issue['id']).to eq(issue.id)
      end

      context 'filtering before a specific date' do
        let!(:issue2) { create(:issue, project: project, author: user, created_at: Date.new(2000, 1, 1), updated_at: Date.new(2000, 1, 1)) }

        it 'returns issues created before a specific date' do
          get api('/issues?created_before=2000-01-02T00:00:00.060Z', user)

          expect(json_response.size).to eq(1)
          expect(first_issue['id']).to eq(issue2.id)
        end

        it 'returns issues updated before a specific date' do
          get api('/issues?updated_before=2000-01-02T00:00:00.060Z', user)

          expect(json_response.size).to eq(1)
          expect(first_issue['id']).to eq(issue2.id)
        end
      end

      context 'filtering after a specific date' do
        let!(:issue2) { create(:issue, project: project, author: user, created_at: 1.week.from_now, updated_at: 1.week.from_now) }

        it 'returns issues created after a specific date' do
          get api("/issues?created_after=#{issue2.created_at}", user)

          expect(json_response.size).to eq(1)
          expect(first_issue['id']).to eq(issue2.id)
        end

        it 'returns issues updated after a specific date' do
          get api("/issues?updated_after=#{issue2.updated_at}", user)

          expect(json_response.size).to eq(1)
          expect(first_issue['id']).to eq(issue2.id)
        end
      end

      it 'returns an array of labeled issues' do
        get api("/issues", user), labels: label.title

        expect_paginated_array_response(size: 1)
        expect(first_issue['labels']).to eq([label.title])
      end

      it 'returns an array of labeled issues when all labels matches' do
        label_b = create(:label, title: 'foo', project: project)
        label_c = create(:label, title: 'bar', project: project)

        create(:label_link, label: label_b, target: issue)
        create(:label_link, label: label_c, target: issue)

        get api("/issues", user), labels: "#{label.title},#{label_b.title},#{label_c.title}"

        expect_paginated_array_response(size: 1)
        expect(json_response.first['labels']).to eq([label_c.title, label_b.title, label.title])
      end

      it 'returns an empty array if no issue matches labels' do
        get api('/issues', user), labels: 'foo,bar'

        expect_paginated_array_response(size: 0)
      end

      it 'returns an array of labeled issues matching given state' do
        get api("/issues", user), labels: label.title, state: :opened

        expect_paginated_array_response(size: 1)
        expect(json_response.first['labels']).to eq([label.title])
        expect(json_response.first['state']).to eq('opened')
      end

      it 'returns unlabeled issues for "No Label" label' do
        get api("/issues", user), labels: 'No Label'

        expect_paginated_array_response(size: 1)
        expect(json_response.first['labels']).to be_empty
      end

      it 'returns an empty array if no issue matches labels and state filters' do
        get api("/issues?labels=#{label.title}&state=closed", user)

        expect_paginated_array_response(size: 0)
      end

      it 'returns an empty array if no issue matches milestone' do
        get api("/issues?milestone=#{empty_milestone.title}", user)

        expect_paginated_array_response(size: 0)
      end

      it 'returns an empty array if milestone does not exist' do
        get api("/issues?milestone=foo", user)

        expect_paginated_array_response(size: 0)
      end

      it 'returns an array of issues in given milestone' do
        get api("/issues?milestone=#{milestone.title}", user)

        expect_paginated_array_response(size: 2)
        expect(json_response.first['id']).to eq(issue.id)
        expect(json_response.second['id']).to eq(closed_issue.id)
      end

      it 'returns an array of issues matching state in milestone' do
        get api("/issues?milestone=#{milestone.title}"\
                '&state=closed', user)

        expect_paginated_array_response(size: 1)
        expect(json_response.first['id']).to eq(closed_issue.id)
      end

      it 'returns an array of issues with no milestone' do
        get api("/issues?milestone=#{no_milestone_title}", author)

        expect_paginated_array_response(size: 1)
        expect(json_response.first['id']).to eq(confidential_issue.id)
      end

      it 'returns an array of issues found by iids' do
        get api('/issues', user), iids: [closed_issue.iid]

        expect_paginated_array_response(size: 1)
        expect(json_response.first['id']).to eq(closed_issue.id)
      end

      it 'returns an empty array if iid does not exist' do
        get api("/issues", user), iids: [99999]

        expect_paginated_array_response(size: 0)
      end

      it 'sorts by created_at descending by default' do
        get api('/issues', user)

        response_dates = json_response.map { |issue| issue['created_at'] }

        expect_paginated_array_response(size: 2)
        expect(response_dates).to eq(response_dates.sort.reverse)
      end

      it 'sorts ascending when requested' do
        get api('/issues?sort=asc', user)

        response_dates = json_response.map { |issue| issue['created_at'] }

        expect_paginated_array_response(size: 2)
        expect(response_dates).to eq(response_dates.sort)
      end

      it 'sorts by updated_at descending when requested' do
        get api('/issues?order_by=updated_at', user)

        response_dates = json_response.map { |issue| issue['updated_at'] }

        expect_paginated_array_response(size: 2)
        expect(response_dates).to eq(response_dates.sort.reverse)
      end

      it 'sorts by updated_at ascending when requested' do
        get api('/issues?order_by=updated_at&sort=asc', user)

        response_dates = json_response.map { |issue| issue['updated_at'] }

        expect_paginated_array_response(size: 2)
        expect(response_dates).to eq(response_dates.sort)
      end

      it 'matches V4 response schema' do
        get api('/issues', user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/issues')
      end
    end
  end

  describe "GET /groups/:id/issues" do
    let!(:group)            { create(:group) }
    let!(:group_project)    { create(:project, :public, creator_id: user.id, namespace: group) }
    let!(:group_closed_issue) do
      create :closed_issue,
             author: user,
             assignees: [user],
             project: group_project,
             state: :closed,
             milestone: group_milestone,
             updated_at: 3.hours.ago
    end
    let!(:group_confidential_issue) do
      create :issue,
             :confidential,
             project: group_project,
             author: author,
             assignees: [assignee],
             updated_at: 2.hours.ago
    end
    let!(:group_issue) do
      create :issue,
             author: user,
             assignees: [user],
             project: group_project,
             milestone: group_milestone,
             updated_at: 1.hour.ago,
             title: issue_title,
             description: issue_description
    end
    let!(:group_label) do
      create(:label, title: 'group_lbl', color: '#FFAABB', project: group_project)
    end
    let!(:group_label_link) { create(:label_link, label: group_label, target: group_issue) }
    let!(:group_milestone) { create(:milestone, title: '3.0.0', project: group_project) }
    let!(:group_empty_milestone) do
      create(:milestone, title: '4.0.0', project: group_project)
    end
    let!(:group_note) { create(:note_on_issue, author: user, project: group_project, noteable: group_issue) }

    before do
      group_project.add_reporter(user)
    end
    let(:base_url) { "/groups/#{group.id}/issues" }

    context 'when group has subgroups', :nested_groups do
      let(:subgroup_1) { create(:group, parent: group) }
      let(:subgroup_2) { create(:group, parent: subgroup_1) }

      let(:subgroup_1_project) { create(:project, namespace: subgroup_1) }
      let(:subgroup_2_project) { create(:project, namespace: subgroup_2) }

      let!(:issue_1) { create(:issue, project: subgroup_1_project) }
      let!(:issue_2) { create(:issue, project: subgroup_2_project) }

      before do
        group.add_developer(user)
      end

      it 'also returns subgroups projects issues' do
        get api(base_url, user)

        issue_ids = json_response.map { |issue| issue['id'] }

        expect_paginated_array_response(size: 5)
        expect(issue_ids).to include(issue_1.id, issue_2.id)
      end
    end

    it 'returns all group issues (including opened and closed)' do
      get api(base_url, admin)

      expect_paginated_array_response(size: 3)
    end

    it 'returns group issues without confidential issues for non project members' do
      get api("#{base_url}?state=opened", non_member)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['title']).to eq(group_issue.title)
    end

    it 'returns group confidential issues for author' do
      get api("#{base_url}?state=opened", author)

      expect_paginated_array_response(size: 2)
    end

    it 'returns group confidential issues for assignee' do
      get api("#{base_url}?state=opened", assignee)

      expect_paginated_array_response(size: 2)
    end

    it 'returns group issues with confidential issues for project members' do
      get api("#{base_url}?state=opened", user)

      expect_paginated_array_response(size: 2)
    end

    it 'returns group confidential issues for admin' do
      get api("#{base_url}?state=opened", admin)

      expect_paginated_array_response(size: 2)
    end

    it 'returns an array of labeled group issues' do
      get api("#{base_url}?labels=#{group_label.title}", user)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['labels']).to eq([group_label.title])
    end

    it 'returns an array of labeled group issues where all labels match' do
      get api("#{base_url}?labels=#{group_label.title},foo,bar", user)

      expect_paginated_array_response(size: 0)
    end

    it 'returns issues matching given search string for title' do
      get api("#{base_url}?search=#{group_issue.title}", user)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(group_issue.id)
    end

    it 'returns issues matching given search string for description' do
      get api("#{base_url}?search=#{group_issue.description}", user)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(group_issue.id)
    end

    it 'returns an array of labeled issues when all labels matches' do
      label_b = create(:label, title: 'foo', project: group_project)
      label_c = create(:label, title: 'bar', project: group_project)

      create(:label_link, label: label_b, target: group_issue)
      create(:label_link, label: label_c, target: group_issue)

      get api("#{base_url}", user), labels: "#{group_label.title},#{label_b.title},#{label_c.title}"

      expect_paginated_array_response(size: 1)
      expect(json_response.first['labels']).to eq([label_c.title, label_b.title, group_label.title])
    end

    it 'returns an array of issues found by iids' do
      get api(base_url, user), iids: [group_issue.iid]

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(group_issue.id)
    end

    it 'returns an empty array if iid does not exist' do
      get api(base_url, user), iids: [99999]

      expect_paginated_array_response(size: 0)
    end

    it 'returns an empty array if no group issue matches labels' do
      get api("#{base_url}?labels=foo,bar", user)

      expect_paginated_array_response(size: 0)
    end

    it 'returns an empty array if no issue matches milestone' do
      get api("#{base_url}?milestone=#{group_empty_milestone.title}", user)

      expect_paginated_array_response(size: 0)
    end

    it 'returns an empty array if milestone does not exist' do
      get api("#{base_url}?milestone=foo", user)

      expect_paginated_array_response(size: 0)
    end

    it 'returns an array of issues in given milestone' do
      get api("#{base_url}?state=opened&milestone=#{group_milestone.title}", user)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(group_issue.id)
    end

    it 'returns an array of issues matching state in milestone' do
      get api("#{base_url}?milestone=#{group_milestone.title}"\
              '&state=closed', user)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(group_closed_issue.id)
    end

    it 'returns an array of issues with no milestone' do
      get api("#{base_url}?milestone=#{no_milestone_title}", user)

      expect(response).to have_gitlab_http_status(200)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(group_confidential_issue.id)
    end

    it 'sorts by created_at descending by default' do
      get api(base_url, user)

      response_dates = json_response.map { |issue| issue['created_at'] }

      expect_paginated_array_response(size: 3)
      expect(response_dates).to eq(response_dates.sort.reverse)
    end

    it 'sorts ascending when requested' do
      get api("#{base_url}?sort=asc", user)

      response_dates = json_response.map { |issue| issue['created_at'] }

      expect_paginated_array_response(size: 3)
      expect(response_dates).to eq(response_dates.sort)
    end

    it 'sorts by updated_at descending when requested' do
      get api("#{base_url}?order_by=updated_at", user)

      response_dates = json_response.map { |issue| issue['updated_at'] }

      expect_paginated_array_response(size: 3)
      expect(response_dates).to eq(response_dates.sort.reverse)
    end

    it 'sorts by updated_at ascending when requested' do
      get api("#{base_url}?order_by=updated_at&sort=asc", user)

      response_dates = json_response.map { |issue| issue['updated_at'] }

      expect_paginated_array_response(size: 3)
      expect(response_dates).to eq(response_dates.sort)
    end
  end

  describe "GET /projects/:id/issues" do
    let(:base_url) { "/projects/#{project.id}" }

    it 'avoids N+1 queries' do
      control_count = ActiveRecord::QueryRecorder.new do
        get api("/projects/#{project.id}/issues", user)
      end.count

      create(:issue, author: user, project: project)

      expect do
        get api("/projects/#{project.id}/issues", user)
      end.not_to exceed_query_limit(control_count)
    end

    it 'returns 404 when project does not exist' do
      get api('/projects/1000/issues', non_member)

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 on private projects for other users" do
      private_project = create(:project, :private)
      create(:issue, project: private_project)

      get api("/projects/#{private_project.id}/issues", non_member)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns no issues when user has access to project but not issues' do
      restricted_project = create(:project, :public, :issues_private)
      create(:issue, project: restricted_project)

      get api("/projects/#{restricted_project.id}/issues", non_member)

      expect_paginated_array_response(size: 0)
    end

    it 'returns project issues without confidential issues for non project members' do
      get api("#{base_url}/issues", non_member)

      expect_paginated_array_response(size: 2)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns project issues without confidential issues for project members with guest role' do
      get api("#{base_url}/issues", guest)

      expect_paginated_array_response(size: 2)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns project confidential issues for author' do
      get api("#{base_url}/issues", author)

      expect_paginated_array_response(size: 3)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns project confidential issues for assignee' do
      get api("#{base_url}/issues", assignee)

      expect_paginated_array_response(size: 3)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns project issues with confidential issues for project members' do
      get api("#{base_url}/issues", user)

      expect_paginated_array_response(size: 3)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns project confidential issues for admin' do
      get api("#{base_url}/issues", admin)

      expect_paginated_array_response(size: 3)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns an array of labeled project issues' do
      get api("#{base_url}/issues?labels=#{label.title}", user)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['labels']).to eq([label.title])
    end

    it 'returns an array of labeled issues when all labels matches' do
      label_b = create(:label, title: 'foo', project: project)
      label_c = create(:label, title: 'bar', project: project)

      create(:label_link, label: label_b, target: issue)
      create(:label_link, label: label_c, target: issue)

      get api("#{base_url}/issues", user), labels: "#{label.title},#{label_b.title},#{label_c.title}"

      expect_paginated_array_response(size: 1)
      expect(json_response.first['labels']).to eq([label_c.title, label_b.title, label.title])
    end

    it 'returns issues matching given search string for title' do
      get api("#{base_url}/issues?search=#{issue.title}", user)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(issue.id)
    end

    it 'returns issues matching given search string for description' do
      get api("#{base_url}/issues?search=#{issue.description}", user)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(issue.id)
    end

    it 'returns an array of issues found by iids' do
      get api("#{base_url}/issues", user), iids: [issue.iid]

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(issue.id)
    end

    it 'returns an empty array if iid does not exist' do
      get api("#{base_url}/issues", user), iids: [99999]

      expect_paginated_array_response(size: 0)
    end

    it 'returns an empty array if not all labels matches' do
      get api("#{base_url}/issues?labels=#{label.title},foo", user)

      expect_paginated_array_response(size: 0)
    end

    it 'returns an empty array if no project issue matches labels' do
      get api("#{base_url}/issues?labels=foo,bar", user)

      expect_paginated_array_response(size: 0)
    end

    it 'returns an empty array if no issue matches milestone' do
      get api("#{base_url}/issues?milestone=#{empty_milestone.title}", user)

      expect_paginated_array_response(size: 0)
    end

    it 'returns an empty array if milestone does not exist' do
      get api("#{base_url}/issues?milestone=foo", user)

      expect_paginated_array_response(size: 0)
    end

    it 'returns an array of issues in given milestone' do
      get api("#{base_url}/issues?milestone=#{milestone.title}", user)

      expect_paginated_array_response(size: 2)
      expect(json_response.first['id']).to eq(issue.id)
      expect(json_response.second['id']).to eq(closed_issue.id)
    end

    it 'returns an array of issues matching state in milestone' do
      get api("#{base_url}/issues?milestone=#{milestone.title}&state=closed", user)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(closed_issue.id)
    end

    it 'returns an array of issues with no milestone' do
      get api("#{base_url}/issues?milestone=#{no_milestone_title}", user)

      expect_paginated_array_response(size: 1)
      expect(json_response.first['id']).to eq(confidential_issue.id)
    end

    it 'sorts by created_at descending by default' do
      get api("#{base_url}/issues", user)

      response_dates = json_response.map { |issue| issue['created_at'] }

      expect_paginated_array_response(size: 3)
      expect(response_dates).to eq(response_dates.sort.reverse)
    end

    it 'sorts ascending when requested' do
      get api("#{base_url}/issues?sort=asc", user)

      response_dates = json_response.map { |issue| issue['created_at'] }

      expect_paginated_array_response(size: 3)
      expect(response_dates).to eq(response_dates.sort)
    end

    it 'sorts by updated_at descending when requested' do
      get api("#{base_url}/issues?order_by=updated_at", user)

      response_dates = json_response.map { |issue| issue['updated_at'] }

      expect_paginated_array_response(size: 3)
      expect(response_dates).to eq(response_dates.sort.reverse)
    end

    it 'sorts by updated_at ascending when requested' do
      get api("#{base_url}/issues?order_by=updated_at&sort=asc", user)

      response_dates = json_response.map { |issue| issue['updated_at'] }

      expect_paginated_array_response(size: 3)
      expect(response_dates).to eq(response_dates.sort)
    end
  end

  describe "GET /projects/:id/issues/:issue_iid" do
    it 'exposes known attributes' do
      get api("/projects/#{project.id}/issues/#{issue.iid}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['id']).to eq(issue.id)
      expect(json_response['iid']).to eq(issue.iid)
      expect(json_response['project_id']).to eq(issue.project.id)
      expect(json_response['title']).to eq(issue.title)
      expect(json_response['description']).to eq(issue.description)
      expect(json_response['state']).to eq(issue.state)
      expect(json_response['closed_at']).to be_falsy
      expect(json_response['created_at']).to be_present
      expect(json_response['updated_at']).to be_present
      expect(json_response['labels']).to eq(issue.label_names)
      expect(json_response['milestone']).to be_a Hash
      expect(json_response['assignees']).to be_a Array
      expect(json_response['assignee']).to be_a Hash
      expect(json_response['author']).to be_a Hash
      expect(json_response['confidential']).to be_falsy
    end

    it "exposes the 'closed_at' attribute" do
      get api("/projects/#{project.id}/issues/#{closed_issue.iid}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['closed_at']).to be_present
    end

    context 'links exposure' do
      it 'exposes related resources full URIs' do
        get api("/projects/#{project.id}/issues/#{issue.iid}", user)

        links = json_response['_links']

        expect(links['self']).to end_with("/api/v4/projects/#{project.id}/issues/#{issue.iid}")
        expect(links['notes']).to end_with("/api/v4/projects/#{project.id}/issues/#{issue.iid}/notes")
        expect(links['award_emoji']).to end_with("/api/v4/projects/#{project.id}/issues/#{issue.iid}/award_emoji")
        expect(links['project']).to end_with("/api/v4/projects/#{project.id}")
      end
    end

    it "returns a project issue by internal id" do
      get api("/projects/#{project.id}/issues/#{issue.iid}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq(issue.title)
      expect(json_response['iid']).to eq(issue.iid)
    end

    it "returns 404 if issue id not found" do
      get api("/projects/#{project.id}/issues/54321", user)
      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 if the issue ID is used" do
      get api("/projects/#{project.id}/issues/#{issue.id}", user)

      expect(response).to have_gitlab_http_status(404)
    end

    context 'confidential issues' do
      it "returns 404 for non project members" do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", non_member)

        expect(response).to have_gitlab_http_status(404)
      end

      it "returns 404 for project members with guest role" do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", guest)

        expect(response).to have_gitlab_http_status(404)
      end

      it "returns confidential issue for project members" do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end

      it "returns confidential issue for author" do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", author)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end

      it "returns confidential issue for assignee" do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", assignee)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end

      it "returns confidential issue for admin" do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end
    end
  end

  describe "POST /projects/:id/issues" do
    context 'support for deprecated assignee_id' do
      it 'creates a new project issue' do
        post api("/projects/#{project.id}/issues", user),
          title: 'new issue', assignee_id: user2.id

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('new issue')
        expect(json_response['assignee']['name']).to eq(user2.name)
        expect(json_response['assignees'].first['name']).to eq(user2.name)
      end

      it 'creates a new project issue when assignee_id is empty' do
        post api("/projects/#{project.id}/issues", user),
          title: 'new issue', assignee_id: ''

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('new issue')
        expect(json_response['assignee']).to be_nil
      end
    end

    context 'single assignee restrictions' do
      it 'creates a new project issue with no more than one assignee' do
        post api("/projects/#{project.id}/issues", user),
          title: 'new issue', assignee_ids: [user2.id, guest.id]

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('new issue')
        expect(json_response['assignees'].count).to eq(1)
      end
    end

    context 'user does not have permissions to create issue' do
      let(:not_member)  { create(:user) }

      before do
        project.project_feature.update(issues_access_level: ProjectFeature::PRIVATE)
      end

      it 'renders 403' do
        post api("/projects/#{project.id}/issues", not_member), title: 'new issue'

        expect(response).to have_gitlab_http_status(403)
      end
    end

    it 'creates a new project issue' do
      post api("/projects/#{project.id}/issues", user),
        title: 'new issue', labels: 'label, label2', weight: 3,
        assignee_ids: [user2.id]

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['description']).to be_nil
      expect(json_response['labels']).to eq(%w(label label2))
      expect(json_response['confidential']).to be_falsy
      expect(json_response['assignee']['name']).to eq(user2.name)
      expect(json_response['assignees'].first['name']).to eq(user2.name)
    end

    it 'creates a new confidential project issue' do
      post api("/projects/#{project.id}/issues", user),
        title: 'new issue', confidential: true

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['confidential']).to be_truthy
    end

    it 'creates a new confidential project issue with a different param' do
      post api("/projects/#{project.id}/issues", user),
        title: 'new issue', confidential: 'y'

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['confidential']).to be_truthy
    end

    it 'creates a public issue when confidential param is false' do
      post api("/projects/#{project.id}/issues", user),
        title: 'new issue', confidential: false

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['confidential']).to be_falsy
    end

    it 'creates a public issue when confidential param is invalid' do
      post api("/projects/#{project.id}/issues", user),
        title: 'new issue', confidential: 'foo'

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('confidential is invalid')
    end

    it "returns a 400 bad request if title not given" do
      post api("/projects/#{project.id}/issues", user), labels: 'label, label2'
      expect(response).to have_gitlab_http_status(400)
    end

    it 'allows special label names' do
      post api("/projects/#{project.id}/issues", user),
           title: 'new issue',
           labels: 'label, label?, label&foo, ?, &'
      expect(response.status).to eq(201)
      expect(json_response['labels']).to include 'label'
      expect(json_response['labels']).to include 'label?'
      expect(json_response['labels']).to include 'label&foo'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    it 'returns 400 if title is too long' do
      post api("/projects/#{project.id}/issues", user),
           title: 'g' * 256
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['title']).to eq([
        'is too long (maximum is 255 characters)'
      ])
    end

    context 'resolving discussions' do
      let(:discussion) { create(:diff_note_on_merge_request).to_discussion }
      let(:merge_request) { discussion.noteable }
      let(:project) { merge_request.source_project }

      before do
        project.add_master(user)
      end

      context 'resolving all discussions in a merge request' do
        before do
          post api("/projects/#{project.id}/issues", user),
               title: 'New Issue',
               merge_request_to_resolve_discussions_of: merge_request.iid
        end

        it_behaves_like 'creating an issue resolving discussions through the API'
      end

      context 'resolving a single discussion' do
        before do
          post api("/projects/#{project.id}/issues", user),
               title: 'New Issue',
               merge_request_to_resolve_discussions_of: merge_request.iid,
               discussion_to_resolve: discussion.id
        end

        it_behaves_like 'creating an issue resolving discussions through the API'
      end
    end

    context 'with due date' do
      it 'creates a new project issue' do
        due_date = 2.weeks.from_now.strftime('%Y-%m-%d')

        post api("/projects/#{project.id}/issues", user),
          title: 'new issue', due_date: due_date

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('new issue')
        expect(json_response['description']).to be_nil
        expect(json_response['due_date']).to eq(due_date)
      end
    end

    context 'when an admin or owner makes the request' do
      it 'accepts the creation date to be set' do
        creation_time = 2.weeks.ago
        post api("/projects/#{project.id}/issues", user),
          title: 'new issue', labels: 'label, label2', created_at: creation_time

        expect(response).to have_gitlab_http_status(201)
        expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
      end
    end

    context 'the user can only read the issue' do
      it 'cannot create new labels' do
        expect do
          post api("/projects/#{project.id}/issues", non_member), title: 'new issue', labels: 'label, label2'
        end.not_to change { project.labels.count }
      end
    end
  end

  describe 'POST /projects/:id/issues with spam filtering' do
    before do
      allow_any_instance_of(SpamService).to receive(:check_for_spam?).and_return(true)
      allow_any_instance_of(AkismetService).to receive_messages(spam?: true)
    end

    let(:params) do
      {
        title: 'new issue',
        description: 'content here',
        labels: 'label, label2'
      }
    end

    it "does not create a new project issue" do
      expect { post api("/projects/#{project.id}/issues", user), params }.not_to change(Issue, :count)
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq({ "error" => "Spam detected" })

      spam_logs = SpamLog.all
      expect(spam_logs.count).to eq(1)
      expect(spam_logs[0].title).to eq('new issue')
      expect(spam_logs[0].description).to eq('content here')
      expect(spam_logs[0].user).to eq(user)
      expect(spam_logs[0].noteable_type).to eq('Issue')
    end
  end

  describe "PUT /projects/:id/issues/:issue_iid to update only title" do
    it "updates a project issue" do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        title: 'updated title'
      expect(response).to have_gitlab_http_status(200)

      expect(json_response['title']).to eq('updated title')
    end

    it "returns 404 error if issue iid not found" do
      put api("/projects/#{project.id}/issues/44444", user),
        title: 'updated title'
      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 error if issue id is used instead of the iid" do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          title: 'updated title'
      expect(response).to have_gitlab_http_status(404)
    end

    it 'allows special label names' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          title: 'updated title',
          labels: 'label, label?, label&foo, ?, &'

      expect(response.status).to eq(200)
      expect(json_response['labels']).to include 'label'
      expect(json_response['labels']).to include 'label?'
      expect(json_response['labels']).to include 'label&foo'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    context 'confidential issues' do
      it "returns 403 for non project members" do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", non_member),
          title: 'updated title'
        expect(response).to have_gitlab_http_status(403)
      end

      it "returns 403 for project members with guest role" do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", guest),
          title: 'updated title'
        expect(response).to have_gitlab_http_status(403)
      end

      it "updates a confidential issue for project members" do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", user),
          title: 'updated title'
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq('updated title')
      end

      it "updates a confidential issue for author" do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", author),
          title: 'updated title'
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq('updated title')
      end

      it "updates a confidential issue for admin" do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", admin),
          title: 'updated title'
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq('updated title')
      end

      it 'sets an issue to confidential' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          confidential: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['confidential']).to be_truthy
      end

      it 'makes a confidential issue public' do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", user),
          confidential: false

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['confidential']).to be_falsy
      end

      it 'does not update a confidential issue with wrong confidential flag' do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", user),
          confidential: 'foo'

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('confidential is invalid')
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid with spam filtering' do
    let(:params) do
      {
        title: 'updated title',
        description: 'content here',
        labels: 'label, label2'
      }
    end

    it "does not create a new project issue" do
      allow_any_instance_of(SpamService).to receive_messages(check_for_spam?: true)
      allow_any_instance_of(AkismetService).to receive_messages(spam?: true)

      put api("/projects/#{project.id}/issues/#{issue.iid}", user), params

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq({ "error" => "Spam detected" })

      spam_logs = SpamLog.all
      expect(spam_logs.count).to eq(1)
      expect(spam_logs[0].title).to eq('updated title')
      expect(spam_logs[0].description).to eq('content here')
      expect(spam_logs[0].user).to eq(user)
      expect(spam_logs[0].noteable_type).to eq('Issue')
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update assignee' do
    context 'support for deprecated assignee_id' do
      it 'removes assignee' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          assignee_id: 0

        expect(response).to have_gitlab_http_status(200)

        expect(json_response['assignee']).to be_nil
      end

      it 'updates an issue with new assignee' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          assignee_id: user2.id

        expect(response).to have_gitlab_http_status(200)

        expect(json_response['assignee']['name']).to eq(user2.name)
      end
    end

    it 'removes assignee' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        assignee_ids: [0]

      expect(response).to have_gitlab_http_status(200)

      expect(json_response['assignees']).to be_empty
    end

    it 'updates an issue with new assignee' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        assignee_ids: [user2.id]

      expect(response).to have_gitlab_http_status(200)

      expect(json_response['assignees'].first['name']).to eq(user2.name)
    end

    context 'single assignee restrictions' do
      it 'updates an issue with several assignees but only one has been applied' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          assignee_ids: [user2.id, guest.id]

        expect(response).to have_gitlab_http_status(200)

        expect(json_response['assignees'].size).to eq(1)
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update labels' do
    let!(:label) { create(:label, title: 'dummy', project: project) }
    let!(:label_link) { create(:label_link, label: label, target: issue) }

    it 'does not update labels if not present' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          title: 'updated title'
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['labels']).to eq([label.title])
    end

    it 'removes all labels' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user), labels: ''

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['labels']).to eq([])
    end

    it 'updates labels' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          labels: 'foo,bar'
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['labels']).to include 'foo'
      expect(json_response['labels']).to include 'bar'
    end

    it 'allows special label names' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          labels: 'label:foo, label-bar,label_bar,label/bar,label?bar,label&bar,?,&'
      expect(response.status).to eq(200)
      expect(json_response['labels']).to include 'label:foo'
      expect(json_response['labels']).to include 'label-bar'
      expect(json_response['labels']).to include 'label_bar'
      expect(json_response['labels']).to include 'label/bar'
      expect(json_response['labels']).to include 'label?bar'
      expect(json_response['labels']).to include 'label&bar'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    it 'returns 400 if title is too long' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          title: 'g' * 256
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['title']).to eq([
        'is too long (maximum is 255 characters)'
      ])
    end
  end

  describe "PUT /projects/:id/issues/:issue_iid to update state and label" do
    it "updates a project issue" do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        labels: 'label2', state_event: "close"
      expect(response).to have_gitlab_http_status(200)

      expect(json_response['labels']).to include 'label2'
      expect(json_response['state']).to eq "closed"
    end

    it 'reopens a project isssue' do
      put api("/projects/#{project.id}/issues/#{closed_issue.iid}", user), state_event: 'reopen'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['state']).to eq 'opened'
    end

    context 'when an admin or owner makes the request' do
      it 'accepts the update date to be set' do
        update_time = 2.weeks.ago
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          labels: 'label3', state_event: 'close', updated_at: update_time

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['labels']).to include 'label3'
        expect(Time.parse(json_response['updated_at'])).to be_like_time(update_time)
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update due date' do
    it 'creates a new project issue' do
      due_date = 2.weeks.from_now.strftime('%Y-%m-%d')

      put api("/projects/#{project.id}/issues/#{issue.iid}", user), due_date: due_date

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['due_date']).to eq(due_date)
    end
  end

  describe "DELETE /projects/:id/issues/:issue_iid" do
    it "rejects a non member from deleting an issue" do
      delete api("/projects/#{project.id}/issues/#{issue.iid}", non_member)
      expect(response).to have_gitlab_http_status(403)
    end

    it "rejects a developer from deleting an issue" do
      delete api("/projects/#{project.id}/issues/#{issue.iid}", author)
      expect(response).to have_gitlab_http_status(403)
    end

    context "when the user is project owner" do
      let(:owner)     { create(:user) }
      let(:project)   { create(:project, namespace: owner.namespace) }

      it "deletes the issue if an admin requests it" do
        delete api("/projects/#{project.id}/issues/#{issue.iid}", owner)

        expect(response).to have_gitlab_http_status(204)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/issues/#{issue.iid}", owner) }
      end
    end

    context 'when issue does not exist' do
      it 'returns 404 when trying to move an issue' do
        delete api("/projects/#{project.id}/issues/123", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    it 'returns 404 when using the issue ID instead of IID' do
      delete api("/projects/#{project.id}/issues/#{issue.id}", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe '/projects/:id/issues/:issue_iid/move' do
    let!(:target_project) { create(:project, creator_id: user.id, namespace: user.namespace ) }
    let!(:target_project2) { create(:project, creator_id: non_member.id, namespace: non_member.namespace ) }

    it 'moves an issue' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/move", user),
               to_project_id: target_project.id

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['project_id']).to eq(target_project.id)
    end

    context 'when source and target projects are the same' do
      it 'returns 400 when trying to move an issue' do
        post api("/projects/#{project.id}/issues/#{issue.iid}/move", user),
                 to_project_id: project.id

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']).to eq('Cannot move issue to project it originates from!')
      end
    end

    context 'when the user does not have the permission to move issues' do
      it 'returns 400 when trying to move an issue' do
        post api("/projects/#{project.id}/issues/#{issue.iid}/move", user),
                 to_project_id: target_project2.id

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']).to eq('Cannot move issue due to insufficient permissions!')
      end
    end

    it 'moves the issue to another namespace if I am admin' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/move", admin),
               to_project_id: target_project2.id

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['project_id']).to eq(target_project2.id)
    end

    context 'when using the issue ID instead of iid' do
      it 'returns 404 when trying to move an issue' do
        post api("/projects/#{project.id}/issues/#{issue.id}/move", user),
             to_project_id: target_project.id

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Issue Not Found')
      end
    end

    context 'when issue does not exist' do
      it 'returns 404 when trying to move an issue' do
        post api("/projects/#{project.id}/issues/123/move", user),
                 to_project_id: target_project.id

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Issue Not Found')
      end
    end

    context 'when source project does not exist' do
      it 'returns 404 when trying to move an issue' do
        post api("/projects/0/issues/#{issue.iid}/move", user),
                 to_project_id: target_project.id

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end
    end

    context 'when target project does not exist' do
      it 'returns 404 when trying to move an issue' do
        post api("/projects/#{project.id}/issues/#{issue.iid}/move", user),
                 to_project_id: 0

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'POST :id/issues/:issue_iid/subscribe' do
    it 'subscribes to an issue' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/subscribe", user2)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['subscribed']).to eq(true)
    end

    it 'returns 304 if already subscribed' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/subscribe", user)

      expect(response).to have_gitlab_http_status(304)
    end

    it 'returns 404 if the issue is not found' do
      post api("/projects/#{project.id}/issues/123/subscribe", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 if the issue ID is used instead of the iid' do
      post api("/projects/#{project.id}/issues/#{issue.id}/subscribe", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 if the issue is confidential' do
      post api("/projects/#{project.id}/issues/#{confidential_issue.iid}/subscribe", non_member)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'POST :id/issues/:issue_id/unsubscribe' do
    it 'unsubscribes from an issue' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/unsubscribe", user)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['subscribed']).to eq(false)
    end

    it 'returns 304 if not subscribed' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/unsubscribe", user2)

      expect(response).to have_gitlab_http_status(304)
    end

    it 'returns 404 if the issue is not found' do
      post api("/projects/#{project.id}/issues/123/unsubscribe", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 if using the issue ID instead of iid' do
      post api("/projects/#{project.id}/issues/#{issue.id}/unsubscribe", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 if the issue is confidential' do
      post api("/projects/#{project.id}/issues/#{confidential_issue.iid}/unsubscribe", non_member)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'time tracking endpoints' do
    let(:issuable) { issue }

    include_examples 'time tracking endpoints', 'issue'
  end

  describe 'GET :id/issues/:issue_iid/closed_by' do
    let(:merge_request) do
      create(:merge_request,
             :simple,
             author: user,
             source_project: project,
             target_project: project,
             description: "closes #{issue.to_reference}")
    end

    before do
      create(:merge_requests_closing_issues, issue: issue, merge_request: merge_request)
    end

    it 'returns merge requests that will close issue on merge' do
      get api("/projects/#{project.id}/issues/#{issue.iid}/closed_by", user)

      expect_paginated_array_response(size: 1)
    end

    context 'when no merge requests will close issue' do
      it 'returns empty array' do
        get api("/projects/#{project.id}/issues/#{closed_issue.iid}/closed_by", user)

        expect_paginated_array_response(size: 0)
      end
    end

    it "returns 404 when issue doesn't exists" do
      get api("/projects/#{project.id}/issues/9999/closed_by", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "GET /projects/:id/issues/:issue_iid/user_agent_detail" do
    let!(:user_agent_detail) { create(:user_agent_detail, subject: issue) }

    it 'exposes known attributes' do
      get api("/projects/#{project.id}/issues/#{issue.iid}/user_agent_detail", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['user_agent']).to eq(user_agent_detail.user_agent)
      expect(json_response['ip_address']).to eq(user_agent_detail.ip_address)
      expect(json_response['akismet_submitted']).to eq(user_agent_detail.submitted)
    end

    it "returns unautorized for non-admin users" do
      get api("/projects/#{project.id}/issues/#{issue.iid}/user_agent_detail", user)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  def expect_paginated_array_response(size: nil)
    expect(response).to have_gitlab_http_status(200)
    expect(response).to include_pagination_headers
    expect(json_response).to be_an Array
    expect(json_response.length).to eq(size) if size
  end

  describe 'GET projects/:id/issues/:issue_iid/participants' do
    it_behaves_like 'issuable participants endpoint' do
      let(:entity) { issue }
    end

    it 'returns 404 if the issue is confidential' do
      post api("/projects/#{project.id}/issues/#{confidential_issue.iid}/participants", non_member)

      expect(response).to have_gitlab_http_status(404)
    end
  end
end
