# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Create, feature_category: :pipeline_composition do
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

  shared_examples 'when pipeline has duplicate iid' do
    let_it_be(:old_pipeline) do
      create(:ci_empty_pipeline, project: project, ref: 'master', user: user, partition_id: 100)
    end

    let(:pipeline) do
      build(:ci_empty_pipeline, project: project, ref: 'master', user: user, partition_id: partition_id)
        .tap { |pipeline| pipeline.write_attribute(:iid, old_pipeline.iid) }
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

  context 'when pipeline iid already exists in the same partition' do
    let(:partition_id) { old_pipeline.partition_id }

    it_behaves_like 'when pipeline has duplicate iid'
  end

  context 'when pipeline iid already exists in a different partition' do
    let(:partition_id) { old_pipeline.partition_id + 1 }

    it_behaves_like 'when pipeline has duplicate iid'
  end

  context 'tags persistence' do
    let(:stage) do
      build(:ci_stage, pipeline: pipeline, project: project)
    end

    let(:job) do
      build(:ci_build, :without_job_definition, ci_stage: stage, pipeline: pipeline, project: project)
    end

    let(:bridge) do
      build(:ci_bridge, :without_job_definition, ci_stage: stage, pipeline: pipeline, project: project)
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

  describe 'job definitions persistence' do
    let(:stage) do
      build(:ci_stage, pipeline: pipeline, project: project)
    end

    let(:job1) do
      build(:ci_build,
        :without_job_definition,
        ci_stage: stage,
        pipeline: pipeline,
        project: project,
        name: 'job1',
        options: { script: ['echo test'] }
      )
    end

    let(:job2) do
      build(:ci_build,
        :without_job_definition,
        ci_stage: stage,
        pipeline: pipeline,
        project: project,
        name: 'job2',
        options: { script: ['echo test'] } # Same config as job1
      )
    end

    let(:job3) do
      build(:ci_build,
        :without_job_definition,
        ci_stage: stage,
        pipeline: pipeline,
        project: project,
        name: 'job3',
        options: { script: ['echo different'] } # Different config
      )
    end

    before do
      pipeline.stages = [stage]
      stage.statuses = [job1, job2, job3]

      # Set temp_job_definition as it would be set by Seed::Build
      config1 = { options: { script: ['echo test'] } }
      config2 = { options: { script: ['echo different'] } }

      job_def1 = Ci::JobDefinition.fabricate(
        config: config1,
        project_id: project.id,
        partition_id: pipeline.partition_id
      )
      job_def2 = Ci::JobDefinition.fabricate(
        config: config2,
        project_id: project.id,
        partition_id: pipeline.partition_id
      )

      job1.temp_job_definition = job_def1
      job2.temp_job_definition = job_def1
      job3.temp_job_definition = job_def2
    end

    it 'uses JobDefinitionBuilder to create job definitions' do
      builder_double = instance_double(Gitlab::Ci::Pipeline::Create::JobDefinitionBuilder)
      expect(Gitlab::Ci::Pipeline::Create::JobDefinitionBuilder)
        .to receive(:new)
        .with(pipeline, [job1, job2, job3])
        .and_return(builder_double)
      expect(builder_double).to receive(:run)

      step.perform!
    end

    it 'creates job definitions' do
      expect { step.perform! }.to change { Ci::JobDefinition.count }.by(2)
    end

    it 'creates job definition instances for each job' do
      expect { step.perform! }.to change { Ci::JobDefinitionInstance.count }.by(3)
    end

    it 'deduplicates job definitions with same checksum' do
      step.perform!

      job_definitions = Ci::JobDefinition.all
      expect(job_definitions.count).to eq(2)

      # job1 and job2 should share the same job definition
      expect(job1.reload.job_definition).to eq(job2.reload.job_definition)
      expect(job3.reload.job_definition).not_to eq(job1.job_definition)
    end

    it 'sets correct job definition attributes' do
      step.perform!

      job_def1 = job1.reload.job_definition
      expect(job_def1.project).to eq(project)
      expect(job_def1.partition_id).to eq(pipeline.partition_id)
      expect(job_def1.config[:options]).to eq(script: ['echo test'])

      job_def3 = job3.reload.job_definition
      expect(job_def3.config[:options]).to eq(script: ['echo different'])
    end

    context 'with yaml_variables' do
      before do
        config = { options: { script: ['echo test'] }, yaml_variables: [{ key: 'VAR', value: 'value' }] }
        job_def = Ci::JobDefinition.fabricate(
          config: config,
          project_id: project.id,
          partition_id: pipeline.partition_id
        )
        job1.temp_job_definition = job_def
      end

      it 'includes yaml_variables in job definition' do
        step.perform!

        job_def = job1.reload.job_definition
        expect(job_def.config[:yaml_variables]).to eq([{ key: 'VAR', value: 'value' }])
      end
    end

    context 'with jobs without temp_job_definition' do
      before do
        job1.temp_job_definition = nil

        config = { options: { script: ['echo test'] } }
        job_def = Ci::JobDefinition.fabricate(
          config: config,
          project_id: project.id,
          partition_id: pipeline.partition_id
        )
        job2.temp_job_definition = job_def
        job3.temp_job_definition = nil
      end

      it 'only creates job definitions for jobs with temp_job_definition' do
        expect { step.perform! }.to change { Ci::JobDefinition.count }.by(1)
      end

      it 'only creates job definition instances for jobs with temp_job_definition' do
        expect { step.perform! }.to change { Ci::JobDefinitionInstance.count }.by(1)
      end
    end

    context 'when pipeline save fails' do
      before do
        allow(pipeline).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'still creates job definitions (as they are created outside the transaction)' do
        # Job definitions are intentionally created outside the transaction
        # so they can be reused in future pipeline creations
        expect do
          step.perform!
        rescue StandardError
          nil
        end.to change { Ci::JobDefinition.count }.by(2)
      end
    end
  end
end
