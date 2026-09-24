# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RedundantPipelines::AutoCancelPolicy, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project) }

  let(:auto_cancel_on_new_commit) { 'conservative' }

  let(:interruptible_protected) { false }

  let(:pipeline) { stub_pipeline }

  subject(:policy) { described_class.new(pipeline) }

  # auto_cancel_on_new_commit lives on the pipeline metadata, while the protection a
  # started job records lives on the processing data.
  def stub_pipeline(source: :push)
    build_stubbed(:ci_pipeline, project: project, source: source).tap do |pipeline|
      pipeline.pipeline_metadata = build_stubbed(
        :ci_pipeline_metadata,
        project: project,
        pipeline: pipeline,
        auto_cancel_on_new_commit: auto_cancel_on_new_commit
      )

      pipeline.pipeline_processing_data = build_stubbed(
        :ci_pipeline_processing_data,
        pipeline: pipeline,
        interruptible_protected: interruptible_protected
      )
    end
  end

  describe '#applies?' do
    it 'applies to an ordinary pipeline' do
      expect(policy.applies?).to be(true)
    end

    context 'when auto-cancel is disabled for the project' do
      before do
        project.update!(auto_cancel_pending_pipelines: 'disabled')
      end

      it { expect(policy.applies?).to be(false) }
    end

    context 'when the service is disabled for the project' do
      before do
        stub_feature_flags(disable_cancel_redundant_pipelines_service: true)
      end

      it { expect(policy.applies?).to be(false) }
    end

    context 'when the redis candidates flag is disabled' do
      before do
        stub_feature_flags(ci_redundant_pipeline_candidates_cache: false)
      end

      it { expect(policy.applies?).to be(false) }
    end

    context 'when the pipeline is a child pipeline' do
      let(:pipeline) { build_stubbed(:ci_pipeline, project: project, source: :parent_pipeline) }

      it { expect(policy.applies?).to be(false) }
    end

    context 'when the pipeline source does not affect the ref' do
      let(:pipeline) { build_stubbed(:ci_pipeline, :webide, project: project) }

      it { expect(policy.applies?).to be(false) }
    end
  end

  describe '#cancel_mode' do
    where(:auto_cancel_on_new_commit, :interruptible_protected, :source, :cancel_mode) do
      'conservative'  | false | :push            | :all
      'conservative'  | true  | :push            | nil
      'interruptible' | false | :push            | :interruptible
      'interruptible' | true  | :push            | :interruptible
      'none'          | false | :push            | nil
      'none'          | true  | :push            | nil
      'conservative'  | false | :parent_pipeline | :all
      'conservative'  | true  | :parent_pipeline | nil
      'interruptible' | false | :parent_pipeline | :interruptible
      'none'          | false | :parent_pipeline | nil
    end

    with_them do
      let(:pipeline) { stub_pipeline(source: source) }

      it 'says how auto-cancellation may cancel the pipeline' do
        expect(policy.cancel_mode).to eq(cancel_mode)
      end
    end

    context 'when auto-cancel is disabled for the project' do
      before do
        project.update!(auto_cancel_pending_pipelines: 'disabled')
      end

      it 'cancels nothing' do
        expect(policy.cancel_mode).to be_nil
      end
    end
  end

  describe '#cancelable_by_newer_pipeline?' do
    it 'is cancelable by default' do
      expect(policy).to be_cancelable_by_newer_pipeline
    end

    context 'when the pipeline has no metadata' do
      let(:pipeline) { build_stubbed(:ci_pipeline, project: project) }

      it 'falls back to the conservative default' do
        expect(policy).to be_cancelable_by_newer_pipeline
      end
    end

    context 'when it may not be cancelled' do
      let(:auto_cancel_on_new_commit) { 'none' }

      it { is_expected.not_to be_cancelable_by_newer_pipeline }
    end

    context 'when auto-cancel does not apply to it on its own' do
      let(:pipeline) { stub_pipeline(source: :parent_pipeline) }

      it { is_expected.not_to be_cancelable_by_newer_pipeline }
    end
  end

  describe '#protected_after_non_interruptible_job_starts?' do
    it 'is protected for a conservative pipeline' do
      expect(policy).to be_protected_after_non_interruptible_job_starts
    end

    context 'when the pipeline only cancels interruptible jobs' do
      let(:auto_cancel_on_new_commit) { 'interruptible' }

      it 'stays cancellable however far its jobs get' do
        expect(policy).not_to be_protected_after_non_interruptible_job_starts
      end
    end

    context 'when the pipeline is configured to never be auto-cancelled' do
      let(:auto_cancel_on_new_commit) { 'none' }

      it { is_expected.not_to be_protected_after_non_interruptible_job_starts }
    end

    context 'when the pipeline is already protected' do
      let(:interruptible_protected) { true }

      it { is_expected.to be_protected_after_non_interruptible_job_starts }
    end

    context 'when the pipeline is a child pipeline' do
      let(:pipeline) { stub_pipeline(source: :parent_pipeline) }

      it { is_expected.to be_protected_after_non_interruptible_job_starts }

      context 'when it is configured to never be auto-cancelled' do
        let(:auto_cancel_on_new_commit) { 'none' }

        it { is_expected.not_to be_protected_after_non_interruptible_job_starts }
      end
    end
  end
end
