# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Create::JobDefinitionBuilder, feature_category: :pipeline_composition do
  include Ci::PartitioningHelpers

  let_it_be(:project) { create(:project) }

  let(:pipeline) { build(:ci_empty_pipeline, project: project, partition_id: ci_testing_partition_id) }
  let(:builds) { [] }

  subject(:builder) { described_class.new(pipeline, builds) }

  before do
    stub_current_partition_id(ci_testing_partition_id)
  end

  describe '#run' do
    context 'with no builds' do
      it 'does not create any job definitions' do
        expect { builder.run }.not_to change { Ci::JobDefinition.count }
      end
    end

    context 'with builds having temp_job_definition' do
      let(:job_def_for_test) do
        ::Ci::JobDefinition.fabricate(
          config: { options: { script: ['echo test'] } },
          project_id: project.id,
          partition_id: pipeline.partition_id
        )
      end

      let(:job_def_for_different) do
        ::Ci::JobDefinition.fabricate(
          config: { options: { script: ['echo different'] } },
          project_id: project.id,
          partition_id: pipeline.partition_id
        )
      end

      let(:job1) { job_with_temp_job_definition(name: 'job1', job_def: job_def_for_test) }
      let(:job2) { job_with_temp_job_definition(name: 'job2', job_def: job_def_for_test) }
      let(:job3) { job_with_temp_job_definition(name: 'job3', job_def: job_def_for_different) }

      before do
        builds.push(job1, job2, job3)
      end

      it 'creates unique job definitions' do
        expect { builder.run }.to change { Ci::JobDefinition.count }.by(2)
      end

      it 'builds job definition instances for each build' do
        builder.run

        expect(job1.job_definition_instance).to be_present
        expect(job2.job_definition_instance).to be_present
        expect(job3.job_definition_instance).to be_present
      end

      it 'deduplicates job definitions with same checksum' do
        builder.run

        expect(job1.job_definition_instance.job_definition).to eq(job2.job_definition_instance.job_definition)
        expect(job3.job_definition_instance.job_definition).not_to eq(job1.job_definition_instance.job_definition)
      end

      it 'sets correct attributes on job definitions' do
        builder.run

        job_def1 = job1.job_definition_instance.job_definition.reload
        expect(job_def1.project).to eq(project)
        expect(job_def1.partition_id).to eq(pipeline.partition_id)
        expect(job_def1.config[:options]).to eq(script: ['echo test'])

        job_def3 = job3.job_definition_instance.job_definition.reload
        expect(job_def3.config[:options]).to eq(script: ['echo different'])
      end

      it 'sets correct attributes on job definition instances' do
        builder.run

        instance = job1.job_definition_instance
        expect(instance.partition_id).to eq(pipeline.partition_id)
        expect(instance.project).to eq(project)
        expect(instance.job_definition).to be_present
      end
    end

    context 'with existing job definitions' do
      let(:config) { { options: { script: ['echo test'] } } }
      let(:job_def) do
        ::Ci::JobDefinition.fabricate(config: config, project_id: project.id, partition_id: pipeline.partition_id)
      end

      let!(:existing_job_definition) do
        create(:ci_job_definition,
          project: project,
          partition_id: pipeline.partition_id,
          checksum: job_def.checksum,
          config: job_def.config
        )
      end

      let(:job1) { job_with_temp_job_definition(name: 'job1', job_def: job_def) }
      let(:job2) { job_with_temp_job_definition(name: 'job2', job_def: job_def) }

      before do
        builds.push(job1, job2)
      end

      it 'reuses existing job definition' do
        expect { builder.run }.not_to change { Ci::JobDefinition.count }
      end

      it 'creates job definition instances pointing to existing definition' do
        builder.run

        expect(job1.job_definition_instance.job_definition).to eq(existing_job_definition)
        expect(job2.job_definition_instance.job_definition).to eq(existing_job_definition)
      end
    end

    context 'when some jobs have temp_job_definition and some do not' do
      let(:job_def) do
        ::Ci::JobDefinition.fabricate(
          config: { options: { script: ['echo test'] } },
          project_id: project.id,
          partition_id: pipeline.partition_id
        )
      end

      let(:job_with_def) { job_with_temp_job_definition(name: 'job1', job_def: job_def) }
      let(:job_without_def) do
        build(:ci_build, :without_job_definition, pipeline: pipeline, project: project, name: 'job2')
      end

      before do
        builds.push(job_with_def, job_without_def)
      end

      it 'only processes jobs with temp_job_definition' do
        expect { builder.run }.to change { Ci::JobDefinition.count }.by(1)
      end

      it 'only creates job definition instances for jobs with temp_job_definition' do
        builder.run

        expect(job_with_def.job_definition_instance).to be_present
        expect(job_without_def.job_definition_instance).to be_nil
      end
    end
  end

  private

  def job_with_temp_job_definition(job_def:, name: 'test_job')
    build(:ci_build, :without_job_definition, pipeline: pipeline, project: project, name: name).tap do |job|
      job.temp_job_definition = job_def
    end
  end
end
