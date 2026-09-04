# frozen_string_literal: true

require 'spec_helper'

# SaaS features are left unstubbed, so these hold under FOSS (no EE module) and
# under EE (SaaS gate closed). The flag matrix is covered in the EE spec.
RSpec.describe Gitlab::RackAttack::LabkitRateLimit::PlanRules, feature_category: :rate_limiting do
  # Guarded because the EE override returns the eight real names.
  describe '.flags', unless: Gitlab.ee? do
    it 'is empty, so the suite-wide stub names no undefined flag' do
      expect(described_class.flags).to eq([])
    end
  end

  describe '.active?' do
    it 'is false when the tier-aware limits cannot apply' do
      expect(described_class.active?).to be(false)
    end

    it 'does not read a feature flag before ruling the limits out' do
      expect(::Feature).not_to receive(:enabled?)

      described_class.active?
    end
  end
end
