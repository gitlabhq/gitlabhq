# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlags::ClientConfigurationEntity, factory_default: :keep, feature_category: :feature_flags do
  let_it_be(:project) { create_default(:project) }
  let(:feature_flags_client) { project.create_operations_feature_flags_client! }
  let(:entity) { described_class.new(feature_flags_client) }

  describe '#to_json' do
    subject(:json) { entity.to_json }

    it 'matches schema' do
      expect(json).to match_schema('feature_flags/client_configuration')
    end
  end
end
