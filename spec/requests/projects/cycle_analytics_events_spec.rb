# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'value stream analytics events' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, public_builds: false) }
  let(:issue) { create(:issue, project: project, created_at: 2.days.ago) }

  describe 'GET /:namespace/:project/value_stream_analytics/events/issues' do
    before do
      project.add_developer(user)

      3.times do |count|
        travel_to(Time.now + count.days) do
          create_cycle
        end
      end

      deploy_master(user, project)

      login_as(user)
    end

    it 'lists the issue events' do
      get project_cycle_analytics_issue_path(project, format: :json)

      first_issue_iid = project.issues.sort_by_attribute(:created_desc).pluck(:iid).first.to_s

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['iid']).to eq(first_issue_iid)
    end

    it 'lists the plan events' do
      get project_cycle_analytics_plan_path(project, format: :json)

      first_issue_iid = project.issues.sort_by_attribute(:created_desc).pluck(:iid).first.to_s

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['iid']).to eq(first_issue_iid)
    end

    it 'lists the code events' do
      get project_cycle_analytics_code_path(project, format: :json)

      expect(json_response['events']).not_to be_empty

      first_mr_iid = project.merge_requests.sort_by_attribute(:created_desc).pluck(:iid).first.to_s

      expect(json_response['events'].first['iid']).to eq(first_mr_iid)
    end

    it 'lists the test events', :sidekiq_inline do
      get project_cycle_analytics_test_path(project, format: :json)

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['date']).not_to be_empty
    end

    it 'lists the review events' do
      get project_cycle_analytics_review_path(project, format: :json)

      first_mr_iid = project.merge_requests.sort_by_attribute(:created_desc).pluck(:iid).first.to_s

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['iid']).to eq(first_mr_iid)
    end

    it 'lists the staging events', :sidekiq_inline do
      get project_cycle_analytics_staging_path(project, format: :json)

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['date']).not_to be_empty
    end

    context 'with private project and builds' do
      before do
        project.members.last.update!(access_level: Gitlab::Access::GUEST)
      end

      it 'does not list the test events' do
        get project_cycle_analytics_test_path(project, format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not list the staging events' do
        get project_cycle_analytics_staging_path(project, format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'lists the issue events' do
        get project_cycle_analytics_issue_path(project, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  def create_cycle
    milestone = create(:milestone, project: project)
    issue.update!(milestone: milestone)
    mr = create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}")

    pipeline = create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr)
    pipeline.run

    create(:ci_build, pipeline: pipeline, status: :success, author: user)
    create(:ci_build, pipeline: pipeline, status: :success, author: user)

    merge_merge_requests_closing_issue(user, project, issue)

    ProcessCommitWorker.new.perform(project.id, user.id, mr.commits.last.to_hash)

    mr.metrics.update!(latest_build_started_at: 1.hour.ago, latest_build_finished_at: Time.now)
  end
end
