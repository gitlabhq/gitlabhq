# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Callout do
  let_it_be(:callout) { create(:callout) }

  it_behaves_like 'having unique enum values'

  describe 'validations' do
    it { is_expected.to validate_presence_of(:feature_name) }
    it { is_expected.to validate_uniqueness_of(:feature_name).scoped_to(:user_id).ignoring_case_sensitivity }
  end

  describe 'scopes' do
    describe '.with_feature_name' do
      let_it_be(:feature_name) { described_class.feature_names.keys.last }
      let_it_be(:user_callouts_for_feature_name) { create_list(:callout, 2, feature_name: feature_name) }
      let_it_be(:another_user_callout) { create(:callout, feature_name: described_class.feature_names.each_key.first) }

      it 'returns user callouts for the given feature name only' do
        expect(described_class.with_feature_name(feature_name)).to eq(user_callouts_for_feature_name)
      end
    end
  end
end
