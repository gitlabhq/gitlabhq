# frozen_string_literal: true

RSpec.shared_examples 'group and project milestones' do |route_definition|
  let(:resource_route) { "#{route}/#{milestone.id}" }
  let(:label_1) { create(:label, title: 'label_1', project: project, priority: 1) }
  let(:label_2) { create(:label, title: 'label_2', project: project, priority: 2) }
  let(:label_3) { create(:label, title: 'label_3', project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:another_merge_request) { create(:merge_request, :simple, source_project: project) }

  describe "GET #{route_definition}" do
    it 'returns milestones list' do
      get api(route, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(milestone.title)
    end

    it 'returns a 401 error if user not authenticated' do
      get api(route)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns an array of active milestones' do
      get api("#{route}/?state=active", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(milestone.id)
    end

    it 'returns an array of closed milestones' do
      get api("#{route}/?state=closed", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(closed_milestone.id)
    end

    it 'returns an array of milestones specified by iids' do
      other_milestone = create(:milestone, project: try(:project), group: try(:group))

      get api(route, user), params: { iids: [closed_milestone.iid, other_milestone.iid] }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.pluck('id')).to match_array([closed_milestone.id, other_milestone.id])
    end

    it 'does not return any milestone if none found' do
      get api(route, user), params: { iids: [non_existing_record_iid] }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns a milestone by iids array' do
      get api("#{route}?iids=#{closed_milestone.iid}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response.size).to eq(1)
      expect(json_response.size).to eq(1)
      expect(json_response.first['title']).to eq closed_milestone.title
      expect(json_response.first['id']).to eq closed_milestone.id
    end

    it 'returns a milestone by title' do
      get api(route, user), params: { title: 'version2' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(1)
      expect(json_response.first['title']).to eq milestone.title
      expect(json_response.first['id']).to eq milestone.id
    end

    it 'returns a milestone by searching for title' do
      get api(route, user), params: { search: 'version2' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response.size).to eq(1)
      expect(json_response.first['title']).to eq milestone.title
      expect(json_response.first['id']).to eq milestone.id
    end

    it 'returns a milestones by searching for description' do
      get api(route, user), params: { search: 'open' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response.size).to eq(1)
      expect(json_response.first['title']).to eq milestone.title
      expect(json_response.first['id']).to eq milestone.id
    end
  end

  describe "GET #{route_definition}/:milestone_id" do
    it 'returns a milestone by id' do
      get api(resource_route, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['title']).to eq(milestone.title)
      expect(json_response['iid']).to eq(milestone.iid)
    end

    it 'returns 401 error if user not authenticated' do
      get api(resource_route)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns a 404 error if milestone id not found' do
      get api("#{route}/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "POST #{route_definition}" do
    it 'creates a new milestone' do
      post api(route, user), params: { title: 'new milestone' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['title']).to eq('new milestone')
      expect(json_response['description']).to be_nil
    end

    it 'creates a new milestone with description and dates' do
      post api(route, user), params: { title: 'new milestone', description: 'release', due_date: '2013-03-02', start_date: '2013-02-02' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['description']).to eq('release')
      expect(json_response['due_date']).to eq('2013-03-02')
      expect(json_response['start_date']).to eq('2013-02-02')
    end

    it 'returns a 400 error if title is missing' do
      post api(route, user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns a 400 error if params are invalid (duplicate title)' do
      post api(route, user), params: { title: milestone.title, description: 'release', due_date: '2013-03-02' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'creates a new milestone with reserved html characters' do
      post api(route, user), params: { title: 'foo & bar 1.1 -> 2.2' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['title']).to eq('foo & bar 1.1 -> 2.2')
      expect(json_response['description']).to be_nil
    end
  end

  describe "PUT #{route_definition}/:milestone_id" do
    it 'updates a milestone' do
      put api(resource_route, user), params: { title: 'updated title' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['title']).to eq('updated title')
    end

    it 'removes a due date if nil is passed' do
      milestone.update!(due_date: "2016-08-05")

      put api(resource_route, user), params: { due_date: nil }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['due_date']).to be_nil
    end

    it 'returns a 404 error if milestone id not found' do
      put api("#{route}/#{non_existing_record_id}", user), params: { title: 'updated title' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'closes milestone' do
      put api(resource_route, user), params: { state_event: 'close' }
      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['state']).to eq('closed')
    end

    it 'updates milestone with only start date' do
      put api(resource_route, user), params: { start_date: Date.tomorrow }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe "DELETE #{route_definition}/:milestone_id" do
    it "rejects a member with guest access from deleting a milestone" do
      guest = create(:user)
      milestone.resource_parent.add_guest(guest)

      delete api(resource_route, guest)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'deletes the milestone when the user has reporter access to the project' do
      delete api(resource_route, user)

      expect(project.milestones.find_by_id(milestone.id)).to be_nil
      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  describe "GET #{route_definition}/:milestone_id/issues" do
    let(:issues_route) { "#{route}/#{milestone.id}/issues" }

    before do
      milestone.issues << create(:issue, project: project)
    end

    it 'returns issues for a particular milestone' do
      get api(issues_route, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['milestone']['title']).to eq(milestone.title)
    end

    it 'returns issues sorted by label priority' do
      issue_1 = create(:labeled_issue, project: project, milestone: milestone, labels: [label_3])
      issue_2 = create(:labeled_issue, project: project, milestone: milestone, labels: [label_1])
      issue_3 = create(:labeled_issue, project: project, milestone: milestone, labels: [label_2])

      get api(issues_route, user)

      expect(json_response.first['id']).to eq(issue_2.id)
      expect(json_response.second['id']).to eq(issue_3.id)
      expect(json_response.third['id']).to eq(issue_1.id)
    end

    it 'matches V4 response schema for a list of issues' do
      get api(issues_route, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/issues')
    end

    it 'returns a 401 error if user not authenticated' do
      get api(issues_route)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    describe 'confidential issues' do
      let!(:public_project) { create(:project, :public, organization: organization) }
      let!(:context_group) { try(:group) }
      let!(:milestone) do
        context_group ? create(:milestone, group: context_group) : create(:milestone, project: public_project)
      end

      let!(:issue) { create(:issue, project: public_project) }
      let!(:confidential_issue) { create(:issue, confidential: true, project: public_project) }
      let!(:issues_route) do
        if context_group
          "#{route}/#{milestone.id}/issues"
        else
          "/projects/#{public_project.id}/milestones/#{milestone.id}/issues"
        end
      end

      before do
        # Add public project to the group in context
        setup_for_group if context_group

        public_project.add_developer(user)
        milestone.issues << issue << confidential_issue
      end

      it 'returns confidential issues to team members' do
        get api(issues_route, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        # 2 for projects, 3 for group(which has another project with an issue)
        expect(json_response.size).to be_between(2, 3)
        expect(json_response.pluck('id')).to include(issue.id, confidential_issue.id)
      end

      it 'does not return confidential issues to team members with guest role' do
        member = create(:user)
        public_project.add_guest(member)

        get api(issues_route, member)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
        expect(json_response.pluck('id')).to include(issue.id)
      end

      it 'does not return confidential issues to regular users' do
        get api(issues_route, create(:user))

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
        expect(json_response.pluck('id')).to include(issue.id)
      end

      it 'returns issues ordered by label priority' do
        issue.labels << label_2
        confidential_issue.labels << label_1

        get api(issues_route, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        # 2 for projects, 3 for group(which has another project with an issue)
        expect(json_response.size).to be_between(2, 3)
        expect(json_response.first['id']).to eq(confidential_issue.id)
        expect(json_response.second['id']).to eq(issue.id)
      end
    end
  end

  describe "GET #{route_definition}/:milestone_id/merge_requests" do
    let(:merge_requests_route) { "#{route}/#{milestone.id}/merge_requests" }

    before do
      milestone.merge_requests << merge_request
    end

    it 'returns merge_requests for a particular milestone' do
      # eager-load another_merge_request
      another_merge_request
      get api(merge_requests_route, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(1)
      expect(json_response.first['title']).to eq(merge_request.title)
      expect(json_response.first['milestone']['title']).to eq(milestone.title)
    end

    it 'returns merge_requests sorted by label priority' do
      merge_request_1 = create(:labeled_merge_request, source_branch: 'branch_1', source_project: project, milestone: milestone, labels: [label_2])
      merge_request_2 = create(:labeled_merge_request, source_branch: 'branch_2', source_project: project, milestone: milestone, labels: [label_1])
      merge_request_3 = create(:labeled_merge_request, source_branch: 'branch_3', source_project: project, milestone: milestone, labels: [label_3])

      get api(merge_requests_route, user)

      expect(json_response.first['id']).to eq(merge_request_2.id)
      expect(json_response.second['id']).to eq(merge_request_1.id)
      expect(json_response.third['id']).to eq(merge_request_3.id)
    end

    it 'returns a 404 error if milestone id not found' do
      not_found_route = "#{route}/#{non_existing_record_id}/merge_requests"

      get api(not_found_route, user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 404 if the user has no access to the milestone' do
      new_user = create :user
      get api(merge_requests_route, new_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 401 error if user not authenticated' do
      get api(merge_requests_route)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns merge_requests ordered by position asc' do
      milestone.merge_requests << another_merge_request
      another_merge_request.labels << label_1
      merge_request.labels << label_2

      get api(merge_requests_route, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(2)
      expect(json_response.first['id']).to eq(another_merge_request.id)
      expect(json_response.second['id']).to eq(merge_request.id)
    end
  end
end
