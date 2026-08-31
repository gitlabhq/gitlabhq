# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Organizations::FallbackOrganizationTracker, :request_store, feature_category: :organization do
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
    subject(:trigger) { described_class.trigger }

    context 'when disabled' do
      before do
        described_class.disable
      end

      it 'does not push organization_source to the application context' do
        expect(Gitlab::ApplicationContext).not_to receive(:push).with(hash_including(:organization_source))

        trigger
      end
    end

    context 'when enabled' do
      before do
        described_class.enable
      end

      it 'pushes organization_source to the application context' do
        expect(Gitlab::ApplicationContext).to receive(:push).with(organization_source: 'fallback')

        trigger
      end

      context 'when `track_organization_fallback` flag is disabled' do
        before do
          stub_feature_flags(track_organization_fallback: false)
        end

        it 'does not push organization_source to the application context' do
          expect(Gitlab::ApplicationContext).not_to receive(:push).with(hash_including(:organization_source))

          trigger
        end
      end

      context 'when called multiple times' do
        it 'pushes organization_source only once' do
          expect(Gitlab::ApplicationContext).to receive(:push).with(organization_source: 'fallback').once

          3.times { described_class.trigger }
        end
      end
    end
  end

  describe '.without_tracking' do
    subject(:trigger) { described_class.without_tracking { described_class.trigger } }

    context 'when disabled' do
      before do
        described_class.disable
      end

      it 'does not push organization_source to the application context' do
        expect(Gitlab::ApplicationContext).not_to receive(:push).with(hash_including(:organization_source))

        trigger
      end
    end

    context 'when enabled' do
      before do
        described_class.enable
      end

      it 'does not push organization_source to the application context' do
        expect(Gitlab::ApplicationContext).not_to receive(:push).with(hash_including(:organization_source))

        trigger
      end

      it 'does not disable the tracker outside of the block' do
        trigger

        expect(described_class.enabled?).to be(true)
      end
    end
  end
end
