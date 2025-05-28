# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUserAlias, type: :model, feature_category: :organization do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).inverse_of(:organization_user_aliases).required }
    it { is_expected.to belong_to(:user).inverse_of(:organization_user_aliases).required }
  end

  describe 'validations' do
    subject { build(:organization_user_alias) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).scoped_to(:organization_id) }
  end
end
