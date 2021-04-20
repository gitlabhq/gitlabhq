# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserCallout do
  let!(:callout) { create(:user_callout) }

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }

    it { is_expected.to validate_presence_of(:feature_name) }
    it { is_expected.to validate_uniqueness_of(:feature_name).scoped_to(:user_id).ignoring_case_sensitivity }
  end

  describe '#dismissed_after?' do
    let(:some_feature_name) { described_class.feature_names.keys.second }
    let(:callout_dismissed_month_ago) { create(:user_callout, feature_name: some_feature_name, dismissed_at: 1.month.ago )}
    let(:callout_dismissed_day_ago) { create(:user_callout, feature_name: some_feature_name, dismissed_at: 1.day.ago )}

    it 'returns whether a callout dismissed after specified date' do
      expect(callout_dismissed_month_ago.dismissed_after?(15.days.ago)).to eq(false)
      expect(callout_dismissed_day_ago.dismissed_after?(15.days.ago)).to eq(true)
    end
  end
end
