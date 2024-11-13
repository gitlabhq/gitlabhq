# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Components::LastUsage, type: :model, feature_category: :pipeline_composition do
  let_it_be(:component) { create(:ci_catalog_resource_component) }
  let(:component_usage) { build(:catalog_resource_component_last_usage, component: component) }

  it { is_expected.to belong_to(:component).class_name('Ci::Catalog::Resources::Component') }
  it { is_expected.to belong_to(:catalog_resource).class_name('Ci::Catalog::Resource') }
  it { is_expected.to belong_to(:component_project).class_name('Project') }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:component) }
    it { is_expected.to validate_presence_of(:last_used_date) }
    it { is_expected.to validate_presence_of(:catalog_resource) }
    it { is_expected.to validate_presence_of(:component_project) }
    it { is_expected.to validate_presence_of(:used_by_project_id) }

    it 'validates uniqueness of last_used_date' do
      component_usage.save!

      expect(component_usage).to validate_uniqueness_of(:last_used_date)
        .scoped_to([:component_id, :used_by_project_id])
    end

    it 'validates uniqueness of the index' do
      component_usage = described_class.create!(
        component: component,
        catalog_resource: component.catalog_resource,
        component_project: component.project,
        used_by_project_id: 1,
        last_used_date: Time.zone.today
      )

      expect do
        described_class.create!(
          component: component_usage.component,
          catalog_resource: component_usage.catalog_resource,
          component_project: component_usage.component_project,
          used_by_project_id: component_usage.used_by_project_id,
          last_used_date: component_usage.last_used_date
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    describe '.get_usage_for' do
      let_it_be(:used_by_project) { create(:project) }

      context 'when no record exists' do
        it 'initializes a new record' do
          last_usage = described_class.get_usage_for(component, used_by_project)

          expect(last_usage).to be_a_new_record
          expect(last_usage.component).to eq(component)
          expect(last_usage.catalog_resource).to eq(component.catalog_resource)
          expect(last_usage.component_project).to eq(component.project)
          expect(last_usage.used_by_project_id).to eq(used_by_project.id)
        end
      end

      context 'when a record exists' do
        let!(:existing_record) do
          create(:catalog_resource_component_last_usage,
            component: component,
            catalog_resource: component.catalog_resource,
            component_project: component.project,
            used_by_project_id: used_by_project.id)
        end

        it 'returns the existing record' do
          last_usage = described_class.get_usage_for(component, used_by_project)

          expect(last_usage).not_to be_a_new_record
          expect(last_usage).to eq(existing_record)
        end
      end
    end
  end
end
