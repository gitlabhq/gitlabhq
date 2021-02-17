# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PostMergeService do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request, reload: true) { create(:merge_request, assignees: [user]) }
  let_it_be(:project) { merge_request.project }

  subject { described_class.new(project, user).execute(merge_request) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    it_behaves_like 'cache counters invalidator'
    it_behaves_like 'merge request reviewers cache counters invalidator'

    it 'refreshes the number of open merge requests for a valid MR', :use_clean_rails_memory_store_caching do
      # Cache the counter before the MR changed state.
      project.open_merge_requests_count
      merge_request.update!(state: 'merged')

      expect { subject }.to change { project.open_merge_requests_count }.from(1).to(0)
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

    it 'marks MR as merged regardless of errors when closing issues' do
      merge_request.update!(target_branch: 'foo')
      allow(project).to receive(:default_branch).and_return('foo')

      issue = create(:issue, project: project)
      allow(merge_request).to receive(:visible_closing_issues_for).and_return([issue])
      expect_next_instance_of(Issues::CloseService) do |close_service|
        allow(close_service).to receive(:execute).with(issue, commit: merge_request).and_raise(RuntimeError)
      end

      expect { subject }.to raise_error(RuntimeError)

      expect(merge_request.reload).to be_merged
    end

    it 'clean up environments for the merge request' do
      expect_next_instance_of(Ci::StopEnvironmentsService) do |stop_environment_service|
        expect(stop_environment_service).to receive(:execute_for_merge_request).with(merge_request)
      end

      subject
    end

    it 'schedules CleanupRefsService' do
      expect(MergeRequests::CleanupRefsService).to receive(:schedule).with(merge_request)

      subject
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

    context 'for a merge request chain' do
      before do
        ::MergeRequests::UpdateService
          .new(project, user, force_remove_source_branch: '1')
          .execute(merge_request)
      end

      context 'when there is another MR' do
        let!(:another_merge_request) do
          create(:merge_request,
            source_project: source_project,
            source_branch: 'my-awesome-feature',
            target_project: merge_request.source_project,
            target_branch: merge_request.source_branch
          )
        end

        shared_examples 'does not retarget merge request' do
          it 'another merge request is unchanged' do
            expect { subject }.not_to change { another_merge_request.reload.target_branch }
              .from(merge_request.source_branch)
          end
        end

        shared_examples 'retargets merge request' do
          it 'another merge request is retargeted' do
            expect(SystemNoteService)
              .to receive(:change_branch).once
              .with(another_merge_request, another_merge_request.project, user,
                'target', 'delete',
                merge_request.source_branch, merge_request.target_branch)

            expect { subject }.to change { another_merge_request.reload.target_branch }
              .from(merge_request.source_branch)
              .to(merge_request.target_branch)
          end

          context 'when FF retarget_merge_requests is disabled' do
            before do
              stub_feature_flags(retarget_merge_requests: false)
            end

            include_examples 'does not retarget merge request'
          end

          context 'when source branch is to be kept' do
            before do
              ::MergeRequests::UpdateService
                .new(project, user, force_remove_source_branch: false)
                .execute(merge_request)
            end

            include_examples 'does not retarget merge request'
          end
        end

        context 'in the same project' do
          let(:source_project) { project }

          it_behaves_like 'retargets merge request'

          context 'and is closed' do
            before do
              another_merge_request.close
            end

            it_behaves_like 'does not retarget merge request'
          end

          context 'and is merged' do
            before do
              another_merge_request.mark_as_merged
            end

            it_behaves_like 'does not retarget merge request'
          end
        end

        context 'in forked project' do
          let!(:source_project) { fork_project(project) }

          context 'when user has access to source project' do
            before do
              source_project.add_developer(user)
            end

            it_behaves_like 'retargets merge request'
          end

          context 'when user does not have access to source project' do
            it_behaves_like 'does not retarget merge request'
          end
        end

        context 'and current and another MR is from a fork' do
          let(:project) { create(:project) }
          let(:source_project) { fork_project(project) }

          let(:merge_request) do
            create(:merge_request,
              source_project: source_project,
              target_project: project
            )
          end

          before do
            source_project.add_developer(user)
          end

          it_behaves_like 'does not retarget merge request'
        end
      end

      context 'when many merge requests are to be retargeted' do
        let!(:many_merge_requests) do
          create_list(:merge_request, 10, :unique_branches,
            source_project: merge_request.source_project,
            target_project: merge_request.source_project,
            target_branch: merge_request.source_branch
          )
        end

        it 'retargets only 4 of them' do
          subject

          expect(many_merge_requests.each(&:reload).pluck(:target_branch).tally)
            .to eq(
              merge_request.source_branch => 6,
              merge_request.target_branch => 4
            )
        end
      end
    end
  end
end
