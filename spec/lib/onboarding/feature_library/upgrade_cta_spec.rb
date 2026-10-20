# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Onboarding::FeatureLibrary::UpgradeCta, feature_category: :onboarding, unless: Gitlab.ee? do
  %i[premium ultimate].each do |plan|
    it "has no call to action for the #{plan} page" do
      expect(described_class.new(user: nil, resource: nil, plan: plan).build).to be_nil
    end
  end
end
