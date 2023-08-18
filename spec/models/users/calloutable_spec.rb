# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Calloutable, feature_category: :shared do
  subject { build(:callout) }

  describe "Associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
  end

  describe '#dismissed_after?' do
    let(:some_feature_name) { Users::Callout.feature_names.keys.second }
    let(:callout_dismissed_month_ago) { create(:callout, feature_name: some_feature_name, dismissed_at: 1.month.ago) }
    let(:callout_dismissed_day_ago) { create(:callout, feature_name: some_feature_name, dismissed_at: 1.day.ago) }

    it 'returns whether a callout dismissed after specified date' do
      expect(callout_dismissed_month_ago.dismissed_after?(15.days.ago)).to eq(false)
      expect(callout_dismissed_day_ago.dismissed_after?(15.days.ago)).to eq(true)
    end
  end
end
