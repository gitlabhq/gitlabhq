# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUser, type: :model, feature_category: :cell do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).inverse_of(:organization_users).required }
    it { is_expected.to belong_to(:user).inverse_of(:organization_users).required }
  end
end
