# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::AggregateLast30DayUsageService, :clean_gitlab_redis_shared_state, :freeze_time,
  feature_category: :pipeline_composition do
  let_it_be(:usage_start_date) { Date.today - 30.days }
  let_it_be(:usage_end_date) { Date.today - 1.day }
  let_it_be(:initial_usage_count_updated_at) { usage_end_date.to_time }

  let_it_be(:resources) { create_list(:ci_catalog_resource, 4).sort_by(&:id) }
  let_it_be(:expected_ordered_usage_counts) { [3, 1, 0, 15] }

  let(:expected_cursor_attributes) do
    {
      target_id: 0,
      usage_window: usage_window_hash,
      last_used_by_project_id: 0,
      last_usage_count: 0,
      max_target_id: Ci::Catalog::Resource.maximum(:id).to_i
    }
  end

  let(:usage_window_hash) { { start_date: usage_start_date, end_date: usage_end_date } }
  let(:lease_key) { described_class.name }
  let(:service) { described_class.new }

  before_all do
    # Set up each resource with 1-4 versions, 1-4 components per version, and the expected usages per component
    expected_ordered_usage_counts.each_with_index do |usage_count, i|
      resource = resources[i]

      create_list(:ci_catalog_resource_version, i + 1, catalog_resource: resource).each do |version|
        (1..i + 1).each do |j|
          component = create(:ci_catalog_resource_component, version: version, name: "component#{j}")

          (1..usage_count).each do |mock_used_by_project_id|
            # Inside the usage window
            create(:ci_catalog_resource_component_usage,
              component: component, used_date: usage_start_date, used_by_project_id: mock_used_by_project_id)
            # Outside the usage window
            create(:ci_catalog_resource_component_usage,
              component: component, used_date: usage_start_date - mock_used_by_project_id.days,
              used_by_project_id: mock_used_by_project_id)

            # create new usage records in the window
            create(:catalog_resource_component_last_usage, component: component, last_used_date: usage_start_date,
              used_by_project_id: mock_used_by_project_id)
          end
        end
      end
    end

    Ci::Catalog::Resource.update_all(last_30_day_usage_count_updated_at: initial_usage_count_updated_at)
  end

  context 'when storing usage data in catalog_resource_component_last_usages' do
    describe '#execute' do
      it 'updates component usage counts' do
        service.execute

        resources.each do |resource|
          resource.components.each do |component|
            expect(component.reload.last_30_day_usage_count).to eq(
              component.last_usages.select(:used_by_project_id).distinct.count
            )
          end
        end
      end

      it 'updates resource usage counts' do
        service.execute

        resources.each do |resource|
          expected_count = resource.components.sum(:last_30_day_usage_count)
          expect(resource.reload.last_30_day_usage_count).to eq(expected_count)
        end
      end

      it 'returns a success response' do
        response = service.execute

        expect(response).to be_success
        expect(response.message).to eq('Usage counts updated for components and resources')
      end

      context 'when there are no components' do
        before do
          Ci::Catalog::Resources::Component.delete_all
        end

        it 'updates resource counts to zero' do
          service.execute

          resources.each do |resource|
            expect(resource.reload.last_30_day_usage_count).to eq(0)
          end
        end
      end
    end
  end

  private

  def ordered_usage_counts
    Ci::Catalog::Resource.order(:id).pluck(:last_30_day_usage_count)
  end

  def ordered_usage_counts_updated_at
    Ci::Catalog::Resource.order(:id).pluck(:last_30_day_usage_count_updated_at)
  end
end
