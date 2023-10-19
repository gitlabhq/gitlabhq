# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Refs::EnqueuePipelinesToUnlockService, :unlock_pipelines, :clean_gitlab_redis_shared_state, feature_category: :build_artifacts do
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

      let!(:other_ref_pipeline) { create_pipeline(:locked, other_ref, tag: false) }
      let!(:old_unlocked_pipeline) { create_pipeline(:unlocked, ref) }
      let!(:older_locked_pipeline_1) { create_pipeline(:locked, ref) }
      let!(:older_locked_pipeline_2) { create_pipeline(:locked, ref) }
      let!(:older_locked_pipeline_3) { create_pipeline(:locked, ref) }
      let!(:older_child_pipeline) { create_pipeline(:locked, ref, child_of: older_locked_pipeline_3) }
      let!(:pipeline) { create_pipeline(:locked, ref) }
      let!(:child_pipeline) { create_pipeline(:locked, ref, child_of: pipeline) }
      let!(:newer_pipeline) { create_pipeline(:locked, ref) }

      context 'when before_pipeline is given' do
        let(:before_pipeline) { pipeline }

        it 'only enqueues older locked pipelines within the ref' do
          expect { execute }
            .to change { pipeline_ids_waiting_to_be_unlocked }
            .from([])
            .to([
              older_locked_pipeline_1.id,
              older_locked_pipeline_2.id,
              older_locked_pipeline_3.id,
              older_child_pipeline.id
            ])

          expect(execute).to include(
            status: :success,
            total_pending_entries: 4,
            total_new_entries: 4
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
              older_locked_pipeline_1.id,
              older_locked_pipeline_2.id,
              older_locked_pipeline_3.id,
              older_child_pipeline.id,
              pipeline.id,
              child_pipeline.id,
              newer_pipeline.id
            ])

          expect(execute).to include(
            status: :success,
            total_pending_entries: 7,
            total_new_entries: 7
          )
        end
      end
    end

    context 'when ref is a tag' do
      let(:target_ref) { ci_ref_tag }

      it_behaves_like 'unlocking pipelines'
    end

    context 'when ref is a branch' do
      let(:target_ref) { ci_ref_branch }

      it_behaves_like 'unlocking pipelines'
    end

    def create_pipeline(type, ref, tag: is_tag, child_of: nil)
      trait = type == :locked ? :artifacts_locked : :unlocked
      create(:ci_pipeline, trait, ref: ref, tag: tag, project: project, child_of: child_of).tap do |p|
        if child_of
          build = create(:ci_build, pipeline: child_of)
          create(:ci_sources_pipeline, source_job: build, source_project: project, pipeline: p, project: project)
        end
      end
    end
  end
end
