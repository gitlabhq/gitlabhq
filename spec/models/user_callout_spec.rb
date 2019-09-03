# frozen_string_literal: true

require 'spec_helper'

describe UserCallout do
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
end
