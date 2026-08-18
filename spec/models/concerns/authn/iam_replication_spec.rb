# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamReplication, feature_category: :system_access do
  describe '.enabled?' do
    it 'follows the iam_data_replication feature flag', :aggregate_failures do
      stub_feature_flags(iam_data_replication: false)
      expect(described_class.enabled?).to be(false)

      stub_feature_flags(iam_data_replication: true)
      expect(described_class.enabled?).to be(true)
    end
  end
end
