# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserCallout do
  let_it_be(:callout) { create(:user_callout) }

  it_behaves_like 'having unique enum values'

  describe 'validations' do
    it { is_expected.to validate_presence_of(:feature_name) }
    it { is_expected.to validate_uniqueness_of(:feature_name).scoped_to(:user_id).ignoring_case_sensitivity }
  end
end
