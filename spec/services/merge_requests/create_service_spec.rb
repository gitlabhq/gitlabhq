# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreateService, :clean_gitlab_redis_shared_state, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include AfterNextHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  describe '#execute' do
    context 'valid params' do
      let(:opts) do
        {
          title: 'Awesome merge_request',
          description: 'please fix',
          source_branch: 'feature',
          target_branch: 'master',
          force_remove_source_branch: '1'
        }
      end

      let(:service) { described_class.new(project: project, current_user: user, params: opts) }
      let(:merge_request) { service.execute }

      before do
        project.add_maintainer(user)
        project.add_developer(user2)
      end

      it 'creates an MR' do
        expect(merge_request).to be_valid
        expect(merge_request.draft?).to be(false)
        expect(merge_request.title).to eq('Awesome merge_request')
        expect(merge_request.assignees).to be_empty
        expect(merge_request.merge_params['force_remove_source_branch']).to eq('1')
      end

      it 'does not execute hooks' do
        expect(project).not_to receive(:execute_hooks)

        service.execute
      end

      it 'refreshes the number of open merge requests', :use_clean_rails_memory_store_caching do
        expect do
          service.execute

          BatchLoader::Executor.clear_current
        end.to change { project.open_merge_requests_count }.from(0).to(1)
      end

      it 'creates exactly 1 create MR event', :sidekiq_inline do
        attributes = {
          action: :created,
          target_id: merge_request.id,
          target_type: merge_request.class.name
        }

        expect(Event.where(attributes).count).to eq(1)
      end

      it 'sets the merge_status to preparing' do
        expect(merge_request.reload).to be_preparing
      end

      describe 'checking for spam' do
        it 'checks for spam' do
          expect_next_instance_of(MergeRequest) do |instance|
            expect(instance).to receive(:check_for_spam).with(user: user, action: :create)
          end

          service.execute
        end

        it 'does not persist when spam' do
          allow_next_instance_of(MergeRequest) do |instance|
            allow(instance).to receive(:spam?).and_return(true)
          end

          expect(merge_request).not_to be_persisted
        end
      end

      describe 'when marked with /draft' do
        context 'in title and in description' do
          let(:opts) do
            {
              title: 'Draft: Awesome merge_request',
              description: "well this is not done yet\n/draft",
              source_branch: 'feature',
              target_branch: 'master',
              assignees: [user2]
            }
          end

          it 'sets MR to draft' do
            expect(merge_request.draft?).to be(true)
          end
        end

        context 'in description only' do
          let(:opts) do
            {
              title: 'Awesome merge_request',
              description: "well this is not done yet\n/draft",
              source_branch: 'feature',
              target_branch: 'master',
              assignees: [user2]
            }
          end

          it 'sets MR to draft' do
            expect(merge_request.draft?).to be(true)
          end
        end
      end

      context 'when merge request is assigned to someone' do
        let(:opts) do
          {
            title: 'Awesome merge_request',
            description: 'please fix',
            source_branch: 'feature',
            target_branch: 'master',
            assignee_ids: [user2.id]
          }
        end

        it { expect(merge_request.assignees).to eq([user2]) }
      end

      context 'when reviewer is assigned' do
        let(:opts) do
          {
            title: 'Awesome merge_request',
            description: 'please fix',
            source_branch: 'feature',
            target_branch: 'master',
            reviewers: [user2]
          }
        end

        it { expect(merge_request.reviewers).to eq([user2]) }

        it 'invalidates counter cache for reviewers', :use_clean_rails_memory_store_caching do
          expect { merge_request }
            .to change { user2.review_requested_open_merge_requests_count }
            .by(1)
        end
      end

      context 'when head pipelines already exist for merge request source branch', :sidekiq_inline do
        let(:shas) { project.repository.commits(opts[:source_branch], limit: 2).map(&:id) }
        let!(:pipeline_1) { create(:ci_pipeline, project: project, ref: opts[:source_branch], project_id: project.id, sha: shas[1]) }
        let!(:pipeline_2) { create(:ci_pipeline, project: project, ref: opts[:source_branch], project_id: project.id, sha: shas[0]) }
        let!(:pipeline_3) { create(:ci_pipeline, project: project, ref: "other_branch", project_id: project.id) }

        before do
          # rubocop: disable Cop/DestroyAll
          project.merge_requests
            .where(source_branch: opts[:source_branch], target_branch: opts[:target_branch])
            .destroy_all
          # rubocop: enable Cop/DestroyAll
        end

        it 'sets head pipeline' do
          merge_request = service.execute

          expect(merge_request.reload.head_pipeline).to eq(pipeline_2)
          expect(merge_request).to be_persisted
        end

        context 'when the new pipeline is associated with an old sha' do
          let!(:pipeline_1) { create(:ci_pipeline, project: project, ref: opts[:source_branch], project_id: project.id, sha: shas[0]) }
          let!(:pipeline_2) { create(:ci_pipeline, project: project, ref: opts[:source_branch], project_id: project.id, sha: shas[1]) }

          it 'sets an old pipeline with associated with the latest sha as the head pipeline' do
            merge_request = service.execute

            expect(merge_request.reload.head_pipeline).to eq(pipeline_1)
            expect(merge_request).to be_persisted
          end
        end

        context 'when there are no pipelines with the diff head sha' do
          let!(:pipeline_1) { create(:ci_pipeline, project: project, ref: opts[:source_branch], project_id: project.id, sha: shas[1]) }
          let!(:pipeline_2) { create(:ci_pipeline, project: project, ref: opts[:source_branch], project_id: project.id, sha: shas[1]) }

          it 'does not set the head pipeline' do
            merge_request = service.execute

            expect(merge_request.reload.head_pipeline).to be_nil
            expect(merge_request).to be_persisted
          end
        end
      end

      describe 'Pipelines for merge requests', :sidekiq_inline do
        before do
          stub_ci_pipeline_yaml_file(config)
        end

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

          it 'creates a detached merge request pipeline and sets it as a head pipeline' do
            expect(merge_request).to be_persisted

            merge_request.reload
            expect(merge_request.pipelines_for_merge_request.count).to eq(1)
            expect(merge_request.diff_head_pipeline).to be_detached_merge_request_pipeline
          end

          context 'when merge request is submitted from forked project' do
            let(:target_project) { fork_project(project, nil, repository: true) }

            let(:opts) do
              {
                title: 'Awesome merge_request',
                source_branch: 'feature',
                target_branch: 'master',
                target_project_id: target_project.id
              }
            end

            before do
              target_project.add_developer(user2)
              target_project.add_maintainer(user)
            end

            it 'create detached merge request pipeline for fork merge request' do
              merge_request.reload

              head_pipeline = merge_request.diff_head_pipeline
              expect(head_pipeline).to be_detached_merge_request_pipeline
              expect(head_pipeline.project).to eq(target_project)
            end
          end

          context 'when there are no commits between source branch and target branch' do
            let(:opts) do
              {
                title: 'Awesome merge_request',
                description: 'please fix',
                source_branch: 'not-merged-branch',
                target_branch: 'master'
              }
            end

            it 'does not create a detached merge request pipeline' do
              expect(merge_request).to be_persisted

              merge_request.reload
              expect(merge_request.pipelines_for_merge_request.count).to eq(0)
            end
          end

          context "when branch pipeline was created before a merge request pipline has been created" do
            before do
              create(
                :ci_pipeline,
                project: merge_request.source_project,
                sha: merge_request.diff_head_sha,
                ref: merge_request.source_branch,
                tag: false
              )

              merge_request
            end

            it 'sets the latest detached merge request pipeline as the head pipeline' do
              merge_request.reload

              expect(merge_request.diff_head_pipeline).to be_merge_request_event
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
            expect(merge_request).to be_persisted

            merge_request.reload
            expect(merge_request.pipelines_for_merge_request.count).to eq(0)
          end
        end

        context 'when .gitlab-ci.yml is invalid' do
          let(:config) { 'invalid yaml file' }

          it 'persists a pipeline with config error' do
            expect(merge_request).to be_persisted

            merge_request.reload
            expect(merge_request.pipelines_for_merge_request.count).to eq(1)
            expect(merge_request.pipelines_for_merge_request.last).to be_failed
            expect(merge_request.pipelines_for_merge_request.last).to be_config_error
          end
        end
      end

      context 'after_save callback to store_mentions' do
        let(:labels) { create_pair(:label, project: project) }
        let(:milestone) { create(:milestone, project: project) }
        let(:req_opts) { { source_branch: 'feature', target_branch: 'master' } }

        context 'when mentionable attributes change' do
          let(:opts) { { title: 'Title', description: "Description with #{user.to_reference}" }.merge(req_opts) }

          it 'saves mentions' do
            expect_next_instance_of(MergeRequest) do |instance|
              expect(instance).to receive(:store_mentions!).and_call_original
            end
            expect(merge_request.user_mentions.count).to eq 1
          end
        end

        context 'when mentionable attributes do not change' do
          let(:opts) { { label_ids: labels.map(&:id), milestone_id: milestone.id }.merge(req_opts) }

          it 'does not call store_mentions' do
            expect_next_instance_of(MergeRequest) do |instance|
              expect(instance).not_to receive(:store_mentions!).and_call_original
            end
            expect(merge_request.valid?).to be false
            expect(merge_request.user_mentions.count).to eq 0
          end
        end

        context 'when save fails' do
          let(:opts) { { label_ids: labels.map(&:id), milestone_id: milestone.id } }

          it 'does not call store_mentions' do
            expect_next_instance_of(MergeRequest) do |instance|
              expect(instance).not_to receive(:store_mentions!).and_call_original
            end
            expect(merge_request.valid?).to be false
          end
        end
      end

      context 'with a milestone' do
        let(:milestone) { create(:milestone, project: project) }

        let(:opts) { { title: 'Awesome merge_request', source_branch: 'feature', target_branch: 'master', milestone_id: milestone.id } }

        it 'deletes the cache key for milestone merge request counter' do
          expect_next(Milestones::MergeRequestsCountService, milestone)
            .to receive(:delete_cache).and_call_original

          expect(merge_request).to be_persisted
        end
      end

      it_behaves_like 'reviewer_ids filter' do
        let(:execute) { service.execute }
      end

      context 'when called in a transaction' do
        it 'does not raise an error' do
          expect { MergeRequest.transaction { described_class.new(project: project, current_user: user, params: opts).execute } }.not_to raise_error
        end
      end
    end

    it_behaves_like 'issuable record that supports quick actions' do
      let(:default_params) do
        {
          source_branch: 'feature',
          target_branch: 'master'
        }
      end

      let(:issuable) do
        described_class.new(project: project, current_user: user, params: params.merge(default_params)).execute
      end
    end

    context 'Quick actions' do
      context 'with assignee and milestone in params and command' do
        let(:merge_request) { described_class.new(project: project, current_user: user, params: opts).execute }
        let(:milestone) { create(:milestone, project: project) }

        let(:opts) do
          {
            assignee_ids: create(:user).id,
            milestone_id: 1,
            title: 'Title',
            description: %(/assign @#{user2.username}\n/milestone %"#{milestone.name}"),
            source_branch: 'feature',
            target_branch: 'master'
          }
        end

        before do
          project.add_maintainer(user)
          project.add_maintainer(user2)
        end

        it 'assigns and sets milestone to issuable from command' do
          expect(merge_request).to be_persisted
          expect(merge_request.assignees).to eq([user2])
          expect(merge_request.milestone).to eq(milestone)
        end
      end
    end

    context 'merge request create service' do
      context 'asssignee_id' do
        let(:user2) { create(:user) }

        before do
          project.add_maintainer(user)
        end

        it 'removes assignee_id when user id is invalid' do
          opts = { title: 'Title', description: 'Description', assignee_ids: [-1] }

          merge_request = described_class.new(project: project, current_user: user, params: opts).execute

          expect(merge_request.assignee_ids).to be_empty
        end

        it 'removes assignee_id when user id is 0' do
          opts = { title: 'Title', description: 'Description', assignee_ids: [0] }

          merge_request = described_class.new(project: project, current_user: user, params: opts).execute

          expect(merge_request.assignee_ids).to be_empty
        end

        it 'saves assignee when user id is valid' do
          project.add_maintainer(user2)
          opts = { title: 'Title', description: 'Description', assignee_ids: [user2.id] }

          merge_request = described_class.new(project: project, current_user: user, params: opts).execute

          expect(merge_request.assignees).to eq([user2])
        end

        context 'when assignee is set' do
          let(:opts) do
            {
              title: 'Title',
              description: 'Description',
              assignee_ids: [user2.id],
              source_branch: 'feature',
              target_branch: 'master'
            }
          end

          before do
            project.add_maintainer(user2)
          end

          it 'invalidates open merge request counter for assignees when merge request is assigned' do
            described_class.new(project: project, current_user: user, params: opts).execute

            expect(user2.assigned_open_merge_requests_count).to eq 1
          end

          it 'records the assignee assignment event', :sidekiq_inline do
            mr = described_class.new(project: project, current_user: user, params: opts).execute.reload

            expect(mr.assignment_events).to match([have_attributes(user_id: user2.id, action: 'add')])
          end
        end

        context "when issuable feature is private" do
          before do
            project.project_feature.update!(
              issues_access_level: ProjectFeature::PRIVATE,
              merge_requests_access_level: ProjectFeature::PRIVATE
            )
          end

          levels = [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC]

          levels.each do |level|
            it "removes not authorized assignee when project is #{Gitlab::VisibilityLevel.level_name(level)}" do
              project.update!(visibility_level: level)
              opts = { title: 'Title', description: 'Description', assignee_ids: [user2.id] }

              merge_request = described_class.new(project: project, current_user: user, params: opts).execute

              expect(merge_request.assignee_id).to be_nil
            end
          end
        end
      end
    end

    shared_examples 'when source and target projects are different' do
      let(:target_project) { fork_project(project, nil, repository: true) }

      let(:opts) do
        {
          title: 'Awesome merge_request',
          source_branch: 'feature',
          target_branch: 'master',
          target_project_id: target_project.id
        }
      end

      context 'when user can not access source project' do
        before do
          target_project.add_developer(user2)
          target_project.add_maintainer(user)
        end

        it 'raises an error' do
          expect { described_class.new(project: project, current_user: user, params: opts).execute }
            .to raise_error Gitlab::Access::AccessDeniedError
        end
      end

      context 'when user can not access target project' do
        before do
          target_project.add_developer(user2)
          target_project.add_maintainer(user)
        end

        it 'raises an error' do
          expect { described_class.new(project: project, current_user: user, params: opts).execute }
            .to raise_error Gitlab::Access::AccessDeniedError
        end
      end

      context 'when the user has access to both projects' do
        before do
          target_project.add_developer(user)
          project.add_developer(user)
        end

        it 'creates the merge request', :sidekiq_inline do
          merge_request = described_class.new(project: project, current_user: user, params: opts).execute

          expect(merge_request).to be_persisted
          expect(merge_request.iid).to be > 0
          expect(merge_request.merge_request_diff).not_to be_empty
        end

        it 'does not create the merge request when the target project is archived' do
          target_project.update!(archived: true)

          expect { described_class.new(project: project, current_user: user, params: opts).execute }
            .to raise_error Gitlab::Access::AccessDeniedError
        end
      end
    end

    it_behaves_like 'when source and target projects are different'

    context 'when user sets source project id' do
      let(:another_project) { create(:project) }

      let(:opts) do
        {
          title: 'Awesome merge_request',
          source_branch: 'feature',
          target_branch: 'master',
          source_project_id: another_project.id
        }
      end

      before do
        project.add_developer(user2)
        project.add_maintainer(user)
      end

      it 'ignores source_project_id' do
        merge_request = described_class.new(project: project, current_user: user, params: opts).execute

        expect(merge_request.source_project_id).to eq(project.id)
      end
    end
  end
end
