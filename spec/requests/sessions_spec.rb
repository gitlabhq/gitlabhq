# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sessions' do
  context 'authentication', :allow_forgery_protection do
    let(:user) { create(:user) }

    it 'logout does not require a csrf token' do
      login_as(user)

      post(destroy_user_session_path, headers: { 'X-CSRF-Token' => 'invalid' })

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
