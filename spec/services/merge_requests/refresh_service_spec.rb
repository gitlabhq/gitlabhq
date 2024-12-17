# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RefreshService, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include UserHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:service) { described_class }

  describe '#execute' do
    before do
      @user = create(:user)
      group = create(:group)
      group.add_owner(@user)

      @project = create(:project, :repository, namespace: group)
      @fork_project = fork_project(@project, @user, repository: true)

      @merge_request = create(
        :merge_request,
        source_project: @project,
        source_branch: 'master',
        target_branch: 'feature',
        target_project: @project,
        auto_merge_enabled: true,
        auto_merge_strategy: AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS,
        merge_user: @user
      )

      @another_merge_request = create(
        :merge_request,
        source_project: @project,
        source_branch: 'master',
        target_branch: 'test',
        target_project: @project,
        auto_merge_enabled: true,
        auto_merge_strategy: AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS,
        merge_user: @user
      )

      @fork_merge_request = create(
        :merge_request,
        source_project: @fork_project,
        source_branch: 'master',
        target_branch: 'feature',
        target_project: @project
      )

      @build_failed_todo = create(
        :todo,
        :build_failed,
        user: @user,
        project: @project,
        target: @merge_request,
        author: @user
      )

      @fork_build_failed_todo = create(
        :todo,
        :build_failed,
        user: @user,
        project: @project,
        target: @merge_request,
        author: @user
      )

      @commits = @merge_request.commits

      @oldrev = @commits.last.id
      @newrev = @commits.first.id
    end

    context 'push to origin repo source branch' do
      let(:refresh_service) { service.new(project: @project, current_user: @user) }
      let(:notification_service) { spy('notification_service') }

      before do
        allow(refresh_service).to receive(:execute_hooks)
        allow(NotificationService).to receive(:new) { notification_service }
      end

      context 'query count' do
        it 'does not execute a lot of queries' do
          # Hardcoded the query limit since the queries can also be reduced even
          # if there are the same number of merge requests (e.g. by preloading
          # associations). This should also fail in case additional queries are
          # added elsewhere that affected this service.
          #
          # The limit is based on the number of queries executed at the current
          # state of the service. As we reduce the number of queries executed in
          # this service, the limit should be reduced as well.
          expect { refresh_service.execute(@oldrev, @newrev, 'refs/heads/master') }
            .not_to exceed_query_limit(260)
        end
      end

      it 'executes hooks with update action' do
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs

        expect(refresh_service).to have_received(:execute_hooks)
          .with(@merge_request, 'update', old_rev: @oldrev)

        expect(notification_service).to have_received(:push_to_merge_request)
          .with(@merge_request, @user, new_commits: anything, existing_commits: anything)
        expect(notification_service).to have_received(:push_to_merge_request)
          .with(@another_merge_request, @user, new_commits: anything, existing_commits: anything)

        expect(@merge_request.notes).not_to be_empty
        expect(@merge_request).to be_open
        expect(@merge_request.auto_merge_enabled).to be_falsey
        expect(@merge_request.diff_head_sha).to eq(@newrev)
        expect(@fork_merge_request).to be_open
        expect(@fork_merge_request.notes).to be_empty
        expect(@build_failed_todo).to be_done
        expect(@fork_build_failed_todo).to be_done
      end

      it 'triggers mergeRequestMergeStatusUpdated GraphQL subscription conditionally' do
        expect(GraphqlTriggers).to receive(:merge_request_merge_status_updated).with(@merge_request)
        expect(GraphqlTriggers).to receive(:merge_request_merge_status_updated).with(@another_merge_request)
        expect(GraphqlTriggers).not_to receive(:merge_request_merge_status_updated).with(@fork_merge_request)

        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
      end

      context 'when a merge error exists' do
        let(:error_message) { 'This is a merge error' }

        before do
          @merge_request = create(:merge_request,
            source_project: @project,
            source_branch: 'feature',
            target_branch: 'master',
            target_project: @project,
            merge_error: error_message)
        end

        it 'clears merge errors when pushing to the source branch' do
          expect { refresh_service.execute(@oldrev, @newrev, 'refs/heads/feature') }
            .to change { @merge_request.reload.merge_error }
            .from(error_message)
            .to(nil)
        end

        it 'does not clear merge errors when pushing to the target branch' do
          expect { refresh_service.execute(@oldrev, @newrev, 'refs/heads/master') }
            .not_to change { @merge_request.reload.merge_error }
        end
      end

      it 'reloads source branch MRs memoization' do
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')

        expect { refresh_service.execute(@oldrev, @newrev, 'refs/heads/master') }.to change {
          refresh_service.instance_variable_get(:@source_merge_requests).first.merge_request_diff
        }
      end

      it 'outdates MR suggestions' do
        expect_next_instance_of(Suggestions::OutdateService) do |service|
          expect(service).to receive(:execute).with(@merge_request).and_call_original
          expect(service).to receive(:execute).with(@another_merge_request).and_call_original
        end

        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
      end

      context 'when source branch ref does not exists' do
        before do
          ::Branches::DeleteService.new(@project, @user).execute(@merge_request.source_branch)
        end

        it 'closes MRs without source branch ref' do
          expect { refresh_service.execute(@oldrev, @newrev, 'refs/heads/master') }
            .to change { @merge_request.reload.state }
            .from('opened')
            .to('closed')

          expect(@fork_merge_request.reload).to be_open
        end

        it 'does not change the merge request diff' do
          expect { refresh_service.execute(@oldrev, @newrev, 'refs/heads/master') }
            .not_to change { @merge_request.reload.merge_request_diff }
        end
      end

      it 'calls the merge request activity counter' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_mr_including_ci_config)
          .with(user: @merge_request.author, merge_request: @merge_request)

        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_mr_including_ci_config)
          .with(user: @another_merge_request.author, merge_request: @another_merge_request)

        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
      end
    end

    context 'when pipeline exists for the source branch' do
      let!(:pipeline) { create(:ci_empty_pipeline, ref: @merge_request.source_branch, project: @project, sha: @commits.first.sha) }

      subject { service.new(project: @project, current_user: @user).execute(@oldrev, @newrev, 'refs/heads/master') }

      it 'updates the head_pipeline_id for @merge_request', :sidekiq_inline do
        expect { subject }.to change { @merge_request.reload.head_pipeline_id }.from(nil).to(pipeline.id)
      end

      it 'does not update the head_pipeline_id for @fork_merge_request' do
        expect { subject }.not_to change { @fork_merge_request.reload.head_pipeline_id }
      end
    end

    context 'Pipelines for merge requests', :sidekiq_inline do
      before do
        stub_ci_pipeline_yaml_file(config)
      end

      subject { service.new(project: project, current_user: @user).execute(@oldrev, @newrev, ref) }

      let(:ref) { 'refs/heads/master' }
      let(:project) { @project }

      context "when .gitlab-ci.yml has merge_requests keywords" do
        let(:config) do
          YAML.dump({
            test: {
              stage: 'test',
              script: 'echo',
              only: ['merge_requests']
            }
          })
        end

        it 'create detached merge request pipeline with commits' do
          expect { subject }
            .to change { @merge_request.pipelines_for_merge_request.count }.by(1)
            .and change { @another_merge_request.pipelines_for_merge_request.count }.by(0)

          expect(@merge_request.has_commits?).to be_truthy
          expect(@another_merge_request.has_commits?).to be_falsy
        end

        context 'when push is a branch removal' do
          before do
            # If @newrev is a blank SHA, it means the ref has been removed
            @newrev = Gitlab::Git::SHA1_BLANK_SHA
          end

          it 'does not create detached merge request pipeline' do
            expect { subject }
              .not_to change { @merge_request.pipelines_for_merge_request.count }
          end
        end

        context 'when "push_options: nil" is passed' do
          let(:service_instance) { service.new(project: project, current_user: @user, params: { push_options: nil }) }

          subject { service_instance.execute(@oldrev, @newrev, ref) }

          it 'creates a detached merge request pipeline with commits' do
            expect { subject }
              .to change { @merge_request.pipelines_for_merge_request.count }.by(1)
              .and change { @another_merge_request.pipelines_for_merge_request.count }.by(0)

            expect(@merge_request.has_commits?).to be_truthy
            expect(@another_merge_request.has_commits?).to be_falsy
          end
        end

        context 'when ci.skip push_options are passed' do
          let(:params) { { push_options: { ci: { skip: true } } } }
          let(:service_instance) { service.new(project: project, current_user: @user, params: params) }

          subject { service_instance.execute(@oldrev, @newrev, ref) }

          it 'creates a skipped detached merge request pipeline with commits' do
            expect { subject }
              .to change { @merge_request.pipelines_for_merge_request.count }.by(1)
              .and change { @another_merge_request.pipelines_for_merge_request.count }.by(0)

            expect(@merge_request.has_commits?).to be_truthy
            expect(@another_merge_request.has_commits?).to be_falsy

            pipeline = @merge_request.pipelines_for_merge_request.last
            expect(pipeline).to be_skipped
          end
        end

        it 'does not create detached merge request pipeline for forked project' do
          expect { subject }
            .not_to change { @fork_merge_request.pipelines_for_merge_request.count }
        end

        it 'create detached merge request pipeline for non-fork merge request' do
          subject

          expect(@merge_request.pipelines_for_merge_request.first)
            .to be_detached_merge_request_pipeline
        end

        context 'when service is hooked by target branch' do
          let(:ref) { 'refs/heads/feature' }

          it 'does not create detached merge request pipeline' do
            expect { subject }
              .not_to change { @merge_request.pipelines_for_merge_request.count }
          end
        end

        context 'when service runs on forked project' do
          let(:project) { @fork_project }

          it 'creates detached merge request pipeline for fork merge request' do
            expect { subject }
              .to change { @fork_merge_request.pipelines_for_merge_request.count }.by(1)

            merge_request_pipeline = @fork_merge_request.pipelines_for_merge_request.first
            expect(merge_request_pipeline).to be_detached_merge_request_pipeline
            expect(merge_request_pipeline.project).to eq(@project)
          end
        end

        context "when branch pipeline was created before a detaced merge request pipeline has been created" do
          before do
            create(
              :ci_pipeline,
              project: @merge_request.source_project,
              sha: @merge_request.diff_head_sha,
              ref: @merge_request.source_branch,
              tag: false
            )

            subject
          end

          it 'sets the latest detached merge request pipeline as a head pipeline' do
            @merge_request.reload
            expect(@merge_request.diff_head_pipeline).to be_merge_request_event
          end

          it 'returns pipelines in correct order' do
            @merge_request.reload
            expect(@merge_request.all_pipelines.first).to be_merge_request_event
            expect(@merge_request.all_pipelines.second).to be_push
          end
        end

        context "when MergeRequestUpdateWorker is retried by an exception" do
          it 'does not re-create a duplicate detached merge request pipeline' do
            expect do
              service.new(project: @project, current_user: @user).execute(@oldrev, @newrev, 'refs/heads/master')
            end.to change { @merge_request.pipelines_for_merge_request.count }.by(1)

            expect do
              service.new(project: @project, current_user: @user).execute(@oldrev, @newrev, 'refs/heads/master')
            end.not_to change { @merge_request.pipelines_for_merge_request.count }
          end
        end

        context 'when the pipeline should be skipped' do
          it 'saves a skipped detached merge request pipeline' do
            project.repository.create_file(
              @user, 'new-file.txt', 'A new file',
              message: '[skip ci] This is a test',
              branch_name: 'master'
            )

            expect { subject }
              .to change { @merge_request.pipelines_for_merge_request.count }.by(1)
            expect(@merge_request.pipelines_for_merge_request.last).to be_skipped
          end
        end
      end

      context "when .gitlab-ci.yml does not have merge_requests keywords" do
        let(:config) do
          YAML.dump({
            test: {
              stage: 'test',
              script: 'echo'
            }
          })
        end

        it 'does not create a detached merge request pipeline' do
          expect { subject }
            .not_to change { @merge_request.pipelines_for_merge_request.count }
        end
      end

      context 'when .gitlab-ci.yml is invalid' do
        let(:config) { 'invalid yaml file' }

        it 'persists a pipeline with config error' do
          expect { subject }
            .to change { @merge_request.pipelines_for_merge_request.count }.by(1)
          expect(@merge_request.pipelines_for_merge_request.last).to be_failed
          expect(@merge_request.pipelines_for_merge_request.last).to be_config_error
        end
      end

      context 'when .gitlab-ci.yml file is valid but has a logical error' do
        let(:config) do
          YAML.dump({
            build: {
              script: 'echo "Valid yaml syntax, but..."',
              only: ['master']
            },
            test: {
              script: 'echo "... I depend on build, which does not run."',
              only: ['merge_request'],
              needs: ['build']
            }
          })
        end

        it 'persists a pipeline with config error' do
          expect { subject }
            .to change { @merge_request.pipelines_for_merge_request.count }.by(1)
          expect(@merge_request.pipelines_for_merge_request.last).to be_failed
          expect(@merge_request.pipelines_for_merge_request.last).to be_config_error
        end
      end
    end

    context 'push to origin repo source branch' do
      let(:refresh_service) { service.new(project: @project, current_user: @user) }
      let(:notification_service) { spy('notification_service') }

      before do
        allow(refresh_service).to receive(:execute_hooks)
        allow(NotificationService).to receive(:new) { notification_service }
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      it 'executes hooks with update action' do
        expect(refresh_service).to have_received(:execute_hooks)
          .with(@merge_request, 'update', old_rev: @oldrev)
        expect(notification_service).to have_received(:push_to_merge_request)
          .with(@merge_request, @user, new_commits: anything, existing_commits: anything)
        expect(notification_service).to have_received(:push_to_merge_request)
          .with(@another_merge_request, @user, new_commits: anything, existing_commits: anything)

        expect(@merge_request.notes).not_to be_empty
        expect(@merge_request).to be_open
        expect(@merge_request.auto_merge_enabled).to be_falsey
        expect(@merge_request.diff_head_sha).to eq(@newrev)
        expect(@fork_merge_request).to be_open
        expect(@fork_merge_request.notes).to be_empty
        expect(@build_failed_todo).to be_done
        expect(@fork_build_failed_todo).to be_done
      end
    end

    context 'push to origin repo target branch' do
      context 'when all MRs to the target branch had diffs' do
        before do
          service.new(project: @project, current_user: @user).execute(@oldrev, @newrev, 'refs/heads/feature')
          reload_mrs
        end

        it 'updates the merge state' do
          expect(@merge_request).to be_merged
          expect(@fork_merge_request).to be_merged
          expect(@build_failed_todo).to be_done
          expect(@fork_build_failed_todo).to be_done

          expect(@merge_request.resource_state_events.last.state).to eq('merged')
          expect(@fork_merge_request.resource_state_events.last.state).to eq('merged')
        end
      end

      context 'when an MR to be closed was empty already' do
        let!(:empty_fork_merge_request) do
          create(
            :merge_request,
            source_project: @fork_project,
            source_branch: 'master',
            target_branch: 'master',
            target_project: @project
          )
        end

        before do
          # This spec already has a fake push, so pretend that we were targeting
          # feature all along.
          empty_fork_merge_request.update_columns(target_branch: 'feature')

          service.new(project: @project, current_user: @user).execute(@oldrev, @newrev, 'refs/heads/feature')
          reload_mrs
          empty_fork_merge_request.reload
        end

        it 'only updates the non-empty MRs' do
          expect(@merge_request).to be_merged
          expect(@fork_merge_request).to be_merged

          expect(empty_fork_merge_request).to be_open
          expect(empty_fork_merge_request.merge_request_diff.state).to eq('empty')
          expect(empty_fork_merge_request.notes).to be_empty

          expect(@merge_request.resource_state_events.last.state).to eq('merged')
          expect(@fork_merge_request.resource_state_events.last.state).to eq('merged')
        end
      end

      context 'manual merge of source branch' do
        before do
          # Merge master -> feature branch
          @project.repository.merge(@user, @merge_request.diff_head_sha, @merge_request, 'Test message')
          commit = @project.repository.commit('feature')
          service.new(project: @project, current_user: @user).execute(@oldrev, commit.id, 'refs/heads/feature')
          reload_mrs
        end

        it 'updates the merge state' do
          commit = @project.repository.commit('feature')

          state_event_1 = @merge_request.resource_state_events.last
          expect(state_event_1.state).to eq('merged')
          expect(state_event_1.source_merge_request).to eq(nil)
          expect(state_event_1.source_commit).to eq(commit.id)

          state_event_2 = @fork_merge_request.resource_state_events.last
          expect(state_event_2.state).to eq('merged')
          expect(state_event_2.source_merge_request).to eq(nil)
          expect(state_event_2.source_commit).to eq(commit.id)

          expect(@merge_request).to be_merged
          expect(@merge_request.diffs.size).to be > 0
          expect(@fork_merge_request).to be_merged
          expect(@build_failed_todo).to be_done
          expect(@fork_build_failed_todo).to be_done
        end
      end

      context 'With merged MR that contains the same SHA' do
        before do
          @merge_request.head_pipeline = create(
            :ci_pipeline,
            :success,
            project: @merge_request.source_project,
            ref: @merge_request.source_branch,
            sha: @merge_request.diff_head_sha)

          @merge_request.update_head_pipeline

          # Merged via UI
          MergeRequests::MergeService
            .new(project: @merge_request.target_project, current_user: @user, params: { sha: @merge_request.diff_head_sha })
            .execute(@merge_request)

          commit = @project.repository.commit('feature')
          service.new(project: @project, current_user: @user).execute(@oldrev, commit.id, 'refs/heads/feature')
          reload_mrs
        end

        it 'updates the merge state' do
          state_event_1 = @merge_request.resource_state_events.last
          expect(state_event_1.state).to eq('merged')
          expect(state_event_1.source_merge_request).to eq(nil)
          expect(state_event_1.source_commit).to eq(nil)

          state_event_2 = @fork_merge_request.resource_state_events.last
          expect(state_event_2.state).to eq('merged')
          expect(state_event_2.source_merge_request).to eq(@merge_request)
          expect(state_event_2.source_commit).to eq(nil)

          expect(@fork_merge_request).to be_merged
        end
      end
    end

    context 'push to fork repo source branch' do
      let(:refresh_service) { service.new(project: @fork_project, current_user: @user) }

      def refresh
        allow(refresh_service).to receive(:execute_hooks)
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      context 'open fork merge request' do
        it 'calls MergeRequests::LinkLfsObjectsService#execute' do
          expect_next_instance_of(MergeRequests::LinkLfsObjectsService) do |svc|
            expect(svc).to receive(:execute).with(@fork_merge_request, oldrev: @oldrev, newrev: @newrev)
          end

          refresh
        end

        it 'executes hooks with update action' do
          refresh

          expect(refresh_service).to have_received(:execute_hooks)
            .with(@fork_merge_request, 'update', old_rev: @oldrev)

          expect(@merge_request.notes).to be_empty
          expect(@merge_request).to be_open
          expect(@fork_merge_request.notes.last.note).to include('added 28 commits')
          expect(@fork_merge_request).to be_open
          expect(@build_failed_todo).to be_pending
          expect(@fork_build_failed_todo).to be_pending
        end

        it 'outdates opened forked MR suggestions' do
          expect_next_instance_of(Suggestions::OutdateService) do |service|
            expect(service).to receive(:execute).with(@fork_merge_request).and_call_original
          end

          refresh
        end
      end

      context 'closed fork merge request' do
        before do
          @fork_merge_request.close!
        end

        it 'do not execute hooks with update action' do
          refresh

          expect(refresh_service).not_to have_received(:execute_hooks)
        end

        it 'updates merge request to closed state' do
          refresh

          expect(@merge_request.notes).to be_empty
          expect(@merge_request).to be_open
          expect(@fork_merge_request.notes).to be_empty
          expect(@fork_merge_request).to be_closed
          expect(@build_failed_todo).to be_pending
          expect(@fork_build_failed_todo).to be_pending
        end
      end
    end

    context 'push to fork repo target branch' do
      describe 'changes to merge requests' do
        before do
          service.new(project: @fork_project, current_user: @user).execute(@oldrev, @newrev, 'refs/heads/feature')
          reload_mrs
        end

        it 'updates the merge request state' do
          expect(@merge_request.notes).to be_empty
          expect(@merge_request).to be_open
          expect(@fork_merge_request.notes).to be_empty
          expect(@fork_merge_request).to be_open
          expect(@build_failed_todo).to be_pending
          expect(@fork_build_failed_todo).to be_pending
        end
      end

      describe 'merge request diff' do
        it 'does not reload the diff of the merge request made from fork' do
          expect do
            service.new(project: @fork_project, current_user: @user).execute(@oldrev, @newrev, 'refs/heads/feature')
          end.not_to change { @fork_merge_request.reload.merge_request_diff }
        end
      end
    end

    context 'forked projects with the same source branch name as target branch' do
      let!(:first_commit) do
        @fork_project.repository.create_file(
          @user,
          'test1.txt',
          'Test data',
          message: 'Test commit',
          branch_name: 'master'
        )
      end

      let!(:second_commit) do
        @fork_project.repository.create_file(
          @user,
          'test2.txt',
          'More test data',
          message: 'Second test commit',
          branch_name: 'master'
        )
      end

      let!(:forked_master_mr) do
        create(
          :merge_request,
          source_project: @fork_project,
          source_branch: 'master',
          target_branch: 'master',
          target_project: @project
        )
      end

      let(:force_push_commit) { @project.commit('feature').id }

      it 'reloads a new diff for a push to the forked project' do
        expect do
          service.new(project: @fork_project, current_user: @user).execute(@oldrev, first_commit, 'refs/heads/master')
          reload_mrs
        end.to change { forked_master_mr.merge_request_diffs.count }.by(1)
      end

      it 'reloads a new diff for a force push to the source branch' do
        expect do
          service.new(project: @fork_project, current_user: @user).execute(@oldrev, force_push_commit, 'refs/heads/master')
          reload_mrs
        end.to change { forked_master_mr.merge_request_diffs.count }.by(1)
      end

      it 'reloads a new diff for a force push to the target branch' do
        expect do
          service.new(project: @project, current_user: @user).execute(@oldrev, force_push_commit, 'refs/heads/master')
          reload_mrs
        end.to change { forked_master_mr.merge_request_diffs.count }.by(1)
      end

      it 'reloads a new diff for a push to the target project that contains a commit in the MR' do
        expect do
          service.new(project: @project, current_user: @user).execute(@oldrev, first_commit, 'refs/heads/master')
          reload_mrs
        end.to change { forked_master_mr.merge_request_diffs.count }.by(1)
      end

      it 'does not increase the diff count for a new push to target branch' do
        new_commit = @project.repository.create_file(
          @user,
          'new-file.txt',
          'A new file',
          message: 'This is a test',
          branch_name: 'master'
        )

        expect do
          service.new(project: @project, current_user: @user).execute(@newrev, new_commit, 'refs/heads/master')
          reload_mrs
        end.not_to change { forked_master_mr.merge_request_diffs.count }
      end
    end

    context 'push to origin repo target branch after fork project was removed' do
      before do
        @fork_project.destroy!
        service.new(project: @project, current_user: @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it 'updates the merge request state' do
        expect(@merge_request.resource_state_events.last.state).to eq('merged')

        expect(@merge_request).to be_merged
        expect(@fork_merge_request).to be_open
        expect(@fork_merge_request.notes).to be_empty
        expect(@build_failed_todo).to be_done
        expect(@fork_build_failed_todo).to be_done
      end
    end

    context 'push new branch that exists in a merge request' do
      let(:refresh_service) { service.new(project: @fork_project, current_user: @user) }

      it 'refreshes the merge request' do
        expect(refresh_service).to receive(:execute_hooks)
                                       .with(@fork_merge_request, 'update', old_rev: Gitlab::Git::SHA1_BLANK_SHA)
        allow_any_instance_of(Repository).to receive(:merge_base).and_return(@oldrev)

        refresh_service.execute(Gitlab::Git::SHA1_BLANK_SHA, @newrev, 'refs/heads/master')
        reload_mrs

        expect(@merge_request.notes).to be_empty
        expect(@merge_request).to be_open

        notes = @fork_merge_request.notes.reorder(:created_at).map(&:note)
        expect(notes[0]).to include('restored source branch `master`')
        expect(notes[1]).to include('added 28 commits')
        expect(@fork_merge_request).to be_open
      end
    end

    context 'merge request metrics' do
      let(:user) { create(:user) }
      let(:project) { create(:project, :repository) }
      let(:issue) { create(:issue, project: project) }
      let(:commit) { project.commit }

      before do
        project.add_developer(user)

        allow(commit).to receive_messages(
          safe_message: "Closes #{issue.to_reference}",
          references: [issue],
          author_name: user.name,
          author_email: user.email,
          committed_date: Time.current
        )
      end

      context 'when the merge request is sourced from the same project' do
        it 'creates a `MergeRequestsClosingIssues` record for each issue closed by a commit' do
          allow_any_instance_of(MergeRequest).to receive(:commits).and_return(
            CommitCollection.new(project, [commit], 'close-by-commit')
          )

          merge_request = create(
            :merge_request,
            target_branch: 'master',
            source_branch: 'close-by-commit',
            source_project: project
          )

          refresh_service = service.new(project: project, current_user: user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/close-by-commit')

          expect(MergeRequestsClosingIssues.where(merge_request: merge_request)).to contain_exactly(
            have_attributes(issue_id: issue.id, from_mr_description: true)
          )
        end
      end

      context 'when the merge request is sourced from a different project' do
        it 'creates a `MergeRequestsClosingIssues` record for each issue closed by a commit' do
          forked_project = fork_project(project, user, repository: true)

          allow_any_instance_of(MergeRequest).to receive(:commits).and_return(
            CommitCollection.new(forked_project, [commit], 'close-by-commit')
          )

          merge_request = create(
            :merge_request,
            target_branch: 'master',
            target_project: project,
            source_branch: 'close-by-commit',
            source_project: forked_project
          )

          refresh_service = service.new(project: forked_project, current_user: user)
          allow(refresh_service).to receive(:execute_hooks)
          refresh_service.execute(@oldrev, @newrev, 'refs/heads/close-by-commit')

          expect(MergeRequestsClosingIssues.where(merge_request: merge_request)).to contain_exactly(
            have_attributes(issue_id: issue.id, from_mr_description: true)
          )
        end
      end
    end

    context 'marking the merge request as draft' do
      let(:refresh_service) { service.new(project: @project, current_user: @user) }

      before do
        allow(refresh_service).to receive(:execute_hooks)
      end

      it 'marks the merge request as draft from fixup commits' do
        fixup_merge_request = create(
          :merge_request,
          source_project: @project,
          source_branch: 'wip',
          target_branch: 'master',
          target_project: @project
        )
        commits = fixup_merge_request.commits
        oldrev = commits.last.id
        newrev = commits.first.id

        refresh_service.execute(oldrev, newrev, 'refs/heads/wip')
        fixup_merge_request.reload

        expect(fixup_merge_request.draft?).to eq(true)
        expect(fixup_merge_request.notes.last.note).to match(
          /marked this merge request as \*\*draft\*\* from #{Commit.reference_pattern}/
        )
      end

      it 'references the commit that caused the draft status' do
        draft_merge_request = create(
          :merge_request,
          source_project: @project,
          source_branch: 'wip',
          target_branch: 'master',
          target_project: @project
        )

        commits = draft_merge_request.commits
        oldrev = commits.last.id
        newrev = commits.first.id
        draft_commit = draft_merge_request.commits.find(&:draft?)

        refresh_service.execute(oldrev, newrev, 'refs/heads/wip')

        expect(draft_merge_request.reload.notes.last.note).to eq(
          "marked this merge request as **draft** from #{draft_commit.id}"
        )
      end

      it 'does not mark as draft based on commits that do not belong to an MR' do
        allow(refresh_service).to receive(:find_new_commits)

        refresh_service.instance_variable_set(:@commits,
          [
            double(
              id: 'aaaaaaa',
              sha: 'aaaaaaa',
              short_id: 'aaaaaaa',
              title: 'Fix issue',
              draft?: false
            ),
            double(
              id: 'bbbbbbb',
              sha: 'bbbbbbbb',
              short_id: 'bbbbbbb',
              title: 'fixup! Fix issue',
              draft?: true,
              to_reference: 'bbbbbbb'
            )
          ])

        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs

        expect(@merge_request.draft?).to be_falsey
      end
    end

    def reload_mrs
      @merge_request.reload
      @fork_merge_request.reload
      @build_failed_todo.reload
      @fork_build_failed_todo.reload
    end
  end

  describe 'updating merge_commit' do
    let(:service) { described_class.new(project: project, current_user: user) }
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }

    let(:oldrev) { TestEnv::BRANCH_SHA['merge-commit-analyze-before'] }
    let(:newrev) { TestEnv::BRANCH_SHA['merge-commit-analyze-after'] } # Pretend branch is now updated

    let!(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        source_branch: 'merge-commit-analyze-after',
        target_branch: 'merge-commit-analyze-before',
        target_project: project,
        merge_user: user
      )
    end

    let!(:merge_request_side_branch) do
      create(
        :merge_request,
        source_project: project,
        source_branch: 'merge-commit-analyze-side-branch',
        target_branch: 'merge-commit-analyze-before',
        target_project: project,
        merge_user: user
      )
    end

    subject { service.execute(oldrev, newrev, 'refs/heads/merge-commit-analyze-before') }

    context 'feature enabled' do
      it "updates merge requests' merge_commit and merged_commit values", :aggregate_failures do
        expect(Gitlab::BranchPushMergeCommitAnalyzer).to receive(:new).and_wrap_original do |original_method, commits|
          expect(commits.map(&:id)).to eq(%w[646ece5cfed840eca0a4feb21bcd6a81bb19bda3 29284d9bcc350bcae005872d0be6edd016e2efb5 5f82584f0a907f3b30cfce5bb8df371454a90051 8a994512e8c8f0dfcf22bb16df6e876be7a61036 689600b91aabec706e657e38ea706ece1ee8268f db46a1c5a5e474aa169b6cdb7a522d891bc4c5f9])

          original_method.call(commits)
        end

        subject

        merge_request.reload
        merge_request_side_branch.reload

        expect(merge_request.merge_commit.id).to eq('646ece5cfed840eca0a4feb21bcd6a81bb19bda3')
        expect(merge_request_side_branch.merge_commit.id).to eq('29284d9bcc350bcae005872d0be6edd016e2efb5')
        # we need to use read_attribute to bypass the overridden
        # #merged_commit_sha method, which contains a fallback to
        # #merge_commit_sha
        expect(merge_request.read_attribute(:merged_commit_sha)).to eq('646ece5cfed840eca0a4feb21bcd6a81bb19bda3')
        expect(merge_request_side_branch.read_attribute(:merged_commit_sha)).to eq('29284d9bcc350bcae005872d0be6edd016e2efb5')
      end
    end
  end

  describe '#abort_ff_merge_requests_with_auto_merges' do
    context 'when the auto megre strategy is MWCP' do
      it_behaves_like 'abort ff merge requests with auto merges' do
        let(:auto_merge_strategy) { AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS }
      end
    end

    context 'when auto merge strategy is MWPS' do
      it_behaves_like 'abort ff merge requests with auto merges' do
        let(:auto_merge_strategy) { AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS }
      end
    end
  end

  describe '#abort_auto_merges' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }
    let_it_be(:author) { user }

    let_it_be(:merge_request, refind: true) do
      create(
        :merge_request,
        source_project: project,
        target_project: project,
        merge_user: user,
        auto_merge_enabled: true,
        auto_merge_strategy: AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS
      )
    end

    let(:service) { described_class.new(project: project, current_user: user) }
    let(:oldrev) { merge_request.diff_refs.base_sha }
    let(:newrev) { merge_request.diff_refs.head_sha }
    let(:merge_sha) { oldrev }

    before do
      merge_request.merge_params[:sha] = merge_sha
      merge_request.save!

      service.execute(oldrev, newrev, "refs/heads/#{merge_request.source_branch}")

      merge_request.reload
    end

    it 'aborts auto merge for merge requests' do
      expect(merge_request.auto_merge_enabled?).to be_falsey
      expect(merge_request.merge_user).to be_nil
    end

    context 'when merge params contains up-to-date sha' do
      let(:merge_sha) { newrev }

      it 'maintains auto merge for merge requests' do
        expect(merge_request.auto_merge_enabled?).to be_truthy
        expect(merge_request.merge_user).to eq(user)
      end
    end
  end
end
