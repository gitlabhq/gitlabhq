# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerManagerBuild, :model, feature_category: :fleet_visibility do
  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:runner_manager) { create(:ci_runner_machine, runner: runner) }
  let_it_be(:build) { create(:ci_build, runner_manager: runner_manager) }

  describe 'associations' do
    it { is_expected.to belong_to(:build) }
    it { is_expected.to belong_to(:runner_manager) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:build) }
    it { is_expected.to validate_presence_of(:project_id) }
  end

  describe 'partitioning' do
    context 'with build' do
      let(:build) { FactoryBot.build(:ci_build, partition_id: ci_testing_partition_id) }
      let(:runner_manager_build) { FactoryBot.build(:ci_runner_machine_build, build: build) }

      it 'sets partition_id to the current partition value' do
        expect { runner_manager_build.valid? }.to change { runner_manager_build.partition_id }
          .to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let(:runner_manager_build) { FactoryBot.build(:ci_runner_machine_build, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { runner_manager_build.valid? }.not_to change { runner_manager_build.partition_id }
        end
      end
    end

    context 'without build' do
      let(:runner_manager_build) { FactoryBot.build(:ci_runner_machine_build, build: nil) }

      it { is_expected.to validate_presence_of(:partition_id) }

      it 'does not change the partition_id value' do
        expect { runner_manager_build.valid? }.not_to change { runner_manager_build.partition_id }
      end
    end
  end

  describe 'ci_sliding_list partitioning' do
    let(:connection) { described_class.connection }
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    let(:partitioning_strategy) { described_class.partitioning_strategy }

    it { expect(partitioning_strategy.missing_partitions).to be_empty }
    it { expect(partitioning_strategy.extra_partitions).to be_empty }
    it { expect(partitioning_strategy.current_partitions).to include partitioning_strategy.initial_partition }
    it { expect(partitioning_strategy.active_partition).to be_present }
  end

  context 'with loose foreign key on p_ci_runner_manager_builds.runner_manager_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:ci_runner_machine) }
      let!(:model) { create(:ci_runner_machine_build, runner_manager: parent) }
    end
  end

  describe '.for_build' do
    subject(:for_build) { described_class.for_build(build_id) }

    context 'with valid build_id' do
      let(:build_id) { build.id }

      it { is_expected.to contain_exactly(described_class.find_by_build_id(build_id)) }
    end

    context 'with valid build_ids' do
      let(:build2) { create(:ci_build, runner_manager: runner_manager) }
      let(:build_id) { [build, build2] }

      it { is_expected.to eq(described_class.where(build_id: build_id)) }
    end

    context 'with non-existing build_id' do
      let(:build_id) { non_existing_record_id }

      it { is_expected.to be_empty }
    end
  end

  describe '.pluck_runner_manager_id_and_build_id' do
    subject { scope.pluck_build_id_and_runner_manager_id }

    context 'with default scope' do
      let(:scope) { described_class }

      it { is_expected.to eq({ build.id => runner_manager.id }) }
    end

    context 'with scope excluding build' do
      let(:scope) { described_class.where(build_id: non_existing_record_id) }

      it { is_expected.to be_empty }
    end
  end

  describe '#ensure_project_id' do
    it 'sets the project_id before validation' do
      runner_machine_build = FactoryBot.build(:ci_runner_machine_build, build: build)

      expect do
        runner_machine_build.validate!
      end.to change { runner_machine_build.project_id }.from(nil).to(runner_machine_build.build.project.id)
    end

    it 'does not override the project_id if set' do
      another_project = create(:project)
      runner_machine_build = FactoryBot.build(:ci_runner_machine_build, project_id: another_project.id)

      expect do
        runner_machine_build.validate!
      end.not_to change { runner_machine_build.project_id }.from(another_project.id)
    end
  end
end
