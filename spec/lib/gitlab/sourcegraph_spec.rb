# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Sourcegraph do
  let_it_be(:user) { create(:user) }
  let(:feature_scope) { true }

  before do
    Feature.enable(:sourcegraph, feature_scope)
  end

  describe '.feature_conditional?' do
    subject { described_class.feature_conditional? }

    context 'when feature is enabled globally' do
      it { is_expected.to be_falsey }
    end

    context 'when feature is enabled only to a resource' do
      let(:feature_scope) { user }

      it { is_expected.to be_truthy }
    end
  end

  describe '.feature_available?' do
    subject { described_class.feature_available? }

    context 'when feature is enabled globally' do
      it { is_expected.to be_truthy }
    end

    context 'when feature is enabled only to a resource' do
      let(:feature_scope) { user }

      it { is_expected.to be_truthy }
    end
  end

  describe '.feature_enabled?' do
    let(:current_user) { nil }

    subject { described_class.feature_enabled?(current_user) }

    context 'when feature is enabled globally' do
      it { is_expected.to be_truthy }
    end

    context 'when feature is enabled only to a resource' do
      let(:feature_scope) { user }

      context 'for the same resource' do
        let(:current_user) { user }

        it { is_expected.to be_truthy }
      end

      context 'for a different resource' do
        let(:current_user) { create(:user) }

        it { is_expected.to be_falsey }
      end
    end
  end
end
