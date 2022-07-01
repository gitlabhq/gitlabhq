# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'VerifiesWithEmail', :clean_gitlab_redis_sessions, :clean_gitlab_redis_rate_limiting do
  include SessionHelpers
  include EmailHelpers

  let(:user) { create(:user) }

  shared_examples_for 'send verification instructions' do
    it 'locks the user' do
      user.reload
      expect(user.unlock_token).not_to be_nil
      expect(user.locked_at).not_to be_nil
    end

    it 'sends an email' do
      mail = find_email_for(user)
      expect(mail.to).to match_array([user.email])
      expect(mail.subject).to eq('Verify your identity')
    end
  end

  shared_examples_for 'prompt for email verification' do
    it 'sets the verification_user_id session variable and renders the email verification template' do
      expect(request.session[:verification_user_id]).to eq(user.id)
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('devise/sessions/email_verification')
    end
  end

  describe 'verify_with_email' do
    context 'when user is locked and a verification_user_id session variable exists' do
      before do
        encrypted_token = Devise.token_generator.digest(User, :unlock_token, 'token')
        user.update!(locked_at: Time.current, unlock_token: encrypted_token)
        stub_session(verification_user_id: user.id)
      end

      context 'when rate limited and a verification_token param exists' do
        before do
          allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

          post(user_session_path(user: { verification_token: 'token' }))
        end

        it_behaves_like 'prompt for email verification'

        it 'adds a verification error message' do
          expect(response.body)
            .to include("You&#39;ve reached the maximum amount of tries. "\
                        'Wait 10 minutes or resend a new code and try again.')
        end
      end

      context 'when an invalid verification_token param exists' do
        before do
          post(user_session_path(user: { verification_token: 'invalid_token' }))
        end

        it_behaves_like 'prompt for email verification'

        it 'adds a verification error message' do
          expect(response.body).to include(('The code is incorrect. Enter it again, or resend a new code.'))
        end
      end

      context 'when an expired verification_token param exists' do
        before do
          user.update!(locked_at: 1.hour.ago)
          post(user_session_path(user: { verification_token: 'token' }))
        end

        it_behaves_like 'prompt for email verification'

        it 'adds a verification error message' do
          expect(response.body).to include(('The code has expired. Resend a new code and try again.'))
        end
      end

      context 'when a valid verification_token param exists' do
        before do
          post(user_session_path(user: { verification_token: 'token' }))
        end

        it 'unlocks the user' do
          user.reload
          expect(user.unlock_token).to be_nil
          expect(user.locked_at).to be_nil
        end

        it 'redirects to the successful verification path' do
          expect(response).to redirect_to(users_successful_verification_path)
        end
      end
    end

    context 'when signing in with a valid password' do
      let(:sign_in) { post(user_session_path(user: { login: user.username, password: user.password })) }

      context 'when the feature flag is toggled on' do
        before do
          stub_feature_flags(require_email_verification: true)
        end

        context 'when rate limited' do
          before do
            allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
            sign_in
          end

          it 'redirects to the login form and shows an alert message' do
            expect(response).to redirect_to(new_user_session_path)
            expect(flash[:alert]).to eq('Maximum login attempts exceeded. Wait 10 minutes and try again.')
          end
        end

        context 'when the user already has an unlock_token set' do
          before do
            user.update!(unlock_token: 'token')
            sign_in
          end

          it_behaves_like 'prompt for email verification'
        end

        context 'when the user is already locked' do
          before do
            user.update!(locked_at: Time.current)
            perform_enqueued_jobs { sign_in }
          end

          it_behaves_like 'send verification instructions'
          it_behaves_like 'prompt for email verification'
        end

        context 'when the user is signing in from an unknown ip address' do
          before do
            allow(AuthenticationEvent)
              .to receive(:initial_login_or_known_ip_address?)
              .and_return(false)

            perform_enqueued_jobs { sign_in }
          end

          it_behaves_like 'send verification instructions'
          it_behaves_like 'prompt for email verification'
        end
      end

      context 'when the feature flag is toggled off' do
        before do
          stub_feature_flags(require_email_verification: false)
          sign_in
        end

        it 'redirects to the root path' do
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe 'resend_verification_code' do
    context 'when no verification_user_id session variable exists' do
      before do
        post(users_resend_verification_code_path)
      end

      it 'returns 204 No Content' do
        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when a verification_user_id session variable exists' do
      before do
        stub_session(verification_user_id: user.id)

        perform_enqueued_jobs do
          post(users_resend_verification_code_path)
        end
      end

      it_behaves_like 'send verification instructions'
      it_behaves_like 'prompt for email verification'
    end

    context 'when exceeding the rate limit' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

        stub_session(verification_user_id: user.id)

        perform_enqueued_jobs do
          post(users_resend_verification_code_path)
        end
      end

      it 'does not lock the user' do
        user.reload
        expect(user.unlock_token).to be_nil
        expect(user.locked_at).to be_nil
      end

      it 'does not send an email' do
        mail = find_email_for(user)
        expect(mail).to be_nil
      end

      it_behaves_like 'prompt for email verification'
    end
  end

  describe 'successful_verification' do
    before do
      sign_in(user)
    end

    it 'renders the template and removes the verification_user_id session variable' do
      stub_session(verification_user_id: user.id)

      get(users_successful_verification_path)

      expect(request.session.has_key?(:verification_user_id)).to eq(false)
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('successful_verification', layout: 'minimal')
      expect(response.body).to include(root_path)
    end
  end
end
