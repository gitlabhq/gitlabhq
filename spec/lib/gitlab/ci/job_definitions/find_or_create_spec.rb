# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::JobDefinitions::FindOrCreate, feature_category: :pipeline_composition do
  include Ci::PartitioningHelpers

  let_it_be(:project) { create(:project) }
  let(:partition_id) { ci_testing_partition_id }
  let(:bulk_insert) { described_class.new(project, partition_id, checksum_to_config) }

  before do
    stub_current_partition_id(partition_id)
  end

  describe '#execute' do
    subject(:execute) { bulk_insert.execute }

    context 'when checksum_to_config is empty' do
      let(:checksum_to_config) { {} }

      it 'returns an empty relation' do
        result = execute

        expect(result).to eq(::Ci::JobDefinition.none)
      end

      it 'does not create any records' do
        expect { execute }.not_to change { ::Ci::JobDefinition.count }
      end
    end

    context 'when inserting new records' do
      let(:checksum1) { 'checksum1' }
      let(:checksum2) { 'checksum2' }
      let(:config1) { { name: 'job1', script: ['echo test1'] } }
      let(:config2) { { name: 'job2', script: ['echo test2'] } }
      let(:checksum_to_config) do
        {
          checksum1 => config1,
          checksum2 => config2
        }
      end

      it 'creates new job definitions' do
        expect { execute }.to change { ::Ci::JobDefinition.count }.by(2)
      end

      it 'returns the created job definitions' do
        result = execute

        expect(result.count).to eq(2)
        expect(result.pluck(:checksum)).to contain_exactly(checksum1, checksum2)
      end

      it 'stores the correct attributes', :freeze_time do
        execute

        definition1 = ::Ci::JobDefinition.find_by(checksum: checksum1)
        definition2 = ::Ci::JobDefinition.find_by(checksum: checksum2)

        expect(definition1).to have_attributes(
          project_id: project.id,
          partition_id: partition_id,
          checksum: checksum1,
          config: config1,
          interruptible: false,
          created_at: Time.current,
          updated_at: Time.current
        )

        expect(definition2).to have_attributes(
          project_id: project.id,
          partition_id: partition_id,
          checksum: checksum2,
          config: config2,
          interruptible: false,
          created_at: Time.current,
          updated_at: Time.current
        )
      end
    end

    context 'when some records already exist' do
      let(:existing_checksum) { 'existing_checksum' }
      let(:new_checksum) { 'new_checksum' }
      let(:existing_config) { { name: 'existing', script: ['echo existing'] } }
      let(:new_config) { { name: 'new', script: ['echo new'] } }

      let!(:existing_definition) do
        create(:ci_job_definition,
          project: project,
          partition_id: partition_id,
          checksum: existing_checksum,
          config: existing_config)
      end

      let(:checksum_to_config) do
        {
          existing_checksum => existing_config,
          new_checksum => new_config
        }
      end

      it 'only creates the missing records' do
        expect { execute }.to change { ::Ci::JobDefinition.count }.by(1)
      end

      it 'returns all requested records' do
        result = execute

        expect(result.count).to eq(2)
        expect(result.pluck(:checksum)).to contain_exactly(existing_checksum, new_checksum)
      end

      it 'does not update existing records', :freeze_time do
        original_updated_at = existing_definition.updated_at

        execute
        existing_definition.reload

        expect(existing_definition.updated_at).to eq(original_updated_at)
      end
    end

    context 'when all records already exist' do
      let(:checksum1) { 'checksum1' }
      let(:checksum2) { 'checksum2' }
      let(:config1) { { name: 'job1', script: ['echo test1'] } }
      let(:config2) { { name: 'job2', script: ['echo test2'] } }

      let!(:existing_definition1) do
        create(:ci_job_definition,
          project: project,
          partition_id: partition_id,
          checksum: checksum1,
          config: config1)
      end

      let!(:existing_definition2) do
        create(:ci_job_definition,
          project: project,
          partition_id: partition_id,
          checksum: checksum2,
          config: config2)
      end

      let(:checksum_to_config) do
        {
          checksum1 => config1,
          checksum2 => config2
        }
      end

      it 'does not create any new records' do
        expect { execute }.not_to change { ::Ci::JobDefinition.count }
      end

      it 'returns the existing records' do
        result = execute

        expect(result.size).to eq(2)
        expect(result.pluck(:checksum)).to contain_exactly(checksum1, checksum2)
      end
    end

    context 'when config includes interruptible field' do
      let(:checksum_interruptible_true) { 'checksum_int_true' }
      let(:checksum_interruptible_false) { 'checksum_int_false' }
      let(:checksum_no_interruptible) { 'checksum_no_int' }

      let(:config_interruptible_true) { { name: 'job1', script: ['echo test1'], interruptible: true } }
      let(:config_interruptible_false) { { name: 'job2', script: ['echo test2'], interruptible: false } }
      let(:config_no_interruptible) { { name: 'job3', script: ['echo test3'] } }

      let(:checksum_to_config) do
        {
          checksum_interruptible_true => config_interruptible_true,
          checksum_interruptible_false => config_interruptible_false,
          checksum_no_interruptible => config_no_interruptible
        }
      end

      it 'sets interruptible based on config or defaults to false' do
        execute

        definition_true = ::Ci::JobDefinition.find_by(checksum: checksum_interruptible_true)
        definition_false = ::Ci::JobDefinition.find_by(checksum: checksum_interruptible_false)
        definition_default = ::Ci::JobDefinition.find_by(checksum: checksum_no_interruptible)

        expect(definition_true).to have_attributes(
          project_id: project.id,
          partition_id: partition_id,
          checksum: checksum_interruptible_true,
          config: config_interruptible_true,
          interruptible: true
        )

        expect(definition_false).to have_attributes(
          project_id: project.id,
          partition_id: partition_id,
          checksum: checksum_interruptible_false,
          config: config_interruptible_false,
          interruptible: false
        )

        expect(definition_default).to have_attributes(
          project_id: project.id,
          partition_id: partition_id,
          checksum: checksum_no_interruptible,
          config: config_no_interruptible,
          interruptible: false
        )
      end
    end
  end
end
