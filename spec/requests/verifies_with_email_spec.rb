# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'VerifiesWithEmail', :clean_gitlab_redis_sessions, :clean_gitlab_redis_rate_limiting,
  feature_category: :instance_resiliency do
  include SessionHelpers
  include EmailHelpers

  let(:user) { create(:user) }

  shared_examples_for 'does not send verification instructions' do
    let(:recipient_email) { nil }

    specify do
      mail = find_email_for(recipient_email || user)
      expect(mail&.subject).not_to eq(s_('IdentityVerification|Verify your identity'))
    end
  end

  shared_examples_for 'locks the user and sends verification instructions' do
    let(:recipient_email) { nil }

    it 'locks the user' do
      user.reload
      expect(user.unlock_token).not_to be_nil
      expect(user.locked_at).not_to be_nil
    end

    it 'sends an email', :aggregate_failures do
      mail = find_email_for(recipient_email || user)
      expect(mail.to).to match_array([recipient_email || user.email])
      expect(mail.subject).to eq(s_('IdentityVerification|Verify your identity'))
    end
  end

  shared_examples_for 'send verification instructions' do
    it_behaves_like 'locks the user and sends verification instructions'

    context 'when an unconfirmed verification email exists' do
      let(:new_email) { 'new@email' }
      let(:user) { create(:user, unconfirmed_email: new_email, confirmation_sent_at: 1.minute.ago) }

      it 'sends a verification instructions email to the unconfirmed email address' do
        mail = ActionMailer::Base.deliveries.find { |d| d.to.include?(new_email) }
        expect(mail.subject).to eq(s_('IdentityVerification|Verify your identity'))
      end
    end
  end

  shared_examples_for 'prompt for email verification' do
    it 'sets the verification_user_id session variable and renders the email verification template',
      :aggregate_failures do
      expect(request.session[:verification_user_id]).to eq(user.id)
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('devise/sessions/email_verification')
    end
  end

  shared_examples_for 'rate limited' do
    it 'redirects to the login form and shows an alert message' do
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert])
        .to eq(s_('IdentityVerification|Maximum login attempts exceeded. Wait 10 minutes and try again.'))
    end
  end

  shared_examples_for 'two factor prompt or successful login' do
    it 'shows the 2FA prompt when enabled or redirects to the root path' do
      if user.two_factor_enabled?
        expect(response.body).to include('Enter verification code')
      else
        expect(response).to redirect_to(root_path)
      end
    end
  end

  shared_examples_for 'verifying with email' do
    context 'when rate limited' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
        sign_in
      end

      it_behaves_like 'rate limited'
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

  shared_examples_for 'not verifying with email' do
    context 'when rate limited' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
        sign_in
      end

      it_behaves_like 'two factor prompt or successful login'
    end

    context 'when the user already has an unlock_token set' do
      before do
        user.update!(unlock_token: 'token')
        sign_in
      end

      it_behaves_like 'two factor prompt or successful login'
    end

    context 'when the user is signing in from an unknown ip address' do
      before do
        allow(AuthenticationEvent)
          .to receive(:initial_login_or_known_ip_address?)
          .and_return(false)
        sign_in
      end

      it_behaves_like 'two factor prompt or successful login'
    end
  end

  describe 'verify_with_email' do
    context 'when user is locked and a verification_user_id session variable exists' do
      before do
        encrypted_token = Devise.token_generator.digest(User, user.email, 'token')
        user.update!(locked_at: Time.current, unlock_token: encrypted_token)
        stub_session(session_data: { verification_user_id: user.id })
      end

      context 'when rate limited and a verification_token param exists' do
        before do
          allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

          post(user_session_path(user: { verification_token: 'token' }))
        end

        it 'adds a verification error message' do
          expect(json_response)
            .to include('message' => "You've reached the maximum amount of tries. "\
                                     'Wait 10 minutes or send a new code and try again.')
        end
      end

      context 'when an invalid verification_token param exists' do
        before do
          post(user_session_path(user: { verification_token: 'invalid_token' }))
        end

        it 'adds a verification error message' do
          expect(json_response)
            .to include('message' => s_('IdentityVerification|The code is incorrect. '\
                                        'Enter it again, or send a new code.'))
        end
      end

      context 'when an expired verification_token param exists' do
        before do
          user.update!(locked_at: 1.hour.ago)
          post(user_session_path(user: { verification_token: 'token' }))
        end

        it 'adds a verification error message' do
          expect(json_response)
            .to include('message' => s_('IdentityVerification|The code has expired. Send a new code and try again.'))
        end
      end

      context 'when a valid verification_token param exists' do
        subject(:submit_token) { post(user_session_path(user: { verification_token: 'token' })) }

        it 'unlocks the user, create logs and records the activity', :freeze_time do
          expect { submit_token }.to change { user.reload.unlock_token }.to(nil)
            .and change { user.locked_at }.to(nil)
            .and change { AuditEvent.count }.by(1)
            .and change { AuthenticationEvent.count }.by(1)
            .and change { user.last_activity_on }.to(Date.today)
            .and change { user.email_reset_offered_at }.to(Time.current)
        end

        it 'returns the success status and a redirect path' do
          submit_token
          expect(json_response).to eq('status' => 'success', 'redirect_path' => users_successful_verification_path)
        end

        context 'when an unconfirmed verification email exists' do
          before do
            user.update!(email: new_email)
          end

          let(:new_email) { 'new@email' }

          it 'confirms the email' do
            expect { submit_token }
              .to change { user.reload.email }.to(new_email)
              .and change { user.confirmed_at }
              .and change { user.unconfirmed_email }.from(new_email).to(nil)
          end
        end

        context 'when email reset has already been offered' do
          before do
            user.update!(email_reset_offered_at: 1.hour.ago, email: 'new@email')
          end

          it 'does not change the email_reset_offered_at field' do
            expect { submit_token }.not_to change { user.reload.email_reset_offered_at }
          end

          it 'does not confirm the email' do
            expect { submit_token }.not_to change { user.reload.email }
          end
        end
      end

      context 'when not completing identity verification and logging in with another account' do
        let(:another_user) { create(:user) }

        before do
          post user_session_path, params: { user: { login: another_user.username, password: another_user.password } }
        end

        it 'redirects to the root path' do
          expect(response).to redirect_to(root_path)
        end
      end
    end

    context 'when signing in with a valid password' do
      let(:headers) { {} }
      let(:sign_in) do
        post user_session_path, params: { user: { login: user.username, password: user.password } }, headers: headers
      end

      it_behaves_like 'not verifying with email'

      context 'when the feature flag is toggled on' do
        before do
          stub_feature_flags(require_email_verification: user)
          stub_feature_flags(skip_require_email_verification: false)
        end

        it_behaves_like 'verifying with email'

        context 'when 2FA is enabled' do
          before do
            user.update!(otp_required_for_login: true)
          end

          it_behaves_like 'not verifying with email'
        end

        context 'when request is from a QA user' do
          before do
            allow(Gitlab::Qa).to receive(:request?).and_return(true)
          end

          it_behaves_like 'not verifying with email'
        end

        context 'when the skip_require_email_verification feature flag is turned on' do
          before do
            stub_feature_flags(skip_require_email_verification: user)
          end

          it_behaves_like 'not verifying with email'
        end

        context 'when the user is not active' do
          context 'when the user is signing in from an unknown IP address' do
            before do
              user.block!
              allow(AuthenticationEvent).to receive(:initial_login_or_known_ip_address?).and_return(false)
              sign_in
            end

            it 'does not prompt for email verification', :aggregate_failures do
              expect(response).to redirect_to(new_user_session_path)
              expect(flash[:alert]).to include('Your account has been blocked')
            end
          end
        end
      end
    end
  end

  describe 'resend_verification_code' do
    let(:params) { { user: { email: '' } } }

    context 'when no verification_user_id session variable exists' do
      before do
        post(users_resend_verification_code_path, params: params)
      end

      it 'returns 204 No Content' do
        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when a verification_user_id session variable exists' do
      before do
        stub_session(session_data: { verification_user_id: user.id })

        perform_enqueued_jobs do
          post(users_resend_verification_code_path, params: params)
        end
      end

      it_behaves_like 'send verification instructions'

      context 'when user => email param is present' do
        context 'when email param matches the user\'s verified primary email' do
          let(:params) { { user: { email: user.email } } }

          it_behaves_like 'locks the user and sends verification instructions'
        end

        context 'when email param matches one of the user\'s verified secondary emails' do
          let(:secondary_email) { create(:email, :confirmed, user: user) }
          let(:params) { { user: { email: secondary_email.email } } }

          it_behaves_like 'locks the user and sends verification instructions' do
            let(:recipient_email) { secondary_email.email }
          end
        end

        context 'when email param matches one of the user\'s unverified secondary emails' do
          let(:secondary_email) { create(:email, user: user) }
          let(:params) { { user: { email: secondary_email.email } } }

          it_behaves_like 'does not send verification instructions' do
            let(:recipient_email) { secondary_email.email }
          end
        end

        context 'when email param does not match any of the user\'s verified emails' do
          let(:bad_actor) { create(:user) }
          let(:params) { { user: { email: bad_actor.email } } }

          it_behaves_like 'does not send verification instructions' do
            let(:recipient_email) { bad_actor.email }
          end
        end
      end
    end

    context 'when exceeding the rate limit' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

        stub_session(session_data: { verification_user_id: user.id })

        perform_enqueued_jobs do
          post(users_resend_verification_code_path, params: params)
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
    end
  end

  describe 'update_email' do
    let(:new_email) { 'new@email' }

    subject(:do_request) { patch(users_update_email_path(user: { email: new_email })) }

    context 'when no verification_user_id session variable exists' do
      it 'returns 204 No Content' do
        do_request

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when a verification_user_id session variable exists' do
      before do
        stub_session(session_data: { verification_user_id: user.id })
      end

      it 'locks the user' do
        do_request

        expect(user.reload.unlock_token).not_to be_nil
        expect(user.locked_at).not_to be_nil
      end

      it 'sends a changed notification to the primary email and verification instructions to the unconfirmed email' do
        perform_enqueued_jobs { do_request }

        sent_mails = ActionMailer::Base.deliveries.map { |mail| { mail.to[0] => mail.subject } }

        expect(sent_mails).to match_array([
          { user.reload.unconfirmed_email => s_('IdentityVerification|Verify your identity') },
          { user.email => 'Email Changed' }
        ])
      end

      it 'calls the UpdateEmailService and returns a success response' do
        expect_next_instance_of(Users::EmailVerification::UpdateEmailService, user: user) do |instance|
          expect(instance).to receive(:execute).with(email: new_email).and_call_original
        end

        do_request

        expect(json_response).to eq('status' => 'success')
      end
    end

    context 'when failing to update the email address' do
      let(:service_response) do
        {
          status: 'failure',
          reason: 'the reason',
          message: 'the message'
        }
      end

      before do
        stub_session(session_data: { verification_user_id: user.id })
      end

      it 'calls the UpdateEmailService and returns an error response' do
        expect_next_instance_of(Users::EmailVerification::UpdateEmailService, user: user) do |instance|
          expect(instance).to receive(:execute).with(email: new_email).and_return(service_response)
        end

        do_request

        expect(json_response).to eq(service_response.with_indifferent_access)
      end
    end
  end

  describe 'successful_verification' do
    before do
      allow(user).to receive(:role_required?).and_return(true) # It skips the required signup info before_action
      sign_in(user)
    end

    it 'renders the template and removes the verification_user_id session variable' do
      stub_session(session_data: { verification_user_id: user.id })

      get(users_successful_verification_path)

      expect(request.session.has_key?(:verification_user_id)).to eq(false)
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('successful_verification', layout: 'minimal')
      expect(response.body).to include(root_path)
    end
  end
end
