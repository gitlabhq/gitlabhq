require 'spec_helper'

describe 'cycle analytics events' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  describe 'GET /:namespace/:project/cycle_analytics/events/issues' do
    before do
      project.team << [user, :developer]

      3.times { create_cycle }
      deploy_master

      login_as(user)
    end

    it 'lists the issue events in the right order' do
      get namespace_project_cycle_analytics_issue_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      first_issue_iid = Issue.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['events'].first['iid']).to eq(first_issue_iid)
    end

    it 'lists the plan events in the right order' do
      get namespace_project_cycle_analytics_plan_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      first_date = DateTime.parse(json_response['events'].first['commit']['authored_date'])
      last_date = DateTime.parse(json_response['events'].last['commit']['authored_date'])

      expect(first_date).to be > last_date
    end

    it 'lists the code events in the right order' do
      get namespace_project_cycle_analytics_code_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      first_mr_iid = Issue.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['events'].first['iid']).to eq(first_mr_iid)
    end

    it 'lists the test events in the right order' do
      get namespace_project_cycle_analytics_test_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      # TODO create builds
    end

    it 'lists the review events in the right order' do
      get namespace_project_cycle_analytics_review_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      first_mr_iid = Issue.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['events'].first['iid']).to eq(first_mr_iid)
    end

    it 'lists the staging events in the right order' do
      get namespace_project_cycle_analytics_staging_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      # TODO create builds
    end

    it 'lists the production events in the right order' do
      get namespace_project_cycle_analytics_production_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      first_issue_iid = Issue.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['events'].first['iid']).to eq(first_issue_iid)
    end
  end

  def json_response
    JSON.parse(response.body)
  end

  def create_cycle
    issue = create(:issue, project: project, created_at: 2.days.ago)
    milestone = create(:milestone, project: project)
    issue.update(milestone: milestone)

    create_merge_request_closing_issue(issue)
    merge_merge_requests_closing_issue(issue)
  end
end
