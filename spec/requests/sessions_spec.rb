# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sessions', feature_category: :system_access do
  include SessionHelpers

  let_it_be(:user) { create(:user) }

  it_behaves_like 'Base action controller' do
    subject(:request) { get new_user_session_path }
  end

  context 'for authentication', :allow_forgery_protection do
    it 'logout does not require a csrf token' do
      login_as(user)

      post(destroy_user_session_path, headers: { 'X-CSRF-Token' => 'invalid' })

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'when user has pending invitations' do
    it 'accepts the invitations and stores a user location' do
      create(:group_member, :invited, invite_email: user.email)
      member = create(:group_member, :invited, invite_email: user.email)

      post user_session_path(user: { login: user.username, password: user.password })

      expect(response).to redirect_to(group_path(member.source))
    end
  end

  context 'when using two-factor authentication via OTP' do
    let_it_be(:user) { create(:user, :two_factor, :invalid) }
    let(:user_params) { { login: user.username, password: user.password } }

    context 'with an invalid user' do
      it 'raises StandardError when ActiveRecord::RecordInvalid is raised to return 500 instead of 422' do
        otp = user.current_otp

        expect { authenticate_2fa(otp_attempt: otp) }.to raise_error(StandardError)
      end
    end

    context 'with an invalid record other than user' do
      it 'raises ActiveRecord::RecordInvalid for invalid record to return 422f' do
        otp = user.current_otp
        allow_next_instance_of(ActiveRecord::RecordInvalid) do |instance|
          allow(instance).to receive(:record).and_return(nil) # Simulate it's not a user
        end

        expect { authenticate_2fa(otp_attempt: otp) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    def authenticate_2fa(otp_attempt:)
      post(user_session_path(params: { user: user_params })) # First sign-in request for password, second for OTP
      post(user_session_path(params: { user: user_params.merge(otp_attempt: otp_attempt) }))
    end
  end

  describe 'GET /users/sign_in_path' do
    before do
      stub_feature_flags(two_step_sign_in: true)
    end

    shared_examples 'returns nil sign_in_path' do |login_value|
      it 'returns nil' do
        params = login_value.nil? ? {} : { login: login_value }
        get users_sign_in_path_path, params: params, as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'sign_in_path' => nil })
      end
    end

    context 'when requesting JSON format' do
      context 'when login parameter is not provided' do
        it_behaves_like 'returns nil sign_in_path', nil
      end

      context 'when login parameter is blank' do
        it_behaves_like 'returns nil sign_in_path', ''
      end

      context 'when user is found by username' do
        it_behaves_like 'returns nil sign_in_path', -> { user.username }
      end

      context 'when user is not found found' do
        it_behaves_like 'returns nil sign_in_path', -> { 'nonexistent' }
      end
    end

    context 'when requesting HTML format' do
      it 'returns 404' do
        get users_sign_in_path_path, as: :html

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
