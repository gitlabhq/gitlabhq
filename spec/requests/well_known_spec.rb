# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'well-known URLs', feature_category: :shared do
  describe '/.well-known/change-password', feature_category: :system_access do
    it 'redirects to edit profile password path' do
      get('/.well-known/change-password')

      expect(response).to redirect_to(edit_user_settings_password_path)
    end
  end

  describe '/.well-known/security.txt', feature_category: :compliance_management do
    let(:action) { get('/.well-known/security.txt') }

    context 'for an authenticated user' do
      before do
        sign_in(create(:user))
      end

      it 'renders when a security txt is configured' do
        stub_application_setting security_txt_content: 'HELLO'
        action
        expect(response.body).to eq('HELLO')
      end

      it 'returns a 404 when a security txt is blank' do
        stub_application_setting security_txt_content: ''
        action
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns a 404 when a security txt is nil' do
        stub_application_setting security_txt_content: nil
        action
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'for an unauthenticated user' do
      it 'renders when a security txt is configured' do
        stub_application_setting security_txt_content: 'HELLO'
        action
        expect(response.body).to eq('HELLO')
      end

      it 'redirects to sign in' do
        stub_application_setting security_txt_content: ''
        action
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
