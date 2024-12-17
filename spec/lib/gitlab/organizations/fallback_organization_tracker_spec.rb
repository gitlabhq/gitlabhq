# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Organizations::FallbackOrganizationTracker, :request_store, feature_category: :cell do
  shared_examples 'tracker that is enabled' do
    before do
      described_class.enable
    end

    specify { expect(described_class.enabled?).to be(true) }
  end

  shared_examples 'tracker that is disabled' do
    before do
      described_class.disable
    end

    specify { expect(described_class.enabled?).to be(false) }
  end

  describe '.enable' do
    it_behaves_like 'tracker that is enabled'
  end

  describe '.disable' do
    it_behaves_like 'tracker that is disabled'
  end

  describe '.enabled?' do
    it_behaves_like 'tracker that is enabled'
    it_behaves_like 'tracker that is disabled'
  end

  describe '.trigger' do
    let_it_be(:event) { 'fallback_current_organization_to_default' }
    let_it_be(:category) { 'Organizations' }

    subject { described_class.trigger }

    context 'when disabled' do
      before do
        described_class.disable
      end

      it_behaves_like 'internal event not tracked'
    end

    context 'when enabled' do
      before do
        described_class.enable
      end

      it_behaves_like 'internal event tracking'

      context 'when `track_organization_fallback` flag is disabled' do
        before do
          stub_feature_flags(track_organization_fallback: false)
        end

        it_behaves_like 'internal event not tracked'
      end
    end
  end

  describe '.without_tracking' do
    subject(:trigger) { described_class.without_tracking { described_class.trigger } }

    context 'when disabled' do
      before do
        described_class.disable
      end

      it_behaves_like 'internal event not tracked'
    end

    context 'when enabled' do
      before do
        described_class.enable
      end

      it_behaves_like 'internal event not tracked'

      it 'does not disable the tracker outside of the block' do
        trigger

        expect(described_class.enabled?).to be(true)
      end
    end
  end
end
