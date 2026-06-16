# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::OauthApplicationPolicy, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:application) { create(:oauth_application, owner: user) }

  subject { described_class.new(current_user, application) }

  context 'when user is the owner' do
    let(:current_user) { user }

    it { expect_allowed(:read_oauth_application) }
    it { expect_allowed(:update_oauth_application) }
    it { expect_allowed(:delete_oauth_application) }
  end

  context 'when user is not the owner' do
    let(:current_user) { other_user }

    it { expect_disallowed(:read_oauth_application) }
    it { expect_disallowed(:update_oauth_application) }
    it { expect_disallowed(:delete_oauth_application) }
  end
end
