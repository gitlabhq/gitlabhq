# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authn::ServiceAccounts, feature_category: :system_access do
  describe 'LIMIT_FOR_FREE' do
    it 'is set to 100' do
      expect(described_class::LIMIT_FOR_FREE).to eq(100)
    end
  end

  describe 'LIMIT_FOR_TRIAL' do
    it 'is set to 100' do
      expect(described_class::LIMIT_FOR_TRIAL).to eq(100)
    end
  end

  describe '.creation_allowed_for_saas?', unless: Gitlab.ee? do
    it 'returns true regardless of arguments' do
      expect(described_class.creation_allowed_for_saas?).to be(true)
    end
  end

  describe '.free_tier?', unless: Gitlab.ee? do
    it 'returns true in CE (no license)' do
      expect(described_class.free_tier?).to be(true)
    end
  end

  describe '.free_tier_namespace?', unless: Gitlab.ee? do
    it 'returns false in CE (no SaaS subscription concept)' do
      expect(described_class.free_tier_namespace?(nil)).to be(false)
    end
  end

  describe '.creation_allowed_for_sm?' do
    context 'when under the free tier limit' do
      it 'returns true' do
        expect(described_class.creation_allowed_for_sm?).to be(true)
      end
    end

    context 'when at the free tier limit' do
      before do
        stub_const('Authn::ServiceAccounts::LIMIT_FOR_FREE', 2)
        create_list(:user, 2, :service_account)
      end

      it 'returns false' do
        expect(described_class.creation_allowed_for_sm?).to be(false)
      end
    end
  end
end
