# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Components::Usage, type: :model, feature_category: :pipeline_composition do
  let_it_be(:component) { create(:ci_catalog_resource_component) }
  let(:component_usage) { build(:ci_catalog_resource_component_usage, component: component) }

  it { is_expected.to belong_to(:component).class_name('Ci::Catalog::Resources::Component') }
  it { is_expected.to belong_to(:catalog_resource).class_name('Ci::Catalog::Resource') }
  it { is_expected.to belong_to(:project).class_name('Project') }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:component) }
    it { is_expected.to validate_presence_of(:catalog_resource) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:used_by_project_id) }

    it do
      component_usage.save!

      expect(component_usage).to validate_uniqueness_of(:used_date)
        .scoped_to([:component_id, :used_by_project_id])
    end
  end

  describe 'callbacks' do
    describe 'used date', :freeze_time do
      context 'when used date is not provided' do
        it 'sets the used date to today' do
          component_usage.save!

          expect(component_usage.reload.used_date).to eq(Date.today)
        end
      end

      context 'when used date is provided' do
        it 'sets the given used date' do
          component_usage.used_date = Date.today + 1.day
          component_usage.save!

          expect(component_usage.reload.used_date).to eq(Date.today + 1.day)
        end
      end
    end
  end

  describe 'monthly partitioning', :freeze_time do
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    it 'drops partitions older than 12 months' do
      # We start with the intialized partitions
      oldest_partition = described_class.partitioning_strategy.current_partitions.min_by(&:from)
      newest_partition = described_class.partitioning_strategy.current_partitions.max_by(&:from)

      # We add one usage record into the oldest and newest partitions
      create(:ci_catalog_resource_component_usage, component: component, used_date: oldest_partition.from)
      create(:ci_catalog_resource_component_usage, component: component, used_date: newest_partition.from)

      expect(described_class.count).to eq(2)

      # After traveling forward 12 months from the oldest partition month
      travel_to(oldest_partition.to + 12.months + 1.day)

      # the oldest partition is dropped
      partition_manager.sync_partitions

      expect(described_class.partitioning_strategy.current_partitions.include?(oldest_partition)).to eq(false)

      # and we only have the usage record from the remaining partitions
      expect(described_class.count).to eq(1)
    end
  end
end
