# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PasswordsController, :with_current_organization, type: :request, feature_category: :system_access do
  describe '#edit' do
    let_it_be_with_reload(:user) { create(:user) }
    let(:reset_password_token) { user.send_reset_password_instructions }

    subject(:perform_request) do
      get edit_user_password_path, params: {
        reset_password_token: reset_password_token
      }
    end

    it 'shows edit page' do
      perform_request

      expect(response).to be_ok
    end

    context 'when reset password token has expired' do
      before do
        travel_to 100.days.ago do
          reset_password_token
        end
      end

      it 'warns the user the reset token is expired' do
        perform_request

        expect(response).to redirect_to(new_user_password_url(user_email: user.email))
        expect(flash[:alert]).to eq('Your password reset token has expired.')
      end
    end

    context 'when user cannot be found because incorrect organization specified' do
      let(:another_organization) { create(:organization) }

      before do
        stub_current_organization(another_organization)
      end

      it 'redirects to password reset page' do
        perform_request

        expect(response).to redirect_to(new_user_password_url(user_email: ''))
        expect(flash[:alert]).to eq('Your password reset token has expired.')
      end
    end
  end

  describe '#update' do
    let(:user) { create(:user, password_automatically_set: true, password_expires_at: 10.minutes.ago) }
    let(:expected_context) do
      { 'meta.caller_id' => 'PasswordsController#update',
        'meta.user' => user.username }
    end

    let(:password) { User.random_password }
    let(:reset_password_token) { user.send_reset_password_instructions }

    subject(:perform_request) do
      put user_password_path, params: {
        user: {
          password: password,
          password_confirmation: password,
          reset_password_token: reset_password_token
        }
      }
    end

    include_examples 'set_current_context'

    it 'updates the password' do
      expect { perform_request }.to change { user.reload.encrypted_password }

      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when reset_password_token is expired' do
      before do
        travel_to 100.days.ago do
          reset_password_token
        end
      end

      it 'does not update the password' do
        expect { perform_request }.not_to change { user.reload.encrypted_password }
      end
    end

    context 'when user cannot be found because incorrect organization specified' do
      let(:another_organization) { create(:organization) }

      before do
        stub_current_organization(another_organization)
      end

      it 'does not update the password' do
        expect { perform_request }.not_to change { user.reload.encrypted_password }

        expect(response.body).to include('errors prohibited this user from being saved')
      end
    end
  end
end
