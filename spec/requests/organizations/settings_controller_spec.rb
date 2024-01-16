# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::SettingsController, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }

  describe 'GET #general' do
    subject(:gitlab_request) { get general_settings_organization_path(organization) }

    context 'when the user is not signed in' do
      it_behaves_like 'organization - redirects to sign in page'

      context 'when `ui_for_organizations` feature flag is disabled' do
        before do
          stub_feature_flags(ui_for_organizations: false)
        end

        it_behaves_like 'organization - redirects to sign in page'
      end
    end

    context 'when the user is signed in' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      context 'with no association to an organization' do
        it_behaves_like 'organization - not found response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end

      context 'as as admin', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end

      context 'as a default organization user' do
        before_all do
          create(:organization_user, organization: organization, user: user)
        end

        it_behaves_like 'organization - not found response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end

      context 'as an owner of an organization' do
        before_all do
          create(:organization_user, :owner, organization: organization, user: user)
        end

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end
    end
  end
end
