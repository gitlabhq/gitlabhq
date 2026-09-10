# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WebHooks::DuoFlowCallback, feature_category: :webhooks do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe '.available?' do
    subject(:available) { described_class.available?(project) }

    it 'is unavailable without a container' do
      expect(described_class.available?(nil)).to be(false)
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(duo_flow_callback_hooks: false)
      end

      it { is_expected.to be(false) }
    end

    context 'when the flag is enabled for a different namespace' do
      before do
        stub_feature_flags(duo_flow_callback_hooks: create(:group))
      end

      it { is_expected.to be(false) }
    end

    context 'when on FOSS', unless: Gitlab.ee? do
      it { is_expected.to be(false) }
    end
  end
end
