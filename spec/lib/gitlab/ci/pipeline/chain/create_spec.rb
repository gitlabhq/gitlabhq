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

  shared_examples 'pipeline creation' do
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

    context 'when coordinating webhook execution with worker', :request_store do
      let(:pipeline) { build(:ci_empty_pipeline, project: project, ref: 'master', user: user) }
      let(:stage) { build(:ci_stage, pipeline: pipeline, project: project) }
      let(:ci_build) { build(:ci_build, pipeline: pipeline, ci_stage: stage, project: project, user: user) }

      before do
        pipeline.stages = [stage]
        stage.statuses = [ci_build]
      end

      it 'sets request store flag to prevent build callbacks from executing hooks' do
        expect(ci_build).not_to receive(:execute_hooks)

        step.perform!
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(ci_trigger_build_hooks_in_chain: false)
          stub_feature_flags(ci_bulk_insert_pipeline_records: false)
        end

        it 'does not set request store flag' do
          step.perform!

          expect(Gitlab::SafeRequestStore[:ci_triggering_build_hooks_via_chain]).to be_nil
        end
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
        it 'does not try to insert taggings' do
          expect(Gitlab::Ci::Tags::BulkInsert)
            .not_to receive(:bulk_insert_tags!)

          step.perform!

          expect(job).to be_persisted
          expect(job.tag_list).to eq([])
          expect(Ci::Tag.count).to be_zero
        end
      end

      context 'with tags' do
        let(:job) do
          build(:ci_build, ci_stage: stage, pipeline: pipeline, project: project, tag_list: %w[tag1 tag2])
        end

        it 'does not bulk inserts tags' do
          expect(Gitlab::Ci::Tags::BulkInsert)
            .not_to receive(:bulk_insert_tags!)

          step.perform!

          expect(job).to be_persisted
          expect(job.reload.tag_list).to eq(%w[tag1 tag2])
          expect(job.reload.taggings).to be_empty
          expect(Ci::Tag.named(%w[tag1 tag2])).to be_empty
        end
      end
    end

    describe 'pipeline logger tag counts' do
      let(:stage) { build(:ci_stage, pipeline: pipeline, project: project) }
      let(:job1) do
        build(:ci_build, :without_job_definition, ci_stage: stage, pipeline: pipeline, project: project,
          tag_list: %w[ruby docker])
      end

      let(:job2) do
        build(:ci_build, :without_job_definition, ci_stage: stage, pipeline: pipeline, project: project,
          tag_list: %w[docker postgres])
      end

      let(:logger) { Gitlab::Ci::Pipeline::Logger.new(project: project) }

      before do
        pipeline.stages = [stage]
        stage.statuses = [job1, job2]

        # Set temp_job_definition as it would be set by Seed::Build
        config1 = { options: { script: ['echo test'] }, tag_list: %w[ruby docker] }
        config2 = { options: { script: ['echo different'] }, tag_list: %w[docker postgres] }

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
        job2.temp_job_definition = job_def2

        allow(command).to receive(:logger).and_return(logger)
      end

      it 'does not execute SQL queries when calculating tag counts for logger' do
        step.perform!

        expect(pipeline).to be_persisted

        recorder = ActiveRecord::QueryRecorder.new do
          logger.commit(pipeline: pipeline, caller: 'test')
        end

        # The logger should not make any SQL queries for pipeline_builds_tags_count
        # and pipeline_builds_distinct_tags_count because it uses the cached tag_list
        # from already-loaded builds
        expect(recorder.count).to eq(0)
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

  # shared_examples 'pipeline creation'

  context 'with bulk insert disabled' do
    before do
      stub_feature_flags(ci_bulk_insert_pipeline_records: false)
    end

    it_behaves_like 'pipeline creation'
  end

  context 'with bulk insert enabled' do
    before do
      stub_feature_flags(ci_bulk_insert_pipeline_records: true)
    end

    it_behaves_like 'pipeline creation'
  end

  describe 'bulk insert path' do
    let(:pipeline) { build(:ci_empty_pipeline, project: project, ref: 'master', user: user) }
    let(:stage) { build(:ci_stage, pipeline: pipeline, project: project) }
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
        options: { script: ['echo different'] }
      )
    end

    before do
      stub_feature_flags(ci_bulk_insert_pipeline_records: true)

      pipeline.stages = [stage]
      stage.statuses = [job1, job2]

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
      job2.temp_job_definition = job_def2
    end

    it 'persists pipeline using bulk insert' do
      step.perform!

      expect(pipeline).to be_persisted
      expect(step.break?).to be false
    end

    it 'bulk inserts stages with IDs restored' do
      step.perform!

      persisted_stage = pipeline.reload.stages.first
      expect(persisted_stage).to be_persisted
      expect(persisted_stage.id).to be_present
      expect(persisted_stage.pipeline_id).to eq(pipeline.id)
      expect(persisted_stage.partition_id).to eq(pipeline.partition_id)
    end

    it 'bulk inserts builds with IDs and partition_ids restored' do
      step.perform!

      persisted_builds = pipeline.reload.builds.order(:id)
      expect(persisted_builds.count).to eq(2)

      persisted_builds.each do |build|
        expect(build).to be_persisted
        expect(build.id).to be_present
        expect(build.partition_id).to be_present
        expect(build.commit_id).to eq(pipeline.id)
        expect(build.project_id).to eq(project.id)
      end
    end

    it 'bulk inserts job definition instances with correct references' do
      step.perform!

      persisted_builds = pipeline.reload.builds.order(:id)
      expect(Ci::JobDefinitionInstance.count).to eq(2)

      persisted_builds.each do |build|
        instance = build.job_definition_instance
        expect(instance).to be_present
        expect(instance.job_id).to eq(build.id)
        expect(instance.partition_id).to eq(build.partition_id)
        expect(instance.job_definition).to be_present
      end
    end

    context 'when insert fails' do
      before do
        allow_next_instance_of(Gitlab::Ci::Pipeline::Chain::Create) do |instance|
          allow(instance).to receive(:insert_records_and_restore_ids).and_raise(ActiveRecord::RecordInvalid.new)
        end
      end

      it 'cleans up by destroying the pipeline' do
        step.perform!

        expect(pipeline).not_to be_persisted
        expect(Ci::Pipeline.find_by(id: pipeline.id)).to be_nil
        expect(step.break?).to be true
      end
    end

    context 'with more than 500 builds' do
      let(:pipeline) { build(:ci_empty_pipeline, project: project, ref: 'master', user: user) }
      let(:stage) { build(:ci_stage, pipeline: pipeline, project: project) }

      before do
        builds = Array.new(550) do |i|
          build(:ci_build,
            :without_job_definition,
            ci_stage: stage,
            pipeline: pipeline,
            project: project,
            name: "job#{i}",
            options: { script: ['echo test'] }
          )
        end

        pipeline.stages = [stage]
        stage.statuses = builds

        builds.each do |job|
          config = { options: { script: ['echo test'] } }
          job_def = Ci::JobDefinition.fabricate(
            config: config,
            project_id: project.id,
            partition_id: pipeline.partition_id
          )
          job.temp_job_definition = job_def
        end
      end

      it 'batches inserts and persists all builds' do
        step.perform!

        expect(pipeline).to be_persisted
        expect(pipeline.reload.builds.count).to eq(550)
      end
    end

    context 'when pipeline has duplicate iid during bulk insert' do
      let_it_be(:old_pipeline) do
        create(:ci_empty_pipeline, project: project, ref: 'master', user: user)
      end

      let(:pipeline) do
        build(:ci_empty_pipeline, project: project, ref: 'master', user: user)
          .tap { |pipeline| pipeline.write_attribute(:iid, old_pipeline.iid) }
      end

      before do
        pipeline.stages = [stage]
        stage.statuses = [job1]
      end

      it 'retries and succeeds after flushing internal id' do
        expect(InternalId).to receive(:flush_records!).with(project: project, usage: :ci_pipelines).and_call_original

        step.perform!

        expect(pipeline).to be_persisted
        expect(step.break?).to be false
      end
    end

    context 'when pipeline has validation errors' do
      before do
        allow(pipeline).to receive(:validate!).and_raise(ActiveRecord::RecordInvalid.new(pipeline))
        pipeline.stages = [stage]
        stage.statuses = [job1]
      end

      it 'validates pipeline before allocating IID' do
        expect(pipeline).to receive(:validate!).and_raise(ActiveRecord::RecordInvalid.new(pipeline))
        expect(pipeline).not_to receive(:save!)

        step.perform!
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

      it 'does not persist the pipeline' do
        step.perform!

        expect(pipeline).not_to be_persisted
      end
    end

    context 'when build has validation errors' do
      let(:invalid_build) do
        build(:ci_build,
          :without_job_definition,
          ci_stage: stage,
          pipeline: pipeline,
          project: project,
          name: nil
        )
      end

      before do
        pipeline.stages = [stage]
        stage.statuses = [invalid_build]
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

      it 'does not persist the pipeline' do
        step.perform!

        expect(pipeline).not_to be_persisted
      end
    end

    context 'with empty stages' do
      before do
        pipeline.stages = []
      end

      it 'persists pipeline without stages' do
        step.perform!

        expect(pipeline).to be_persisted
        expect(pipeline.reload.stages).to be_empty
      end
    end

    context 'with build without ci_stage' do
      let(:job_without_stage) do
        build(:ci_build,
          :without_job_definition,
          pipeline: pipeline,
          project: project,
          name: 'job_without_stage',
          options: { script: ['echo test'] }
        )
      end

      before do
        pipeline.stages = [stage]
        stage.statuses = [job1, job_without_stage]

        job_without_stage.ci_stage = nil
        job_without_stage.importing = true

        config = { options: { script: ['echo test'] } }
        job_def = Ci::JobDefinition.fabricate(
          config: config,
          project_id: project.id,
          partition_id: pipeline.partition_id
        )
        job_without_stage.temp_job_definition = job_def
      end

      it 'persists build without setting stage_id' do
        step.perform!

        persisted_build = Ci::Build.find_by(name: 'job_without_stage')
        expect(persisted_build).to be_present
        expect(persisted_build.stage_id).to be_nil
      end
    end
  end
end
