# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUserDetail, type: :model, feature_category: :cell do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).inverse_of(:organization_user_details).required }
    it { is_expected.to belong_to(:user).inverse_of(:organization_user_details).required }
  end

  describe 'validations' do
    subject { build(:organization_user_detail) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:display_name) }
    it { is_expected.to validate_uniqueness_of(:username).scoped_to(:organization_id) }
  end
end
