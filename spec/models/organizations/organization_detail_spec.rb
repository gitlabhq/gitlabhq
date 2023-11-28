# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationDetail, type: :model, feature_category: :cell do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).inverse_of(:organization_detail) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:organization) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  end
end
