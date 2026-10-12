# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Doorkeeper::AccessGrant, feature_category: :system_access do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).class_name('Organizations::Organization').optional(false) }
    it { is_expected.to have_one(:openid_request).class_name('Doorkeeper::OpenidConnect::Request') }
  end

  it_behaves_like 'a Doorkeeper model stuck to the database load balancer' do
    let(:namespace) { :oauth_grant }
    let(:record) { create(:oauth_access_grant) }
    let(:lookups) { { by_token: record.plaintext_token } }
    let(:expected_stuck_secrets) { [record.plaintext_token] }
  end
end
