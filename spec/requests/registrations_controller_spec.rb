# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsController, :with_current_organization, type: :request, feature_category: :system_access do
  describe '#create' do
    let_it_be(:user_attrs) { build_stubbed(:user).slice(:first_name, :last_name, :username, :email, :password) }
    let(:expected_context) do
      { 'meta.caller_id' => 'RegistrationsController#create' }
    end

    subject(:request) { post user_registration_path, params: { user: user_attrs } }

    it_behaves_like 'Base action controller'
    it_behaves_like 'set_current_context'

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

    context 'with user_detail built' do
      it 'creates the user_detail record' do
        expect { request }.to change { UserDetail.count }.by(1)
      end
    end
  end

  describe '#destroy' do
    let(:user) { create(:user) }
    let(:expected_context) do
      { 'meta.caller_id' => 'RegistrationsController#destroy',
        'meta.user' => user.username }
    end

    subject do
      sign_in(user)
      delete user_registration_path
    end

    include_examples 'set_current_context'
  end
end
