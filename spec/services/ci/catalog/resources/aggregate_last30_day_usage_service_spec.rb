# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::AggregateLast30DayUsageService,
  feature_category: :pipeline_composition do
  let(:service) { described_class.new }

  describe '#execute' do
    let_it_be(:resource) { create(:ci_catalog_resource) }
    let_it_be(:component_a) { create(:ci_catalog_resource_component, catalog_resource: resource) }
    let_it_be(:component_b) { create(:ci_catalog_resource_component, catalog_resource: resource) }
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }

    it 'returns a success response' do
      response = service.execute

      expect(response).to be_success
      expect(response.message).to eq('Usage counts updated for components and resources')
    end

    context 'when updating usage counts' do
      before do
        # Project1 uses both components A and B
        create(:catalog_resource_component_last_usage,
          component: component_a,
          used_by_project_id: project1.id,
          last_used_date: 10.days.ago.to_date
        )
        create(:catalog_resource_component_last_usage,
          component: component_b,
          used_by_project_id: project1.id,
          last_used_date: 10.days.ago.to_date
        )

        # Project2 uses only component A
        create(:catalog_resource_component_last_usage,
          component: component_a,
          used_by_project_id: project2.id,
          last_used_date: 5.days.ago.to_date
        )

        service.execute
      end

      it 'updates resource usage counts' do
        # Should count 3 component usages:
        # - project1 + component_a = 1
        # - project1 + component_b = 1
        # - project2 + component_a = 1
        # Total = 3
        expect(resource.reload.last_30_day_usage_count).to eq(3)
      end

      it 'updates component usage counts' do
        expect(component_a.reload.last_30_day_usage_count).to eq(2)  # used by project1 and project2 in last 30 days
        expect(component_b.reload.last_30_day_usage_count).to eq(1)  # used by project1 only in last 30 days
      end
    end

    context 'when filtering by date' do
      let_it_be(:project3) { create(:project) }

      it 'only counts usage from the last 30 days' do
        create(:catalog_resource_component_last_usage,
          component: component_a,
          used_by_project_id: project1.id,
          last_used_date: 15.days.ago.to_date  # Within 30 days
        )
        create(:catalog_resource_component_last_usage,
          component: component_a,
          used_by_project_id: project2.id,
          last_used_date: 5.days.ago.to_date   # Within 30 days
        )
        create(:catalog_resource_component_last_usage,
          component: component_a,
          used_by_project_id: project3.id,
          last_used_date: 35.days.ago.to_date  # Older than 30 days - should not count
        )

        service.execute

        expect(component_a.reload.last_30_day_usage_count).to eq(2)
        expect(resource.reload.last_30_day_usage_count).to eq(2)
      end
    end

    context 'when there are no components' do
      let_it_be(:resources) { create_list(:ci_catalog_resource, 4).sort_by(&:id) }

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
