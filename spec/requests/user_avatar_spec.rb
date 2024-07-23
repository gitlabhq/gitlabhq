# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Loading a user avatar', feature_category: :user_profile do
  let_it_be(:organization) { create(:organization) }
  let(:user) { create(:user, :with_avatar, organizations: [organization]) }

  context 'when logged in' do
    # The exact query count will vary depending on the 2FA settings of the
    # instance, group, and user. Removing those extra 2FA queries in this case
    # may not be a good idea, so we just set up the ideal case.
    before do
      stub_application_setting(require_two_factor_authentication: true)

      login_as(create(:user, :two_factor, organizations: [organization]))
    end

    # One each for: current user, current organization, avatar user, and upload record
    it 'only performs four SQL queries' do
      get user.avatar_url # Skip queries on first application load

      expect(response).to have_gitlab_http_status(:ok)
      expect { get user.avatar_url }.not_to exceed_query_limit(4)
    end
  end

  context 'when logged out' do
    # One each for avatar user and upload record
    it 'only performs two SQL queries' do
      get user.avatar_url # Skip queries on first application load

      expect(response).to have_gitlab_http_status(:ok)
      expect { get user.avatar_url }.not_to exceed_query_limit(3)
    end
  end
end
