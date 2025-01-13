# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authn::PersonalAccessTokenLastUsedIp, feature_category: :system_access do
  describe 'associations' do
    subject { build(:personal_access_token_last_used_ip) }

    it { is_expected.to belong_to(:personal_access_token) }
  end
end
