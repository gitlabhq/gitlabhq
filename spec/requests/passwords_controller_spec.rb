# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PasswordsController, type: :request, feature_category: :system_access do
  describe '#update' do
    let(:user) { create(:user, password_automatically_set: true, password_expires_at: 10.minutes.ago) }
    let(:expected_context) do
      { 'meta.caller_id' => 'PasswordsController#update',
        'meta.user' => user.username }
    end

    subject(:perform_request) do
      password = User.random_password
      put user_password_path, params: {
        user: {
          password: password,
          password_confirmation: password,
          reset_password_token: user.send_reset_password_instructions
        }
      }
    end

    include_examples 'set_current_context'
  end
end
