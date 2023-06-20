# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Warden", feature_category: :system_access do
  describe "rate limit" do
    include_context 'unique ips sign in limit'
    let(:user) { create(:user) }

    before do
      # Set the rate limit to 1 request per IP address per user.
      stub_application_setting(unique_ips_limit_per_user: 1)
      sign_in(user)
    end

    it 'limits the number of requests that can be made from a single IP address per user' do
      change_ip('ip1')
      get user_path(user)
      expect(response).to be_successful

      change_ip('ip2')
      get user_path(user)
      expect(response).to be_forbidden
    end
  end
end
