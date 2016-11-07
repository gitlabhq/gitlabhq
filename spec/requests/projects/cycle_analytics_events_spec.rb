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

    it 'lists the issue events' do
      get namespace_project_cycle_analytics_issue_path(project.namespace, project, format: :json)

      expect(json_response['items']).not_to be_empty

      first_issue_iid = Issue.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['items'].first['iid']).to eq(first_issue_iid)
    end

    it 'lists the plan events' do
      get namespace_project_cycle_analytics_plan_path(project.namespace, project, format: :json)

      expect(json_response['items']).not_to be_empty

      commits = []

      MergeRequest.all.each do |mr|
        mr.merge_request_diff.st_commits.each do |commit|
          commits << { date: commit[:authored_date], sha: commit[:id] }
        end
      end

      newest_sha = commits.sort_by { |k| k['date'] }.first[:sha][0...8]

      expect(json_response['items'].first['sha']).to eq(newest_sha)
    end

    it 'lists the code events' do
      get namespace_project_cycle_analytics_code_path(project.namespace, project, format: :json)

      expect(json_response['items']).not_to be_empty

      first_mr_iid = Issue.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['items'].first['iid']).to eq(first_mr_iid)
    end

    it 'lists the test events' do
      get namespace_project_cycle_analytics_test_path(project.namespace, project, format: :json)

      expect(json_response['items']).not_to be_empty

      expect(json_response['items'].first['date']).not_to be_empty
    end

    it 'lists the review events' do
      get namespace_project_cycle_analytics_review_path(project.namespace, project, format: :json)

      expect(json_response['items']).not_to be_empty

      first_mr_iid = Issue.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['items'].first['iid']).to eq(first_mr_iid)
    end

    it 'lists the staging events' do
      get namespace_project_cycle_analytics_staging_path(project.namespace, project, format: :json)

      expect(json_response['items']).not_to be_empty

      expect(json_response['items'].first['date']).not_to be_empty
    end

    it 'lists the production events' do
      get namespace_project_cycle_analytics_production_path(project.namespace, project, format: :json)

      expect(json_response['items']).not_to be_empty

      first_issue_iid = Issue.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['items'].first['iid']).to eq(first_issue_iid)
    end
  end

  def json_response
    JSON.parse(response.body)
  end

  def create_cycle
    issue = create(:issue, project: project, created_at: 2.days.ago)
    milestone = create(:milestone, project: project)
    issue.update(milestone: milestone)
    mr = create_merge_request_closing_issue(issue)

    pipeline = create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha)
    pipeline.run

    create(:ci_build, pipeline: pipeline, status: :success, author: user)
    create(:ci_build, pipeline: pipeline, status: :success, author: user)

    merge_merge_requests_closing_issue(issue)
  end
end
