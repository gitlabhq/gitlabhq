# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::ProcessRefChangesService, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:user) { project.first_owner }
  let(:params) { { changes: git_changes } }

  subject { described_class.new(project, user, params) }

  shared_examples_for 'service for processing ref changes' do |push_service_class|
    let(:service) { double(execute: true) }
    let(:git_changes) { double(branch_changes: [], tag_changes: []) }

    def multiple_changes(change, count)
      Array.new(count).map.with_index do |n, index|
        { index: index, oldrev: change[:oldrev], newrev: change[:newrev], ref: "#{change[:ref]}#{n}" }
      end
    end

    let(:changes) do
      [
        { index: 0, oldrev: Gitlab::Git::SHA1_BLANK_SHA, newrev: '789012', ref: "#{ref_prefix}/create" },
        { index: 1, oldrev: '123456', newrev: '789012', ref: "#{ref_prefix}/update" },
        { index: 2, oldrev: '123456', newrev: Gitlab::Git::SHA1_BLANK_SHA, ref: "#{ref_prefix}/delete" }
      ]
    end

    before do
      allow(git_changes).to receive(changes_method).and_return(changes)
    end

    it "calls #{push_service_class}" do
      expect(push_service_class)
        .to receive(:new)
        .with(project, project.first_owner, hash_including(execute_project_hooks: true, create_push_event: true))
        .exactly(changes.count).times
        .and_return(service)

      subject.execute
    end

    context 'when BranchPushService' do
      it 'calls BranchPushService with process_commit_worker_pool' do
        next unless push_service_class == Git::BranchPushService

        expect(push_service_class)
          .to receive(:new)
          .with(anything, anything, hash_including(
            process_commit_worker_pool: a_kind_of(Gitlab::Git::ProcessCommitWorkerPool)
          )).exactly(changes.count).times
            .and_return(service)

        subject.execute
      end
    end

    context 'changes exceed push_event_hooks_limit' do
      let(:push_event_hooks_limit) { 3 }

      let(:changes) do
        multiple_changes(
          { oldrev: '123456', newrev: '789012', ref: "#{ref_prefix}/test" },
          push_event_hooks_limit + 1
        )
      end

      before do
        stub_application_setting(push_event_hooks_limit: push_event_hooks_limit)
      end

      it "calls #{push_service_class} with execute_project_hooks set to false" do
        expect(push_service_class)
          .to receive(:new)
          .with(project, project.first_owner, hash_including(execute_project_hooks: false))
          .exactly(changes.count).times
          .and_return(service)

        subject.execute
      end
    end

    context 'changes exceed push_event_activities_limit per action' do
      let(:push_event_activities_limit) { 3 }

      let(:changes) do
        [
          { oldrev: Gitlab::Git::SHA1_BLANK_SHA, newrev: '789012', ref: "#{ref_prefix}/create" },
          { oldrev: '123456', newrev: '789012', ref: "#{ref_prefix}/update" },
          { oldrev: '123456', newrev: Gitlab::Git::SHA1_BLANK_SHA, ref: "#{ref_prefix}/delete" }
        ].flat_map do |change|
          multiple_changes(change, push_event_activities_limit + 1)
        end
      end

      before do
        stub_application_setting(push_event_activities_limit: push_event_activities_limit)
      end

      it "calls #{push_service_class} with create_push_event set to false" do
        expect(push_service_class)
          .to receive(:new)
          .with(project, project.first_owner, hash_including(create_push_event: false))
          .exactly(changes.count).times
          .and_return(service)

        subject.execute
      end

      it 'creates events per action' do
        allow(push_service_class).to receive(:new).and_return(service)

        expect { subject.execute }.to change { Event.count }.by(3)
      end
    end

    context 'pipeline creation' do
      context 'with valid .gitlab-ci.yml' do
        before do
          stub_ci_pipeline_to_return_yaml_file

          allow_any_instance_of(Project)
            .to receive(:commit)
            .and_return(project.commit)

          if changes_method == :branch_changes
            allow_any_instance_of(Repository).to receive(:branch_exists?) { true }
          end

          if changes_method == :tag_changes
            allow_any_instance_of(Repository).to receive(:tag_exists?) { true }
          end

          allow(Gitlab::Git::Commit).to receive(:between) { [] }
        end

        context 'when git_push_create_all_pipelines is disabled' do
          before do
            stub_feature_flags(git_push_create_all_pipelines: false)
          end

          it 'creates pipeline for branches and tags' do
            subject.execute

            # We don't run a pipeline for a deletion
            expect(Ci::Pipeline.pluck(:ref)).to contain_exactly('create', 'update')
          end

          it "creates exactly #{described_class::PIPELINE_PROCESS_LIMIT} pipelines" do
            stub_const("#{described_class}::PIPELINE_PROCESS_LIMIT", changes.count - 1)

            # We expect some logs from Gitlab::Ci::Pipeline::CommandLogger,
            # but no logs from warn_if_over_process_limit
            expect(Gitlab::AppJsonLogger).to receive(:info).with(
              hash_including("class" => "Gitlab::Ci::Pipeline::CommandLogger")
            ).twice

            expect { subject.execute }.to change { Ci::Pipeline.count }.by(described_class::PIPELINE_PROCESS_LIMIT)
          end
        end

        context 'when git_push_create_all_pipelines is enabled' do
          before do
            stub_feature_flags(git_push_create_all_pipelines: true)
          end

          it 'creates all pipelines' do
            # We don't run a pipeline for a deletion
            expect { subject.execute }.to change { Ci::Pipeline.count }.by(changes.count - 1)
          end
        end
      end

      context 'with invalid .gitlab-ci.yml' do
        before do
          stub_ci_pipeline_yaml_file(nil)

          allow(Gitlab::Git::Commit).to receive(:between) { [] }
        end

        it 'does not create a pipeline' do
          expect { subject.execute }.not_to change { Ci::Pipeline.count }
        end
      end
    end

    describe "housekeeping", :clean_gitlab_redis_cache, :clean_gitlab_redis_queues, :clean_gitlab_redis_shared_state do
      let(:housekeeping) { ::Repositories::HousekeepingService.new(project) }

      before do
        allow(::Repositories::HousekeepingService).to receive(:new).and_return(housekeeping)

        allow(push_service_class)
          .to receive(:new)
          .with(project, project.first_owner, hash_including(execute_project_hooks: true, create_push_event: true))
          .exactly(changes.count).times
          .and_return(service)
      end

      it 'does not perform housekeeping when not needed' do
        expect(housekeeping).not_to receive(:execute)

        subject.execute
      end

      context 'when housekeeping is needed' do
        before do
          allow(housekeeping).to receive(:needed?).and_return(true)
        end

        it 'performs housekeeping' do
          expect(housekeeping).to receive(:execute)

          subject.execute
        end

        it 'does not raise an exception' do
          allow(housekeeping).to receive(:try_obtain_lease).and_return(false)

          subject.execute
        end
      end

      it 'increments the push counter' do
        expect(housekeeping).to receive(:increment!)

        subject.execute
      end
    end
  end

  context 'branch changes' do
    let(:changes_method) { :branch_changes }
    let(:ref_prefix) { 'refs/heads' }

    it_behaves_like 'service for processing ref changes', Git::BranchPushService

    context 'when there are merge requests associated with branches' do
      let(:tag_changes) do
        [
          { index: 7, oldrev: Gitlab::Git::SHA1_BLANK_SHA, newrev: '789012', ref: "refs/tags/v10.0.0" }
        ]
      end

      let(:branch_changes) do
        [
          { index: 0, oldrev: Gitlab::Git::SHA1_BLANK_SHA, newrev: '789012', ref: "#{ref_prefix}/create1" },
          { index: 1, oldrev: Gitlab::Git::SHA1_BLANK_SHA, newrev: '789013', ref: "#{ref_prefix}/create2" },
          { index: 2, oldrev: Gitlab::Git::SHA1_BLANK_SHA, newrev: '789014', ref: "#{ref_prefix}/create3" },
          { index: 3, oldrev: '789015', newrev: '789016', ref: "#{ref_prefix}/changed1" },
          { index: 4, oldrev: '789017', newrev: '789018', ref: "#{ref_prefix}/changed2" },
          { index: 5, oldrev: '789019', newrev: Gitlab::Git::SHA1_BLANK_SHA, ref: "#{ref_prefix}/removed1" },
          { index: 6, oldrev: '789020', newrev: Gitlab::Git::SHA1_BLANK_SHA, ref: "#{ref_prefix}/removed2" }
        ]
      end

      let(:git_changes) do
        double(branch_changes: branch_changes, tag_changes: tag_changes)
      end

      before do
        allow(MergeRequests::PushedBranchesService).to receive(:new).and_return(
          double(execute: %w[create1 create2]), double(execute: %w[changed1]), double(execute: %w[removed2])
        )

        allow(Gitlab::Git::Commit).to receive(:between).and_return([])
      end

      it 'schedules job for existing merge requests' do
        expect(UpdateMergeRequestsWorker).to receive(:perform_async).with(
          project.id,
          user.id,
          Gitlab::Git::SHA1_BLANK_SHA,
          '789012',
          "#{ref_prefix}/create1",
          { 'push_options' => nil }).ordered

        expect(UpdateMergeRequestsWorker).to receive(:perform_async).with(
          project.id,
          user.id,
          Gitlab::Git::SHA1_BLANK_SHA,
          '789013',
          "#{ref_prefix}/create2",
          { 'push_options' => nil }).ordered

        expect(UpdateMergeRequestsWorker).to receive(:perform_async).with(
          project.id,
          user.id,
          '789015',
          '789016',
          "#{ref_prefix}/changed1",
          { 'push_options' => nil }).ordered

        expect(UpdateMergeRequestsWorker).to receive(:perform_async).with(
          project.id,
          user.id,
          '789020',
          Gitlab::Git::SHA1_BLANK_SHA,
          "#{ref_prefix}/removed2",
          { 'push_options' => nil }).ordered

        subject.execute
      end

      context 'when git_push_create_all_pipelines is disabled' do
        before do
          stub_feature_flags(git_push_create_all_pipelines: false)
        end

        it 'logs a warning' do
          allow(Gitlab::AppJsonLogger).to receive(:info).and_call_original

          expect(Gitlab::AppJsonLogger).to receive(:info).with(
            hash_including(
              message: "Some pipelines may not have been created because ref count exceeded limit",
              ref_limit: described_class::PIPELINE_PROCESS_LIMIT,
              total_ref_count: branch_changes.count + tag_changes.count,
              possible_omitted_refs: ["#{ref_prefix}/changed2", "refs/tags/v10.0.0"],
              possible_omitted_ref_count: 2
            )
          )

          subject.execute
        end
      end
    end
  end

  context 'tag changes' do
    let(:changes_method) { :tag_changes }
    let(:ref_prefix) { 'refs/tags' }

    it_behaves_like 'service for processing ref changes', Git::TagPushService
  end
end
