# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Components::Usages::CreateService, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:component) { create(:ci_catalog_resource_component) }

  let(:service) { described_class.new(component, used_by_project: project) }

  describe '#execute' do
    subject(:execute) { service.execute }

    it 'creates a usage record and updates last_usage', :aggregate_failures do
      expect { execute }.to change { Ci::Catalog::Resources::Components::LastUsage.count }.by(1)
      expect(execute).to be_success
      expect(execute.message).to eq('Usage recorded')

      last_usage = Ci::Catalog::Resources::Components::LastUsage.find_by(component: component,
        used_by_project_id: project.id)

      expect(last_usage.last_used_date).to be_present
    end

    context 'when usage has already been recorded', :freeze_time do
      let!(:existing_last_usage) do
        create(:catalog_resource_component_last_usage,
          component: component, used_by_project_id: project.id, last_used_date: Time.current.to_date - 3.days)
      end

      it 'updates the last_used_date for the existing last_usage record' do
        expect { execute }.not_to change { Ci::Catalog::Resources::Components::LastUsage.count }

        last_usage = Ci::Catalog::Resources::Components::LastUsage.find_by(component: component,
          used_by_project_id: project.id)
        expect(last_usage.last_used_date).to eq(Time.current.to_date)
      end
    end
  end
end
