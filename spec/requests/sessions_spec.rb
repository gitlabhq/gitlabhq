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

  context 'with IAM login challenge' do
    let(:valid_challenge) { 'a' * 64 }
    let(:iam_service_url) { 'https://iam.example.com' }
    let(:iam_redirect_url) { "#{iam_service_url}/oauth2/authorize?client_id=test-app&login_verifier=#{'b' * 64}" }

    before do
      stub_feature_flags(iam_svc_login: true)
      allow(Authn::IamAuthService).to receive(:enabled?).and_return(true)
    end

    context 'when storing the challenge' do
      it 'stores a valid challenge in session' do
        get new_user_session_path, params: { login_challenge: valid_challenge }

        expect(request.session[:login_challenge]).to eq(valid_challenge)
      end

      it 'does not store anything when challenge param is missing' do
        get new_user_session_path

        expect(request.session[:login_challenge]).to be_nil
      end

      it 'clears a previously stored challenge when revisiting without one' do
        get new_user_session_path, params: { login_challenge: valid_challenge }
        get new_user_session_path

        expect(request.session[:login_challenge]).to be_nil
      end

      context 'when iam_svc_login feature flag is disabled' do
        before do
          stub_feature_flags(iam_svc_login: false)
        end

        it 'does not store the challenge' do
          get new_user_session_path, params: { login_challenge: valid_challenge }

          expect(request.session[:login_challenge]).to be_nil
        end
      end

      context 'when IAM service is not enabled' do
        before do
          allow(Authn::IamAuthService).to receive(:enabled?).and_return(false)
        end

        it 'does not store the challenge' do
          get new_user_session_path, params: { login_challenge: valid_challenge }

          expect(request.session[:login_challenge]).to be_nil
        end
      end
    end

    shared_context 'with IAM accept challenge succeeding' do
      before do
        allow_next_instance_of(Authn::IamService::AcceptLoginChallengeService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.success(payload: { redirect_to: iam_redirect_url })
          )
        end
      end
    end

    shared_context 'with IAM accept challenge failing' do
      before do
        allow_next_instance_of(Authn::IamService::AcceptLoginChallengeService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(message: 'IAM login accept failed: HTTP 500', reason: :iam_request_failed)
          )
        end
      end
    end

    context 'when signing in with a login challenge' do
      def sign_in_within_iam_challenge_flow
        get new_user_session_path, params: { login_challenge: valid_challenge }
        post user_session_path, params: { user: { login: user.username, password: user.password } }
      end

      context 'when the IAM service accepts the challenge' do
        include_context 'with IAM accept challenge succeeding'

        it 'redirects to the IAM redirect URL and clears the challenge from session', :aggregate_failures do
          sign_in_within_iam_challenge_flow

          expect(response).to redirect_to(iam_redirect_url)
          expect(request.session[:login_challenge]).to be_nil
        end
      end

      context 'when the IAM service returns an error' do
        include_context 'with IAM accept challenge failing'

        it 'falls back to the default redirect path with a flash alert', :aggregate_failures do
          sign_in_within_iam_challenge_flow

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('An error occurred. Please try again.')
          expect(request.session[:login_challenge]).to be_nil
        end
      end

      context 'when IAM login is not enabled' do
        before do
          stub_feature_flags(iam_svc_login: false)
        end

        it 'redirects normally without calling the IAM service' do
          get new_user_session_path, params: { login_challenge: valid_challenge }
          post user_session_path, params: { user: { login: user.username, password: user.password } }

          expect(response).to redirect_to(root_path)
        end
      end

      context 'when authentication fails' do
        it 'preserves the challenge from session on failed login' do
          get new_user_session_path, params: { login_challenge: valid_challenge }

          post user_session_path, params: { user: { login: user.username, password: 'wrong_password' } }

          expect(request.session[:login_challenge]).to eq(valid_challenge)
        end

        context 'when authentication retry succeed' do
          include_context 'with IAM accept challenge succeeding'

          it 'redirects to the IAM redirect URL and clears the challenge from session' do
            get new_user_session_path, params: { login_challenge: valid_challenge }
            post user_session_path, params: { user: { login: user.username, password: 'wrong_password' } }
            post user_session_path, params: { user: { login: user.username, password: user.password } }

            expect(response).to redirect_to(iam_redirect_url)
            expect(request.session[:login_challenge]).to be_nil
          end
        end
      end
    end

    context 'when already authenticated' do
      before do
        login_as(user)
      end

      context 'when the IAM service accepts the challenge' do
        include_context 'with IAM accept challenge succeeding'

        it 'redirects to the IAM redirect URL and clears the login challenge from session' do
          get new_user_session_path, params: { login_challenge: valid_challenge }

          expect(response).to redirect_to(iam_redirect_url)
          expect(request.session[:login_challenge]).to be_nil
        end
      end

      context 'when the IAM service returns an error' do
        include_context 'with IAM accept challenge failing'

        it 'falls back to the default redirect with a flash alert', :aggregate_failures do
          get new_user_session_path, params: { login_challenge: valid_challenge }

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('An error occurred. Please try again.')
        end
      end
    end

    context 'when signing in without a login challenge' do
      it 'redirects to the default path' do
        post user_session_path, params: { user: { login: user.username, password: user.password } }

        expect(response).to redirect_to(root_path)
      end
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
