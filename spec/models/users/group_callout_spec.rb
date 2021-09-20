# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::GroupCallout do
  let_it_be(:user) { create_default(:user) }
  let_it_be(:group) { create_default(:group) }
  let_it_be(:callout) { create(:group_callout) }

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:feature_name) }
    it { is_expected.to validate_uniqueness_of(:feature_name).scoped_to(:user_id, :group_id).ignoring_case_sensitivity }
  end

  describe '#source_feature_name' do
    it 'provides string based off source and feature' do
      expect(callout.source_feature_name).to eq "#{callout.feature_name}_#{callout.group_id}"
    end
  end
end
