# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsController, type: :request, feature_category: :system_access do
  describe 'POST #create' do
    let_it_be(:user_attrs) { build_stubbed(:user).slice(:first_name, :last_name, :username, :email, :password) }

    subject(:request) { post user_registration_path, params: { user: user_attrs } }

    it_behaves_like 'Base action controller'

    context 'when email confirmation is required' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'hard')
        stub_application_setting(require_admin_approval_after_user_signup: false)
      end

      it 'redirects to the `users_almost_there_path`', unless: Gitlab.ee? do
        request

        expect(response).to redirect_to(users_almost_there_path(email: user_attrs[:email]))
      end
    end
  end
end
