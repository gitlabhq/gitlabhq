# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::OrganizationsController, type: :request, feature_category: :cell do
  describe 'GET #index' do
    subject(:gitlab_request) { get admin_organizations_path }

    before do
      sign_in(user)
    end

    context 'as an admin', :enable_admin_mode do
      let_it_be(:user) { create(:admin) }

      it_behaves_like 'organization - successful response'
      it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
    end

    context 'as a regular user' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'organization - not found response'
      it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
    end
  end
end
