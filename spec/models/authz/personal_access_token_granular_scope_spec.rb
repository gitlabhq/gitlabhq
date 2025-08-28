# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::PersonalAccessTokenGranularScope, feature_category: :permissions do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).required }
    it { is_expected.to belong_to(:personal_access_token).required }
    it { is_expected.to belong_to(:granular_scope).required }
  end
end
