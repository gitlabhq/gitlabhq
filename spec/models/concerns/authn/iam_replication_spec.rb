# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamReplication, feature_category: :system_access do
  describe '.enabled?' do
    it 'is enabled by default in the test environment' do
      expect(described_class.enabled?).to be(true)
    end

    context 'when the iam_data_replication flag is disabled' do
      before do
        stub_feature_flags(iam_data_replication: false)
      end

      it 'is disabled' do
        expect(described_class.enabled?).to be(false)
      end
    end
  end

  describe '.replicator_for' do
    it 'returns the replicator class for a known entity type' do
      expect(described_class.replicator_for('oauth_application'))
        .to eq(Authn::IamReplication::OauthApplicationReplicator)
    end

    it 'raises for an unknown entity type' do
      expect { described_class.replicator_for('unknown') }
        .to raise_error(ArgumentError, /unknown entity_type/)
    end
  end
end
