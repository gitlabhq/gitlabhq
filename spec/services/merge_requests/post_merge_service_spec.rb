# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PostMergeService, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request, reload: true) { create(:merge_request, assignees: [user]) }
  let_it_be(:project, reload: true) { merge_request.project }
  let(:params) { {} }

  subject { described_class.new(project: project, current_user: user, params: params).execute(merge_request) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    it_behaves_like 'cache counters invalidator'
    it_behaves_like 'merge request reviewers cache counters invalidator'

    it 'refreshes the number of open merge requests for a valid MR', :use_clean_rails_memory_store_caching do
      # Cache the counter before the MR changed state.
      project.open_merge_requests_count

      expect do
        subject

        BatchLoader::Executor.clear_current
      end.to change { project.open_merge_requests_count }.from(1).to(0)
    end

    it 'updates metrics' do
      metrics = merge_request.metrics
      metrics_service = double(MergeRequestMetricsService)
      allow(MergeRequestMetricsService)
        .to receive(:new)
        .with(metrics)
        .and_return(metrics_service)

      expect(metrics_service).to receive(:merge)

      subject
    end

    it 'calls the merge request activity counter' do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_merge_mr_action)
        .with(user: user)

      subject
    end

    it 'deletes non-latest diffs' do
      diff_removal_service = instance_double(MergeRequests::DeleteNonLatestDiffsService, execute: nil)

      expect(MergeRequests::DeleteNonLatestDiffsService)
        .to receive(:new).with(merge_request)
        .and_return(diff_removal_service)

      subject

      expect(diff_removal_service).to have_received(:execute)
    end

    it 'clean up environments for the merge request' do
      expect_next_instance_of(::Environments::StopService) do |stop_environment_service|
        expect(stop_environment_service).to receive(:execute_for_merge_request_pipeline).with(merge_request)
      end

      subject
    end

    it 'schedules CleanupRefsService' do
      expect(MergeRequests::CleanupRefsService).to receive(:schedule).with(merge_request)

      subject
    end

    context 'when there are issues to be closed' do
      let_it_be(:issue) { create(:issue, project: project) }

      before do
        merge_request.update!(target_branch: 'foo')

        allow(project).to receive(:default_branch).and_return('foo')
        allow(merge_request).to receive(:closes_issues).and_return([issue])
      end

      it 'performs MergeRequests::CloseIssueWorker asynchronously' do
        create(:merge_requests_closing_issues, merge_request: merge_request, issue: issue)

        expect(MergeRequests::CloseIssueWorker)
          .to receive(:perform_async)
          .with(project.id, user.id, issue.id, merge_request.id, { skip_authorization: false })

        subject

        expect(merge_request.reload).to be_merged
      end

      context 'when issue is an external issue' do
        let_it_be(:issue) { ExternalIssue.new('JIRA-123', project) }

        before do
          project.update!(has_external_issue_tracker: true)
          merge_request.reload
        end

        it 'executes Issues::CloseService' do
          expect_next_instance_of(Issues::CloseService) do |close_service|
            expect(close_service).to receive(:execute).with(issue, commit: merge_request)
          end

          subject

          expect(merge_request.reload).to be_merged
        end
      end
    end

    context 'when the merge request has review apps' do
      it 'cancels all review app deployments' do
        pipeline = create(:ci_pipeline,
          source: :merge_request_event,
          merge_request: merge_request,
          project: project,
          sha: merge_request.diff_head_sha,
          merge_requests_as_head_pipeline: [merge_request])

        review_env_a = create(:environment, project: project, state: :available, name: 'review/a')
        review_env_b = create(:environment, project: project, state: :available, name: 'review/b')
        review_env_c = create(:environment, project: project, state: :stopped, name: 'review/c')
        deploy_env = create(:environment, project: project, state: :available, name: 'deploy')

        review_job_a1 = create(:ci_build, :with_deployment, :start_review_app,
          pipeline: pipeline, project: project, environment: review_env_a.name)
        review_job_a2 = create(:ci_build, :with_deployment, :start_review_app,
          pipeline: pipeline, project: project, environment: review_env_a.name)
        finished_review_job_a = create(:ci_build, :with_deployment, :start_review_app,
          pipeline: pipeline, project: project, status: :success, environment: review_env_a.name)
        review_job_b1 = create(:ci_build, :with_deployment, :start_review_app,
          pipeline: pipeline, project: project, environment: review_env_b.name)
        review_job_b2 = create(:ci_build, :start_review_app,
          pipeline: pipeline, project: project, environment: review_env_b.name)
        review_job_c1 = create(:ci_build, :with_deployment, :start_review_app,
          pipeline: pipeline, project: project, environment: review_env_c.name)
        deploy_job = create(:ci_build, :with_deployment, :deploy_to_production,
          pipeline: pipeline, project: project, environment: deploy_env.name)

        subject

        expect(review_job_a1.reload.canceled?).to be true
        expect(review_job_a2.reload.canceled?).to be true
        expect(finished_review_job_a.reload.status).to eq "success"
        expect(finished_review_job_a.reload.canceled?).to be false
        expect(review_job_b1.reload.canceled?).to be true
        expect(review_job_b2.reload.canceled?).to be false
        expect(review_job_c1.reload.canceled?).to be false
        expect(deploy_job.reload.canceled?).to be false
      end
    end

    context 'when the merge request has a pages deployment' do
      it 'performs Pages::DeactivateMrDeploymentWorker asynchronously' do
        expect(Pages::DeactivateMrDeploymentsWorker)
          .to receive(:perform_async)
          .with(merge_request.id)

        subject

        expect(merge_request.reload).to be_merged
      end
    end
  end

  context 'when there are auto merge MRs with the branch as target' do
    context 'when source branch is to be deleted' do
      let(:params) { { delete_source_branch: true } }

      it 'aborts auto merges' do
        mr_1 = create(:merge_request, :merge_when_checks_pass, target_branch: merge_request.source_branch,
          source_branch: "test", source_project: merge_request.project)
        mr_2 = create(:merge_request, :merge_when_checks_pass, target_branch: merge_request.source_branch,
          source_branch: "feature", source_project: merge_request.project)
        mr_3 = create(:merge_request, :merge_when_checks_pass, target_branch: 'feature',
          source_branch: 'second', source_project: merge_request.project)

        expect(merge_request.source_project.merge_requests.with_auto_merge_enabled).to contain_exactly(mr_1, mr_2, mr_3)
        subject
        expect(merge_request.source_project.merge_requests.with_auto_merge_enabled).to contain_exactly(mr_3)
      end
    end

    context 'when source branch is not be deleted' do
      it 'does not abort any auto merges' do
        mr_1 = create(:merge_request, :merge_when_checks_pass, target_branch: merge_request.source_branch,
          source_branch: "test", source_project: merge_request.project)
        mr_2 = create(:merge_request, :merge_when_checks_pass, target_branch: merge_request.source_branch,
          source_branch: "feature", source_project: merge_request.project)
        mr_3 = create(:merge_request, :merge_when_checks_pass, target_branch: 'feature',
          source_branch: 'second', source_project: merge_request.project)

        expect(merge_request.source_project.merge_requests.with_auto_merge_enabled).to contain_exactly(mr_1, mr_2, mr_3)
        subject
        expect(merge_request.source_project.merge_requests.with_auto_merge_enabled).to contain_exactly(mr_1, mr_2, mr_3)
      end
    end
  end

  context 'when event source is given' do
    let(:source) { create(:merge_request, :simple, source_project: project) }

    subject { described_class.new(project: project, current_user: user).execute(merge_request, source) }

    it 'creates a resource_state_event as expected' do
      expect { subject }.to change { ResourceStateEvent.count }.by 1

      event = merge_request.resource_state_events.last

      expect(event.state).to eq 'merged'
      expect(event.source_merge_request).to eq source
    end
  end
end
