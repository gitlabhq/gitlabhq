# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::AggregateLast30DayUsageWorker, feature_category: :pipeline_composition do
  subject(:worker) { described_class.new }

  include_examples 'an idempotent worker'

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has the option to reschedule once if deduplicated and a TTL' do
    expect(described_class.get_deduplication_options).to include(
      { if_deduplicated: :reschedule_once, ttl: Gitlab::Ci::Components::Usages::Aggregator::WORKER_DEDUP_TTL })
  end

  describe '#perform', :clean_gitlab_redis_shared_state, :freeze_time do
    let_it_be(:usage_start_date) { Date.today - Ci::Catalog::Resources::AggregateLast30DayUsageService::WINDOW_LENGTH }
    let_it_be(:usage_end_date) { Date.today - 1.day }

    let_it_be(:resources) { create_list(:ci_catalog_resource, 3).sort_by(&:id) }
    let_it_be(:expected_ordered_usage_counts) { [7, 12, 0] }

    let(:usage_window_hash) { { start_date: usage_start_date, end_date: usage_end_date } }

    subject(:perform) { worker.perform }

    before_all do
      # Set up each resource with 1 version and 1 component, and the expected usages per component
      expected_ordered_usage_counts.each_with_index do |usage_count, i|
        resource = resources[i]
        version = create(:ci_catalog_resource_version, catalog_resource: resource)
        component = create(:ci_catalog_resource_component, version: version)

        (1..usage_count).each do |k|
          create(:ci_catalog_resource_component_usage,
            component: component, used_date: usage_start_date, used_by_project_id: k)
        end
      end
    end

    it 'aggregates and updates usage counts for all catalog resources' do
      perform

      ordered_usage_counts = Ci::Catalog::Resource.order(:id).pluck(:last_30_day_usage_count)
      ordered_usage_counts_updated_at = Ci::Catalog::Resource.order(:id).pluck(:last_30_day_usage_count_updated_at)

      expect(ordered_usage_counts).to eq(expected_ordered_usage_counts)
      expect(ordered_usage_counts_updated_at).to match_array([Time.current] * 3)
    end

    it 'logs the service response' do
      expect(worker).to receive(:log_hash_metadata_on_done)
        .with(
          status: :success,
          message: 'Targets processed',
          total_targets_completed: 3,
          cursor_attributes: {
            target_id: 0,
            usage_window: usage_window_hash,
            last_used_by_project_id: 0,
            last_usage_count: 0,
            max_target_id: Ci::Catalog::Resource.maximum(:id).to_i
          })

      perform
    end
  end
end
