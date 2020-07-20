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

  describe 'scopes' do
    describe '.with_feature_name' do
      let(:second_feature_name) { described_class.feature_names.keys.second }
      let(:last_feature_name) { described_class.feature_names.keys.last }

      it 'returns callout for requested feature name only' do
        callout1 = create(:user_callout, feature_name: second_feature_name )
        create(:user_callout, feature_name: last_feature_name )

        callouts = described_class.with_feature_name(second_feature_name)

        expect(callouts).to match_array([callout1])
      end
    end

    describe '.with_dismissed_after' do
      let(:some_feature_name) { described_class.feature_names.keys.second }
      let(:callout_dismissed_month_ago) { create(:user_callout, feature_name: some_feature_name, dismissed_at: 1.month.ago )}

      it 'does not return callouts dismissed before specified date' do
        callouts = described_class.with_dismissed_after(15.days.ago)

        expect(callouts).to match_array([])
      end

      it 'returns callouts dismissed after specified date' do
        callouts = described_class.with_dismissed_after(2.months.ago)

        expect(callouts).to match_array([callout_dismissed_month_ago])
      end
    end
  end
end
