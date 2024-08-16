# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsController, type: :request, feature_category: :system_access do
  describe '#destroy' do
    let_it_be(:user) { create(:user) }
    let(:expected_context) do
      { 'meta.caller_id' => 'SessionsController#destroy',
        'meta.user' => user.username }
    end

    subject(:perform_request) do
      sign_in(user)
      post destroy_user_session_path
    end

    include_examples 'set_current_context'
  end

  describe '#new' do
    let(:expected_context) do
      { 'meta.caller_id' => 'SessionsController#new' }
    end

    subject(:perform_request) do
      get new_user_session_path
    end

    include_examples 'set_current_context'
  end

  describe '#create' do
    let_it_be(:user) { create(:user) }
    let(:expected_context) do
      { 'meta.caller_id' => 'SessionsController#create',
        'meta.user' => user.username }
    end

    subject(:perform_request) do
      user.update!(failed_attempts: User.maximum_attempts.pred)
      post user_session_path, params: { user: { login: user.username, password: user.password.succ } }
    end

    include_examples 'set_current_context'
  end
end
