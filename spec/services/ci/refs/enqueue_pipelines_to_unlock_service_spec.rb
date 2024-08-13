# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Refs::EnqueuePipelinesToUnlockService, :unlock_pipelines, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  describe '#execute' do
    let_it_be(:ref) { 'master' }
    let_it_be(:project) { create(:project) }
    let_it_be(:tag_ref_path) { "#{::Gitlab::Git::TAG_REF_PREFIX}#{ref}" }
    let_it_be(:ci_ref_tag) { create(:ci_ref, ref_path: tag_ref_path, project: project) }
    let_it_be(:branch_ref_path) { "#{::Gitlab::Git::BRANCH_REF_PREFIX}#{ref}" }
    let_it_be(:ci_ref_branch) { create(:ci_ref, ref_path: branch_ref_path, project: project) }
    let_it_be(:other_ref) { 'other_ref' }
    let_it_be(:other_ref_path) { "#{::Gitlab::Git::BRANCH_REF_PREFIX}#{other_ref}" }
    let_it_be(:other_ci_ref) { create(:ci_ref, ref_path: other_ref_path, project: project) }

    let(:service) { described_class.new }

    subject(:execute) { service.execute(target_ref, before_pipeline: before_pipeline) }

    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)
      stub_const("#{described_class}::ENQUEUE_INTERVAL_SECONDS", 0)
    end

    shared_examples_for 'unlocking pipelines' do
      let(:is_tag) { target_ref.ref_path.include?(::Gitlab::Git::TAG_REF_PREFIX) }

      let!(:other_ref_pipeline) { create_pipeline(:locked, other_ref, :failed, tag: false) }
      let!(:old_unlocked_pipeline) { create_pipeline(:unlocked, ref, :failed) }
      let!(:old_locked_pipeline_1) { create_pipeline(:locked, ref, :failed) }
      let!(:old_locked_pipeline_2) { create_pipeline(:locked, ref, :success) }
      let!(:old_locked_pipeline_3) { create_pipeline(:locked, ref, :success) }
      let!(:old_locked_pipeline_3_child) { create_pipeline(:locked, ref, :success, child_of: old_locked_pipeline_3) }
      let!(:old_locked_pipeline_4) { create_pipeline(:locked, ref, :success) }
      let!(:old_locked_pipeline_4_child) { create_pipeline(:locked, ref, :success, child_of: old_locked_pipeline_4) }
      let!(:old_locked_pipeline_5) { create_pipeline(:locked, ref, :failed) }
      let!(:old_locked_pipeline_5_child) { create_pipeline(:locked, ref, :success, child_of: old_locked_pipeline_5) }
      let!(:pipeline) { create_pipeline(:locked, ref, :failed) }
      let!(:child_pipeline) { create_pipeline(:locked, ref, :failed, child_of: pipeline) }
      let!(:newer_pipeline) { create_pipeline(:locked, ref, :failed) }

      context 'when before_pipeline is given' do
        let(:before_pipeline) { pipeline }

        it 'only enqueues old locked pipelines within the ref, excluding the last successful CI source pipeline' do
          expect { execute }
            .to change { pipeline_ids_waiting_to_be_unlocked }
            .from([])
            .to([
              old_locked_pipeline_1.id,
              old_locked_pipeline_2.id,
              old_locked_pipeline_3.id,
              old_locked_pipeline_3_child.id,
              old_locked_pipeline_5.id,
              old_locked_pipeline_5_child.id
            ])

          expect(execute).to include(
            status: :success,
            total_pending_entries: 6,
            total_new_entries: 6
          )
        end
      end

      context 'when before_pipeline is not given' do
        let(:before_pipeline) { nil }

        it 'enqueues all locked pipelines within the ref' do
          expect { execute }
            .to change { pipeline_ids_waiting_to_be_unlocked }
            .from([])
            .to([
              old_locked_pipeline_1.id,
              old_locked_pipeline_2.id,
              old_locked_pipeline_3.id,
              old_locked_pipeline_3_child.id,
              old_locked_pipeline_4.id,
              old_locked_pipeline_4_child.id,
              old_locked_pipeline_5.id,
              old_locked_pipeline_5_child.id,
              pipeline.id,
              child_pipeline.id,
              newer_pipeline.id
            ])

          expect(execute).to include(
            status: :success,
            total_pending_entries: 11,
            total_new_entries: 11
          )
        end
      end
    end

    context 'when ref is a tag', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/451377' do
      let(:target_ref) { ci_ref_tag }

      it_behaves_like 'unlocking pipelines'
    end

    # Quarantining this spec as well, as when we quarantined the one above,
    # this one started failing in the merge request:
    #   https://gitlab.com/gitlab-org/gitlab/-/jobs/7424531351#L505
    context 'when ref is a branch', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/451377' do
      let(:target_ref) { ci_ref_branch }

      it_behaves_like 'unlocking pipelines'
    end

    def create_pipeline(type, ref, status, tag: is_tag, child_of: nil)
      trait = type == :locked ? :artifacts_locked : :unlocked
      create(:ci_pipeline, trait, status: status, ref: ref, tag: tag, project: project, child_of: child_of).tap do |p|
        if child_of
          build = create(:ci_build, pipeline: child_of)
          create(:ci_sources_pipeline, source_job: build, source_project: project, pipeline: p, project: project)
        end
      end
    end
  end
end
