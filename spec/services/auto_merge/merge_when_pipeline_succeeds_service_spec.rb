# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMerge::MergeWhenPipelineSucceedsService, feature_category: :code_review_workflow do
  include_context 'for auto_merge strategy context'

  describe "#available_for?" do
    subject { service.available_for?(mr_merge_if_green_enabled) }

    let(:pipeline_status) { :running }

    before do
      create(
        :ci_pipeline,
        pipeline_status,
        ref: mr_merge_if_green_enabled.source_branch,
        sha: mr_merge_if_green_enabled.diff_head_sha,
        project: mr_merge_if_green_enabled.source_project
      )
      mr_merge_if_green_enabled.update_head_pipeline
    end

    it { is_expected.to be_falsey }

    context 'when the head pipeline succeeded' do
      let(:pipeline_status) { :success }

      it { is_expected.to be_falsy }
    end

    context 'when the user does not have permission to merge' do
      before do
        allow(mr_merge_if_green_enabled).to receive(:can_be_merged_by?) { false }
      end

      it { is_expected.to be_falsy }
    end
  end

  describe "#execute" do
    it_behaves_like 'auto_merge service #execute', 'merge_when_pipeline_succeeds' do
      let(:auto_merge_strategy) { AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS }
      let(:expected_note) do
        "enabled an automatic merge when the pipeline for #{pipeline.sha}"
      end
    end
  end

  describe "#process" do
    it_behaves_like 'auto_merge service #process'
  end

  describe '#cancel' do
    it_behaves_like 'auto_merge service #cancel'
  end

  describe '#abort' do
    it_behaves_like 'auto_merge service #abort'
  end

  describe 'pipeline integration' do
    context 'when there are multiple stages in the pipeline' do
      let(:ref) { mr_merge_if_green_enabled.source_branch }
      let(:sha) { project.commit(ref).id }

      let(:build_stage) { create(:ci_stage, name: 'build', pipeline: pipeline) }

      let(:pipeline) do
        create(:ci_empty_pipeline, ref: ref, sha: sha, project: project)
      end

      let!(:build) do
        create(
          :ci_build,
          :created,
          pipeline: pipeline,
          ref: ref,
          name: 'build',
          ci_stage: build_stage
        )
      end

      let!(:test) do
        create(:ci_build, :created, pipeline: pipeline, ref: ref, name: 'test')
      end

      before do
        # This behavior of MergeRequest: we instantiate a new object
        #
        allow_any_instance_of(MergeRequest)
          .to receive(:head_pipeline)
          .and_wrap_original do
            Ci::Pipeline.find(pipeline.id)
          end
      end

      it "doesn't merge if any of stages failed" do
        expect(MergeWorker).not_to receive(:perform_async)

        build.success
        test.reload
        test.drop
      end

      it 'merges when all stages succeeded', :sidekiq_might_not_need_inline do
        expect(MergeWorker).to receive(:perform_async)

        build.success
        test.reload
        test.success
      end
    end
  end
end
