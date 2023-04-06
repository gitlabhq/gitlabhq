# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sessions', feature_category: :system_access do
  include SessionHelpers

  context 'authentication', :allow_forgery_protection do
    let(:user) { create(:user) }

    it 'logout does not require a csrf token' do
      login_as(user)

      post(destroy_user_session_path, headers: { 'X-CSRF-Token' => 'invalid' })

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'about_gitlab_active_user' do
    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
    end

    let(:user) { create(:user) }

    context 'when user signs in' do
      it 'sets marketing cookie' do
        post user_session_path(user: { login: user.username, password: user.password })
        expect(response.cookies['about_gitlab_active_user']).to be_present
      end
    end

    context 'when user uses remember_me' do
      it 'sets marketing cookie' do
        post user_session_path(user: { login: user.username, password: user.password, remember_me: true })
        expect(response.cookies['about_gitlab_active_user']).to be_present
      end
    end

    context 'when user signs out' do
      before do
        post user_session_path(user: { login: user.username, password: user.password })
      end

      it 'deletes marketing cookie' do
        post(destroy_user_session_path)
        expect(response.cookies['about_gitlab_active_user']).to be_nil
      end
    end

    context 'when user is not using GitLab SaaS' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
      end

      it 'does not set marketing cookie' do
        post user_session_path(user: { login: user.username, password: user.password })
        expect(response.cookies['about_gitlab_active_user']).to be_nil
      end
    end
  end
end
