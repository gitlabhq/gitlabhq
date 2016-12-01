require 'spec_helper'

describe 'cycle analytics events' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issue) {  create(:issue, project: project, created_at: 2.days.ago) }

  describe 'GET /:namespace/:project/cycle_analytics/events/issues' do
    before do
      project.team << [user, :developer]

      allow_any_instance_of(Gitlab::ReferenceExtractor).to receive(:issues).and_return([issue])

      3.times { create_cycle }
      deploy_master

      login_as(user)
    end

    it 'lists the issue events' do
      get namespace_project_cycle_analytics_issue_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      first_issue_iid = Issue.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['events'].first['iid']).to eq(first_issue_iid)
    end

    it 'lists the plan events' do
      get namespace_project_cycle_analytics_plan_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      expect(json_response['events'].first['short_sha']).to eq(MergeRequest.last.commits.first.short_id)
    end

    it 'lists the code events' do
      get namespace_project_cycle_analytics_code_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      first_mr_iid = project.merge_requests.order(id: :desc).pluck(:iid).first.to_s

      expect(json_response['events'].first['iid']).to eq(first_mr_iid)
    end

    it 'lists the test events' do
      get namespace_project_cycle_analytics_test_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      expect(json_response['events'].first['date']).not_to be_empty
    end

    it 'lists the review events' do
      get namespace_project_cycle_analytics_review_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      first_mr_iid = MergeRequest.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['events'].first['iid']).to eq(first_mr_iid)
    end

    it 'lists the staging events' do
      get namespace_project_cycle_analytics_staging_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      expect(json_response['events'].first['date']).not_to be_empty
    end

    it 'lists the production events' do
      get namespace_project_cycle_analytics_production_path(project.namespace, project, format: :json)

      expect(json_response['events']).not_to be_empty

      first_issue_iid = Issue.order(created_at: :desc).pluck(:iid).first.to_s

      expect(json_response['events'].first['iid']).to eq(first_issue_iid)
    end

    context 'specific branch' do
      it 'lists the test events' do
        branch = MergeRequest.first.source_branch

        get namespace_project_cycle_analytics_test_path(project.namespace, project, format: :json, branch: branch)

        expect(json_response['events']).not_to be_empty

        expect(json_response['events'].first['date']).not_to be_empty
      end
    end

    context 'with private project and builds' do
      before do
        ProjectMember.first.update(access_level: Gitlab::Access::GUEST)
      end

      it 'does not list the test events' do
        get namespace_project_cycle_analytics_test_path(project.namespace, project, format: :json)

        expect(response).to have_http_status(:not_found)
      end

      it 'does not list the staging events' do
        get namespace_project_cycle_analytics_staging_path(project.namespace, project, format: :json)

        expect(response).to have_http_status(:not_found)
      end

      it 'lists the issue events' do
        get namespace_project_cycle_analytics_issue_path(project.namespace, project, format: :json)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end

  def create_cycle
    milestone = create(:milestone, project: project)
    issue.update(milestone: milestone)
    mr = create_merge_request_closing_issue(issue)

    pipeline = create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha)
    pipeline.run

    create(:ci_build, pipeline: pipeline, status: :success, author: user)
    create(:ci_build, pipeline: pipeline, status: :success, author: user)

    merge_merge_requests_closing_issue(issue)

    ProcessCommitWorker.new.perform(project.id, user.id, mr.commits.last.sha)
  end
end
