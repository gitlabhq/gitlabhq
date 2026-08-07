# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::BundledResources::Component, feature_category: :pipeline_composition do
  describe 'associations' do
    it { is_expected.to belong_to(:bundled_resource).class_name('Ci::Catalog::BundledResource').required }
    it { is_expected.to belong_to(:version).class_name('Ci::Catalog::BundledResources::Version').required }
  end

  describe 'validations' do
    subject(:component) { build(:ci_catalog_bundled_resource_component) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:catalog_bundled_version_id) }

    it { is_expected.to allow_values('deploy', 'deploy-v2', 'deploy_v2', 'deploy.v2').for(:name) }

    it 'rejects names that would not compose into a single object-storage path segment' do
      expect(component).not_to allow_values('deploy/v2', '../deploy', 'deploy v2', "deploy\nv2").for(:name)
    end

    it 'accepts a spec matching the component spec json schema' do
      component.spec = { inputs: { website: { type: 'string' } } }

      expect(component).to be_valid
    end

    it 'rejects a spec with disallowed properties' do
      component.spec = { not_a_real_key: true }

      expect(component).not_to be_valid
    end
  end
end
