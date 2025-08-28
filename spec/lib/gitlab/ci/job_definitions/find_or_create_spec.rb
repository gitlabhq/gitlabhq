# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::JobDefinitions::FindOrCreate, feature_category: :pipeline_composition do
  include Ci::PartitioningHelpers

  let_it_be(:project) { create(:project) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, partition_id: partition_id) }
  let(:partition_id) { ci_testing_partition_id }
  let(:jobs) { [] }
  let(:service) { described_class.new(pipeline, jobs) }

  before do
    stub_current_partition_id(partition_id)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'when jobs array is empty' do
      let(:jobs) { [] }

      it 'returns an empty array' do
        expect(execute).to eq([])
      end

      it 'does not create any records' do
        expect { execute }.not_to change { ::Ci::JobDefinition.count }
      end
    end

    context 'when inserting new records' do
      let(:config1) { { options: { script: ['echo test1'] } } }
      let(:config2) { { options: { script: ['echo test2'] } } }

      let(:job_def1) do
        ::Ci::JobDefinition.fabricate(config: config1, project_id: project.id, partition_id: partition_id)
      end

      let(:job_def2) do
        ::Ci::JobDefinition.fabricate(config: config2, project_id: project.id, partition_id: partition_id)
      end

      let(:job1) { build(:ci_build, pipeline: pipeline, temp_job_definition: job_def1) }
      let(:job2) { build(:ci_build, pipeline: pipeline, temp_job_definition: job_def2) }
      let(:jobs) { [job1, job2] }

      it 'creates new job definitions' do
        expect { execute }.to change { ::Ci::JobDefinition.count }.by(2)
      end

      it 'returns the created job definitions' do
        result = execute

        expect(result.count).to eq(2)
        expect(result.map(&:checksum)).to contain_exactly(job_def1.checksum, job_def2.checksum)
      end

      it 'stores the correct attributes', :freeze_time do
        execute

        definition1 = ::Ci::JobDefinition.find_by(checksum: job_def1.checksum)
        definition2 = ::Ci::JobDefinition.find_by(checksum: job_def2.checksum)

        expect(definition1).to have_attributes(
          project_id: project.id,
          partition_id: partition_id,
          checksum: job_def1.checksum,
          config: config1,
          interruptible: false,
          created_at: Time.current,
          updated_at: Time.current
        )

        expect(definition2).to have_attributes(
          project_id: project.id,
          partition_id: partition_id,
          checksum: job_def2.checksum,
          config: config2,
          interruptible: false,
          created_at: Time.current,
          updated_at: Time.current
        )
      end

      context 'when jobs have the same config' do
        let(:config) { { options: { script: ['echo test'] } } }
        let(:shared_job_def) do
          ::Ci::JobDefinition.fabricate(config: config, project_id: project.id, partition_id: partition_id)
        end

        let(:job1) { build(:ci_build, pipeline: pipeline, temp_job_definition: shared_job_def) }
        let(:job2) { build(:ci_build, pipeline: pipeline, temp_job_definition: shared_job_def) }
        let(:jobs) { [job1, job2] }

        it 'creates only one job definition' do
          expect { execute }.to change { ::Ci::JobDefinition.count }.by(1)
        end

        it 'returns one job definition' do
          result = execute
          expect(result.count).to eq(1)
          expect(result.first.checksum).to eq(shared_job_def.checksum)
        end
      end
    end

    context 'when some records already exist' do
      let(:existing_config) { { options: { script: ['echo existing'] } } }
      let(:new_config) { { options: { script: ['echo new'] } } }

      let(:existing_job_def) do
        ::Ci::JobDefinition.fabricate(config: existing_config, project_id: project.id, partition_id: partition_id)
      end

      let(:new_job_def) do
        ::Ci::JobDefinition.fabricate(config: new_config, project_id: project.id, partition_id: partition_id)
      end

      let!(:existing_definition) do
        create(:ci_job_definition,
          project: project,
          partition_id: partition_id,
          checksum: existing_job_def.checksum,
          config: existing_config)
      end

      let(:job1) { build(:ci_build, pipeline: pipeline, temp_job_definition: existing_job_def) }
      let(:job2) { build(:ci_build, pipeline: pipeline, temp_job_definition: new_job_def) }
      let(:jobs) { [job1, job2] }

      it 'only creates the missing records' do
        expect { execute }.to change { ::Ci::JobDefinition.count }.by(1)
      end

      it 'returns all requested records' do
        result = execute

        expect(result.count).to eq(2)
        expect(result.map(&:checksum)).to contain_exactly(existing_job_def.checksum, new_job_def.checksum)
      end

      it 'does not update existing records', :freeze_time do
        original_updated_at = existing_definition.updated_at

        execute
        existing_definition.reload

        expect(existing_definition.updated_at).to eq(original_updated_at)
      end
    end

    context 'when all records already exist' do
      let(:config1) { { options: { script: ['echo test1'] } } }
      let(:config2) { { options: { script: ['echo test2'] } } }

      let(:job_def1) do
        ::Ci::JobDefinition.fabricate(config: config1, project_id: project.id, partition_id: partition_id)
      end

      let(:job_def2) do
        ::Ci::JobDefinition.fabricate(config: config2, project_id: project.id, partition_id: partition_id)
      end

      let!(:existing_definition1) do
        create(:ci_job_definition,
          project: project,
          partition_id: partition_id,
          checksum: job_def1.checksum,
          config: config1)
      end

      let!(:existing_definition2) do
        create(:ci_job_definition,
          project: project,
          partition_id: partition_id,
          checksum: job_def2.checksum,
          config: config2)
      end

      let(:job1) { build(:ci_build, pipeline: pipeline, temp_job_definition: job_def1) }
      let(:job2) { build(:ci_build, pipeline: pipeline, temp_job_definition: job_def2) }
      let(:jobs) { [job1, job2] }

      it 'does not create any new records' do
        expect { execute }.not_to change { ::Ci::JobDefinition.count }
      end

      it 'returns the existing records' do
        result = execute

        expect(result.size).to eq(2)
        expect(result.map(&:checksum)).to contain_exactly(job_def1.checksum, job_def2.checksum)
      end
    end

    context 'when config includes interruptible field' do
      let(:config_interruptible_true) { { options: { script: ['echo test1'] }, interruptible: true } }
      let(:config_interruptible_false) { { options: { script: ['echo test2'] }, interruptible: false } }
      let(:config_no_interruptible) { { options: { script: ['echo test3'] } } }

      let(:job_def_true) do
        ::Ci::JobDefinition.fabricate(config: config_interruptible_true, project_id: project.id,
          partition_id: partition_id)
      end

      let(:job_def_false) do
        ::Ci::JobDefinition.fabricate(config: config_interruptible_false, project_id: project.id,
          partition_id: partition_id)
      end

      let(:job_def_default) do
        ::Ci::JobDefinition.fabricate(config: config_no_interruptible, project_id: project.id,
          partition_id: partition_id)
      end

      let(:job1) { build(:ci_build, pipeline: pipeline, temp_job_definition: job_def_true) }
      let(:job2) { build(:ci_build, pipeline: pipeline, temp_job_definition: job_def_false) }
      let(:job3) { build(:ci_build, pipeline: pipeline, temp_job_definition: job_def_default) }
      let(:jobs) { [job1, job2, job3] }

      it 'sets interruptible based on config or defaults to false' do
        execute

        definition_true = ::Ci::JobDefinition.find_by(checksum: job_def_true.checksum)
        definition_false = ::Ci::JobDefinition.find_by(checksum: job_def_false.checksum)
        definition_default = ::Ci::JobDefinition.find_by(checksum: job_def_default.checksum)

        expect(definition_true).to have_attributes(
          project_id: project.id,
          partition_id: partition_id,
          checksum: job_def_true.checksum,
          config: config_interruptible_true,
          interruptible: true
        )

        expect(definition_false).to have_attributes(
          project_id: project.id,
          partition_id: partition_id,
          checksum: job_def_false.checksum,
          config: config_interruptible_false,
          interruptible: false
        )

        expect(definition_default).to have_attributes(
          project_id: project.id,
          partition_id: partition_id,
          checksum: job_def_default.checksum,
          config: config_no_interruptible,
          interruptible: false
        )
      end
    end

    context 'when batch processing' do
      let(:job_definitions) do
        Array.new(described_class::BATCH_SIZE + 10) do |i|
          config = { options: { script: ["echo test#{i}"] } }
          ::Ci::JobDefinition.fabricate(config: config, project_id: project.id, partition_id: partition_id)
        end
      end

      let(:jobs) do
        job_definitions.map do |job_def|
          build(:ci_build, pipeline: pipeline, temp_job_definition: job_def)
        end
      end

      it 'handles batch inserts correctly' do
        expect { execute }.to change { ::Ci::JobDefinition.count }.by(60)
      end

      it 'uses BATCH_SIZE for bulk_insert!' do
        expect(::Ci::JobDefinition).to receive(:bulk_insert!).with(
          anything, hash_including(batch_size: described_class::BATCH_SIZE)
        ).at_least(:once).and_call_original

        execute
      end
    end

    context 'when records are inserted concurrently' do
      let(:config1) { { options: { script: ['echo concurrent1'] } } }
      let(:config2) { { options: { script: ['echo concurrent2'] } } }

      let(:job_def1) do
        ::Ci::JobDefinition.fabricate(config: config1, project_id: project.id, partition_id: partition_id)
      end

      let(:job_def2) do
        ::Ci::JobDefinition.fabricate(config: config2, project_id: project.id, partition_id: partition_id)
      end

      let(:job1) { build(:ci_build, pipeline: pipeline, temp_job_definition: job_def1) }
      let(:job2) { build(:ci_build, pipeline: pipeline, temp_job_definition: job_def2) }
      let(:jobs) { [job1, job2] }

      it 'handles race condition where definitions are inserted after initial check' do
        # Stub the first fetch_records_for call to return empty (simulating no existing records)
        first_call = true
        allow(service).to receive(:fetch_records_for).and_wrap_original do |method, *args|
          # First call returns empty, subsequent calls use the real method
          if first_call
            first_call = false
            []
          else
            method.call(*args)
          end
        end

        # Create the records after the initial check but before bulk_insert! is called
        # This simulates another process/thread creating the same records
        expect(::Ci::JobDefinition).to receive(:bulk_insert!).and_wrap_original do |method, *args, **kwargs|
          create(:ci_job_definition,
            project: project,
            partition_id: partition_id,
            checksum: job_def1.checksum,
            config: config1)

          create(:ci_job_definition,
            project: project,
            partition_id: partition_id,
            checksum: job_def2.checksum,
            config: config2)

          method.call(*args, **kwargs)
        end

        result = execute

        expect(result.size).to eq(2)
        expect(result.map(&:checksum)).to contain_exactly(job_def1.checksum, job_def2.checksum)

        expect(::Ci::JobDefinition.where(checksum: [job_def1.checksum, job_def2.checksum]).count).to eq(2)
      end
    end
  end
end
