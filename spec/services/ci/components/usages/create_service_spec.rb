# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Components::Usages::CreateService, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:component1) { create(:ci_catalog_resource_component) }
  let_it_be(:component2) { create(:ci_catalog_resource_component) }
  let_it_be(:component3) { create(:ci_catalog_resource_component) }

  let(:catalog_components) do
    [
      { component: component1, component_project: component1.project },
      { component: component2, component_project: component2.project }
    ]
  end

  let(:service) { described_class.new(catalog_components, used_by_project: project) }

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'when catalog_components is empty' do
      let(:catalog_components) { [] }

      it 'returns success without creating any records' do
        expect { execute }.not_to change { Ci::Catalog::Resources::Components::LastUsage.count }
        expect(execute).to be_success
        expect(execute.message).to eq('No components to process')
      end
    end

    context 'when creating new usage records', :freeze_time do
      it 'creates usage records for all components', :aggregate_failures do
        expect { execute }.to change { Ci::Catalog::Resources::Components::LastUsage.count }.by(2)
        expect(execute).to be_success
        expect(execute.message).to eq('Usages recorded')

        last_usage1 = Ci::Catalog::Resources::Components::LastUsage.find_by(
          component: component1,
          used_by_project_id: project.id
        )
        last_usage2 = Ci::Catalog::Resources::Components::LastUsage.find_by(
          component: component2,
          used_by_project_id: project.id
        )

        expect(last_usage1.last_used_date).to eq(Time.current.to_date)
        expect(last_usage2.last_used_date).to eq(Time.current.to_date)
        expect(last_usage1.catalog_resource_id).to eq(component1.catalog_resource_id)
        expect(last_usage2.catalog_resource_id).to eq(component2.catalog_resource_id)
      end
    end

    context 'when updating existing usage records', :freeze_time do
      let!(:existing_last_usage1) do
        create(:catalog_resource_component_last_usage,
          component: component1,
          used_by_project_id: project.id,
          last_used_date: Time.current.to_date - 3.days)
      end

      let!(:existing_last_usage2) do
        create(:catalog_resource_component_last_usage,
          component: component2,
          used_by_project_id: project.id,
          last_used_date: Time.current.to_date - 5.days)
      end

      it 'updates the last_used_date for existing records' do
        expect { execute }.not_to change { Ci::Catalog::Resources::Components::LastUsage.count }

        existing_last_usage1.reload
        existing_last_usage2.reload

        expect(existing_last_usage1.last_used_date).to eq(Time.current.to_date)
        expect(existing_last_usage2.last_used_date).to eq(Time.current.to_date)
      end
    end

    context 'when mixing new and existing usage records', :freeze_time do
      let!(:existing_last_usage) do
        create(:catalog_resource_component_last_usage,
          component: component1,
          used_by_project_id: project.id,
          last_used_date: Time.current.to_date - 3.days)
      end

      it 'updates existing records and creates new ones', :aggregate_failures do
        expect { execute }.to change { Ci::Catalog::Resources::Components::LastUsage.count }.by(1)

        existing_last_usage.reload
        expect(existing_last_usage.last_used_date).to eq(Time.current.to_date)

        new_last_usage = Ci::Catalog::Resources::Components::LastUsage.find_by(
          component: component2,
          used_by_project_id: project.id
        )
        expect(new_last_usage.last_used_date).to eq(Time.current.to_date)
      end
    end

    it 'avoids N+1 database queries' do
      # First run creates LastUsage record for component1
      create(:catalog_resource_component_last_usage,
        component: component1,
        used_by_project_id: project.id,
        last_used_date: Time.current.to_date - 3.days)

      # Control run with 2 components (component1 update + component2 insert)
      control = ActiveRecord::QueryRecorder.new do
        described_class.new(catalog_components, used_by_project: project).execute
      end

      catalog_components_with_three = catalog_components + [
        { component: component3, component_project: component3.project }
      ]

      # This run has: component1 update + component2 update + component3 insert
      expect do
        described_class.new(catalog_components_with_three, used_by_project: project).execute
      end.not_to exceed_query_limit(control)
    end
  end
end
