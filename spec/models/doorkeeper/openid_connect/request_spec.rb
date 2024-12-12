# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Doorkeeper::OpenidConnect::Request, type: :model, feature_category: :system_access do
  describe 'associations' do
    it { is_expected.to belong_to(:access_grant).class_name('Doorkeeper::AccessGrant').inverse_of(:openid_request) }
    it { is_expected.to belong_to(:organization).class_name('Organizations::Organization').optional(false) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:access_grant_id) }
    it { is_expected.to validate_presence_of(:nonce) }
  end
end
