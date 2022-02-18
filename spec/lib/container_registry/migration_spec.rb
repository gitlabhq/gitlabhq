# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Migration do
  using RSpec::Parameterized::TableSyntax

  describe '.enabled?' do
    subject { described_class.enabled? }

    it { is_expected.to eq(true) }

    context 'feature flag disabled' do
      before do
        stub_feature_flags(container_registry_migration_phase2_enabled: false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '.limit_gitlab_org?' do
    subject { described_class.limit_gitlab_org? }

    it { is_expected.to eq(true) }

    context 'feature flag disabled' do
      before do
        stub_feature_flags(container_registry_migration_limit_gitlab_org: false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '.enqueue_waiting_time' do
    subject { described_class.enqueue_waiting_time }

    where(:slow_enabled, :fast_enabled, :expected_result) do
      false | false | 1.hour
      true  | false | 6.hours
      false | true  | 0
      true  | true  | 0
    end

    with_them do
      before do
        stub_feature_flags(
          container_registry_migration_phase2_enqueue_speed_slow: slow_enabled,
          container_registry_migration_phase2_enqueue_speed_fast: fast_enabled
        )
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '.capacity' do
    subject { described_class.capacity }

    where(:ff_1_enabled, :ff_10_enabled, :ff_25_enabled, :expected_result) do
      false | false | false | 0
      true  | false | false | 1
      true  | true  | false | 10
      true  | true  | true  | 25
      false | true  | false | 10
      false | true  | true  | 25
      false | false | true  | 25
      true  | false | true  | 25
    end

    with_them do
      before do
        stub_feature_flags(
          container_registry_migration_phase2_capacity_1: ff_1_enabled,
          container_registry_migration_phase2_capacity_10: ff_10_enabled,
          container_registry_migration_phase2_capacity_25: ff_25_enabled
        )
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '.max_tags_count' do
    let(:value) { 1 }

    before do
      stub_application_setting(container_registry_import_max_tags_count: value)
    end

    it 'returns the matching application_setting' do
      expect(described_class.max_tags_count).to eq(value)
    end
  end

  describe '.max_retries' do
    let(:value) { 1 }

    before do
      stub_application_setting(container_registry_import_max_retries: value)
    end

    it 'returns the matching application_setting' do
      expect(described_class.max_retries).to eq(value)
    end
  end

  describe '.start_max_retries' do
    let(:value) { 1 }

    before do
      stub_application_setting(container_registry_import_start_max_retries: value)
    end

    it 'returns the matching application_setting' do
      expect(described_class.start_max_retries).to eq(value)
    end
  end

  describe '.max_step_duration' do
    let(:value) { 5.minutes }

    before do
      stub_application_setting(container_registry_import_max_step_duration: value)
    end

    it 'returns the matching application_setting' do
      expect(described_class.max_step_duration).to eq(value)
    end
  end

  describe '.target_plan_name' do
    let(:value) { 'free' }

    before do
      stub_application_setting(container_registry_import_target_plan: value)
    end

    it 'returns the matching application_setting' do
      expect(described_class.target_plan_name).to eq(value)
    end
  end

  describe '.created_before' do
    let(:value) { 1.day.ago }

    before do
      stub_application_setting(container_registry_import_created_before: value)
    end

    it 'returns the matching application_setting' do
      expect(described_class.created_before).to eq(value)
    end
  end

  describe '.target_plan' do
    let_it_be(:plan) { create(:plan) }

    before do
      stub_application_setting(container_registry_import_target_plan: plan.name)
    end

    it 'returns the matching application_setting' do
      expect(described_class.target_plan).to eq(plan)
    end
  end
end
