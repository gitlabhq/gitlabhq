# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RuntimeEnvironment, feature_category: :runner_core do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:job_runtime_environments).class_name('Ci::JobRuntimeEnvironment') }

  it { is_expected.to validate_presence_of(:environment_key) }
  it { is_expected.to validate_length_of(:environment_key).is_at_most(512) }
  it { is_expected.to validate_presence_of(:project) }

  describe '.find_by_key_and_project' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:runtime_environment) do
      create(:ci_runtime_environment, project: project, environment_key: 'runner-1/system-1/data')
    end

    it 'returns the matching runtime environment for the project' do
      expect(described_class.find_by_key_and_project(runtime_environment.environment_key, project.id))
        .to eq(runtime_environment)
    end

    it 'returns nil when the key matches but the project does not' do
      expect(described_class.find_by_key_and_project(runtime_environment.environment_key, other_project.id))
        .to be_nil
    end

    it 'returns nil when no runtime environment matches the key' do
      expect(described_class.find_by_key_and_project('does-not-exist', project.id)).to be_nil
    end
  end

  describe 'partitioning' do
    it 'uses the sliding_list strategy on the partition column' do
      expect(described_class.partitioning_strategy)
        .to be_a(Gitlab::Database::Partitioning::SlidingListStrategy)
      expect(described_class.partitioning_strategy.partitioning_key).to eq(:partition)
    end
  end

  describe 'sliding_list partitioning' do
    let_it_be(:project) { create(:project) }

    let(:partitioning_strategy) { described_class.partitioning_strategy }

    around do |example|
      Gitlab::Database::SharedModel.using_connection(Ci::ApplicationRecord.connection) do
        example.run
      end
    end

    def create_record(created_at:)
      described_class.create!(project: project, environment_key: 'key', created_at: created_at)
    end

    describe 'next_partition_if callback' do
      let(:active_partition) { partitioning_strategy.active_partition }

      subject(:value) { partitioning_strategy.next_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to be(false) }
      end

      context 'when the partition has records' do
        before do
          create_record(created_at: 1.minute.ago)
        end

        it { is_expected.to be(false) }
      end

      context 'when the oldest record of the partition is older than PARTITION_DURATION' do
        before do
          create_record(created_at: 1.second.before(described_class::PARTITION_DURATION.ago))
          create_record(created_at: 1.minute.ago)
        end

        it { is_expected.to be(true) }
      end
    end

    describe 'detach_partition_if callback' do
      let(:active_partition) { partitioning_strategy.active_partition }

      subject(:value) { partitioning_strategy.detach_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to be(true) }
      end

      context 'when the partition contains records within the cleanup threshold' do
        before do
          create_record(created_at: 1.minute.ago)
        end

        it { is_expected.to be(false) }
      end

      context 'when all the records are older than PARTITION_CLEANUP_THRESHOLD' do
        before do
          create_record(created_at: 1.second.before(described_class::PARTITION_CLEANUP_THRESHOLD.ago))
        end

        it { is_expected.to be(true) }
      end
    end
  end
end
