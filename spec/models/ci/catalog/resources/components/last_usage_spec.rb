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
  end

  describe '.for_catalog_resource_with_component_versions' do
    let_it_be(:catalog_resource) { component.catalog_resource }
    let_it_be(:other_catalog_resource) { create(:ci_catalog_resource) }
    let_it_be(:other_component) { create(:ci_catalog_resource_component, catalog_resource: other_catalog_resource) }

    let_it_be(:usage) do
      create(:catalog_resource_component_last_usage, component: component, catalog_resource: catalog_resource)
    end

    let_it_be(:other_usage) do
      create(:catalog_resource_component_last_usage, component: other_component,
        catalog_resource: other_catalog_resource)
    end

    it 'returns usages for the given catalog resource' do
      result = described_class.for_catalog_resource_with_component_versions(catalog_resource.id)

      expect(result).to contain_exactly(usage)
    end

    it 'eager loads component and version associations' do
      result = described_class.for_catalog_resource_with_component_versions(catalog_resource.id).to_a

      recorder = ActiveRecord::QueryRecorder.new { result.first.component.version }
      expect(recorder.count).to eq(0)
    end

    it 'returns empty when no usages exist for the given catalog resource' do
      result = described_class.for_catalog_resource_with_component_versions(non_existing_record_id)

      expect(result).to be_empty
    end
  end

  describe '.by_version_ids' do
    let_it_be(:catalog_resource) { create(:ci_catalog_resource) }
    let_it_be(:version_a) { create(:ci_catalog_resource_version, catalog_resource: catalog_resource) }
    let_it_be(:version_b) { create(:ci_catalog_resource_version, catalog_resource: catalog_resource) }
    let_it_be(:version_c) { create(:ci_catalog_resource_version, catalog_resource: catalog_resource) }
    let_it_be(:component_in_version_a) do
      create(:ci_catalog_resource_component, catalog_resource: catalog_resource, version: version_a, name: 'comp')
    end

    let_it_be(:component_in_version_b) do
      create(:ci_catalog_resource_component, catalog_resource: catalog_resource, version: version_b, name: 'comp')
    end

    let_it_be(:component_in_version_c) do
      create(:ci_catalog_resource_component, catalog_resource: catalog_resource, version: version_c, name: 'comp')
    end

    let_it_be(:usage_in_version_a) do
      create(:catalog_resource_component_last_usage,
        component: component_in_version_a, catalog_resource: catalog_resource)
    end

    let_it_be(:usage_in_version_b) do
      create(:catalog_resource_component_last_usage,
        component: component_in_version_b, catalog_resource: catalog_resource)
    end

    let_it_be(:usage_in_version_c) do
      create(:catalog_resource_component_last_usage,
        component: component_in_version_c, catalog_resource: catalog_resource)
    end

    it 'returns only usages whose component belongs to a single given version' do
      expect(described_class.by_version_ids([version_a.id])).to contain_exactly(usage_in_version_a)
    end

    it 'returns usages whose component belongs to any of the given versions' do
      expect(described_class.by_version_ids([version_a.id, version_c.id]))
        .to contain_exactly(usage_in_version_a, usage_in_version_c)
    end

    it 'returns empty when none of the given versions have matching usages' do
      empty_version = create(:ci_catalog_resource_version, catalog_resource: catalog_resource)

      expect(described_class.by_version_ids([empty_version.id])).to be_empty
    end

    it 'composes with for_catalog_resource_with_component_versions' do
      result = described_class
        .for_catalog_resource_with_component_versions(catalog_resource.id)
        .by_version_ids([version_b.id])

      expect(result).to contain_exactly(usage_in_version_b)
    end
  end

  describe '.by_version_id' do
    let_it_be(:catalog_resource) { create(:ci_catalog_resource) }
    let_it_be(:version_a) { create(:ci_catalog_resource_version, catalog_resource: catalog_resource) }
    let_it_be(:version_b) { create(:ci_catalog_resource_version, catalog_resource: catalog_resource) }
    let_it_be(:component_in_version_a) do
      create(:ci_catalog_resource_component, catalog_resource: catalog_resource, version: version_a, name: 'comp')
    end

    let_it_be(:component_in_version_b) do
      create(:ci_catalog_resource_component, catalog_resource: catalog_resource, version: version_b, name: 'comp')
    end

    let_it_be(:usage_in_version_a) do
      create(:catalog_resource_component_last_usage,
        component: component_in_version_a, catalog_resource: catalog_resource)
    end

    let_it_be(:usage_in_version_b) do
      create(:catalog_resource_component_last_usage,
        component: component_in_version_b, catalog_resource: catalog_resource)
    end

    it 'returns only usages whose component belongs to the given version' do
      expect(described_class.by_version_id(version_a.id)).to contain_exactly(usage_in_version_a)
    end

    it 'returns empty when the version has no matching usages' do
      empty_version = create(:ci_catalog_resource_version, catalog_resource: catalog_resource)

      expect(described_class.by_version_id(empty_version.id)).to be_empty
    end

    it 'composes with for_catalog_resource_with_component_versions' do
      result = described_class
        .for_catalog_resource_with_component_versions(catalog_resource.id)
        .by_version_id(version_b.id)

      expect(result).to contain_exactly(usage_in_version_b)
    end
  end

  describe '.by_component_name' do
    let_it_be(:catalog_resource) { create(:ci_catalog_resource) }
    let_it_be(:version_a) { create(:ci_catalog_resource_version, catalog_resource: catalog_resource) }
    let_it_be(:version_b) { create(:ci_catalog_resource_version, catalog_resource: catalog_resource) }
    let_it_be(:rails_in_v_a) do
      create(:ci_catalog_resource_component, catalog_resource: catalog_resource, version: version_a, name: 'rails')
    end

    let_it_be(:rails_in_v_b) do
      create(:ci_catalog_resource_component, catalog_resource: catalog_resource, version: version_b, name: 'rails')
    end

    let_it_be(:node_in_v_a) do
      create(:ci_catalog_resource_component, catalog_resource: catalog_resource, version: version_a, name: 'node')
    end

    let_it_be(:rails_usage_v_a) do
      create(:catalog_resource_component_last_usage, component: rails_in_v_a, catalog_resource: catalog_resource)
    end

    let_it_be(:rails_usage_v_b) do
      create(:catalog_resource_component_last_usage, component: rails_in_v_b, catalog_resource: catalog_resource)
    end

    let_it_be(:node_usage_v_a) do
      create(:catalog_resource_component_last_usage, component: node_in_v_a, catalog_resource: catalog_resource)
    end

    it 'returns usages for the named component across all versions' do
      expect(described_class.by_component_name('rails')).to contain_exactly(rails_usage_v_a, rails_usage_v_b)
    end

    it 'is case-sensitive' do
      expect(described_class.by_component_name('RAILS')).to be_empty
    end

    it 'returns empty when the component name does not exist' do
      expect(described_class.by_component_name('does-not-exist')).to be_empty
    end

    it 'composes with by_version_id' do
      result = described_class.by_component_name('rails').by_version_id(version_a.id)

      expect(result).to contain_exactly(rails_usage_v_a)
    end

    it 'composes with by_version_ids' do
      result = described_class.by_component_name('rails').by_version_ids([version_a.id])

      expect(result).to contain_exactly(rails_usage_v_a)
    end
  end
end
