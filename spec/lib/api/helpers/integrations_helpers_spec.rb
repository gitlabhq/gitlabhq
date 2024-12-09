# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Helpers::IntegrationsHelpers, feature_category: :integrations do
  let(:base_classes) { Integration::BASE_CLASSES.map(&:constantize) }
  let(:development_classes) { [Integrations::MockCi, Integrations::MockMonitoring] }
  let(:instance_level_classes) { [Integrations::BeyondIdentity] }

  describe '.integrations' do
    it 'has correct integrations' do
      expect(described_class.integrations.keys.map(&:underscore))
        .to match_array(described_class.integration_classes.map(&:to_param))
    end
  end

  describe '.integration_classes' do
    it 'returns correct integrations', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444979' do
      expect(described_class.integration_classes)
        .to match_array(Integration.descendants.without(base_classes, development_classes, instance_level_classes))
    end
  end

  describe '.development_integration_classes' do
    it 'returns correct integrations' do
      expect(described_class.development_integration_classes).to eq(development_classes)
    end
  end

  describe '.inheritance_field' do
    it 'returns correct field' do
      expect(described_class.inheritance_field).to eq(
        {
          required: false,
          name: :use_inherited_settings,
          type: ::Grape::API::Boolean,
          desc: 'Indicates whether to inherit the default settings. Defaults to `false`.'
        }
      )
    end
  end
end
