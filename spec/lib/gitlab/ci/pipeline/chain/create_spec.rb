# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Create do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_empty_pipeline, project: project, ref: 'master', user: user)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project, current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  context 'when pipeline is ready to be saved' do
    before do
      pipeline.stages.build(name: 'test', position: 0, project: project)

      step.perform!
    end

    it 'saves a pipeline' do
      expect(pipeline).to be_persisted
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'creates stages' do
      expect(pipeline.reload.stages).to be_one
      expect(pipeline.stages.first).to be_persisted
    end
  end

  context 'when pipeline has validation errors' do
    let(:pipeline) do
      build(:ci_pipeline, project: project, ref: nil)
    end

    before do
      step.perform!
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'appends validation error' do
      expect(pipeline.errors.to_a)
        .to include(/Failed to persist the pipeline/)
    end
  end

  context 'when pipeline has duplicate iid' do
    let_it_be(:old_pipeline) do
      create(:ci_empty_pipeline, project: project, ref: 'master', user: user)
    end

    let(:pipeline) do
      build(:ci_empty_pipeline, project: project, ref: 'master', user: user).tap do |pipeline|
        pipeline.write_attribute(:iid, old_pipeline.iid)
      end
    end

    it 'breaks the chain' do
      step.perform!

      expect(step.break?).to be true
    end

    it 'appends validation error' do
      step.perform!

      expect(pipeline.errors.to_a)
        .to include(/Failed to persist the pipeline/)
    end

    it 'flushes internal id records for pipelines' do
      expect { step.perform! }
        .to change { InternalId.where(project: project, usage: :ci_pipelines).count }.by(-1)
    end

    it 'propagates different uniqueness errors' do
      expect(pipeline).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)

      expect { step.perform! }
        .to raise_error(ActiveRecord::RecordNotUnique)
        .and not_change { InternalId.count }
    end
  end

  context 'tags persistence' do
    let(:stage) do
      build(:ci_stage, pipeline: pipeline, project: project)
    end

    let(:job) do
      build(:ci_build, ci_stage: stage, pipeline: pipeline, project: project)
    end

    let(:bridge) do
      build(:ci_bridge, ci_stage: stage, pipeline: pipeline, project: project)
    end

    before do
      pipeline.stages = [stage]
      stage.statuses = [job, bridge]
    end

    context 'without tags' do
      it 'extracts an empty tag list' do
        expect(Gitlab::Ci::Tags::BulkInsert)
          .to receive(:bulk_insert_tags!)
          .with([job])
          .and_call_original

        step.perform!

        expect(job).to be_persisted
        expect(job.tag_list).to eq([])
      end
    end

    context 'with tags' do
      before do
        job.tag_list = %w[tag1 tag2]
      end

      it 'bulk inserts tags' do
        expect(Gitlab::Ci::Tags::BulkInsert)
          .to receive(:bulk_insert_tags!)
          .with([job])
          .and_call_original

        step.perform!

        expect(job).to be_persisted
        expect(job.reload.tag_list).to match_array(%w[tag1 tag2])
      end
    end
  end
end
