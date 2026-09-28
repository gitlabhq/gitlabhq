# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RedundantPipelines::PipelineFamily, feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project) }

  let!(:pipeline) { create(:ci_pipeline, :running, project: project, ref: 'main') }
  let!(:superseded_by) { create(:ci_pipeline, :running, project: project, ref: 'main', sha: 'newer-sha') }

  subject(:family) { described_class.new(pipeline) }

  describe '#active?' do
    it 'is active while the pipeline itself is cancelable' do
      expect(family).to be_active
    end

    context 'when the pipeline has finished' do
      before do
        pipeline.update!(status: 'success')
      end

      it { is_expected.not_to be_active }

      context 'with a child pipeline that is still running' do
        before do
          create(:ci_pipeline, :running, child_of: pipeline)
        end

        it { is_expected.to be_active }
      end

      context 'with a child pipeline that has finished too' do
        before do
          create(:ci_pipeline, :success, child_of: pipeline)
        end

        it { is_expected.not_to be_active }
      end
    end
  end

  describe '#cancel' do
    let!(:job) { create(:ci_build, :interruptible, :running, pipeline: pipeline) }

    subject(:cancel) { family.cancel(auto_canceled_by: superseded_by) }

    it 'cancels the pipeline' do
      cancel

      expect(job.reload).to be_canceled
    end

    it 'records which pipeline superseded it' do
      cancel

      expect(pipeline.reload.auto_canceled_by_id).to eq(superseded_by.id)
    end

    context 'when the pipeline cancels only its interruptible jobs' do
      let!(:other_job) { create(:ci_build, :running, pipeline: pipeline) }

      before do
        pipeline.create_pipeline_metadata!(project: project, auto_cancel_on_new_commit: 'interruptible')
      end

      it 'leaves the jobs it cannot interrupt running' do
        cancel

        expect(job.reload).to be_canceled
        expect(other_job.reload).to be_running
      end
    end

    context 'when the pipeline cancels all of its jobs' do
      let!(:other_job) { create(:ci_build, :created, pipeline: pipeline) }

      it 'cancels every cancelable job' do
        cancel

        expect(job.reload).to be_canceled
        expect(other_job.reload).to be_canceled
      end
    end

    context 'with a child pipeline' do
      let!(:child) { create(:ci_pipeline, :running, child_of: pipeline) }
      let!(:child_job) { create(:ci_build, :interruptible, :running, pipeline: child) }

      it 'cancels the child too' do
        cancel

        expect(child_job.reload).to be_canceled
      end

      context 'when the parent has already finished' do
        before do
          pipeline.update!(status: 'success')
        end

        it 'cancels the child that is still running' do
          cancel

          expect(child_job.reload).to be_canceled
        end
      end

      context 'when the child cancels only its interruptible jobs' do
        let!(:other_child_job) { create(:ci_build, :running, pipeline: child) }

        before do
          child.create_pipeline_metadata!(project: project, auto_cancel_on_new_commit: 'interruptible')
        end

        it 'leaves the jobs it cannot interrupt running' do
          cancel

          expect(child_job.reload).to be_canceled
          expect(other_child_job.reload).to be_running
        end
      end

      context 'when the child is configured to never be auto-canceled' do
        before do
          child.create_pipeline_metadata!(project: project, auto_cancel_on_new_commit: 'none')
        end

        it 'leaves the child alone' do
          cancel

          expect(child_job.reload).to be_running
        end

        it 'still cancels the rest of the family' do
          cancel

          expect(job.reload).to be_canceled
        end
      end

      context 'when a non-interruptible job of the child has started' do
        let!(:other_child_job) { create(:ci_build, :running, pipeline: child) }

        before do
          child.create_pipeline_processing_data!(project_id: project.id, interruptible_protected: true)
        end

        it 'leaves the child alone' do
          cancel

          expect(child_job.reload).to be_running
          expect(other_child_job.reload).to be_running
        end

        it 'still cancels the rest of the family' do
          cancel

          expect(job.reload).to be_canceled
        end
      end
    end

    context 'with several children' do
      let!(:children) { create_list(:ci_pipeline, 3, :running, child_of: pipeline) }

      it 'reads the metadata of every member at once' do
        expect { cancel }.not_to exceed_query_limit(1).for_model(::Ci::PipelineMetadata)
      end

      it 'reads the processing data of every member at once' do
        expect { cancel }.not_to exceed_query_limit(1).for_model(::Ci::PipelineProcessingData)
      end
    end

    context 'when the pipeline itself is configured to never be auto-canceled' do
      before do
        pipeline.create_pipeline_metadata!(project: project, auto_cancel_on_new_commit: 'none')
      end

      it 'cancels nothing' do
        cancel

        expect(job.reload).to be_running
      end
    end
  end
end
