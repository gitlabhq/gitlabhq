# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VerifiesWithEmail, :clean_gitlab_redis_sessions, :clean_gitlab_redis_rate_limiting,
  :with_current_organization, feature_category: :instance_resiliency do
  include SessionHelpers
  include EmailHelpers

  let(:user) { create(:user) }

  before do
    allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
    allow(Gitlab::AppLogger).to receive(:info).and_call_original
  end

  shared_examples_for 'does not send verification instructions' do
    let(:recipient_email) { nil }

    specify do
      mail = find_email_for(recipient_email || user)
      expect(mail&.subject).not_to eq(s_('IdentityVerification|Verify your identity'))
    end
  end

  shared_examples 'sends verification instructions' do
    it 'sends an email', :aggregate_failures do
      mail = find_email_for(recipient_email || user)
      expect(mail.to).to match_array([recipient_email || user.email])
      expect(mail.subject).to eq(s_('IdentityVerification|Verify your identity'))
    end

    it 'logs that it was sent' do
      expect(Gitlab::AppLogger).to have_received(:info).with(
        hash_including(
          message: 'Email Verification',
          event: 'Instructions Sent',
          username: user.username,
          reason: log_reason
        )
      )
    end

    context 'when an unconfirmed verification email exists' do
      before do
        user.update!(unconfirmed_email: 'new@email', confirmation_sent_at: 1.minute.ago)
      end

      it 'sends a verification instructions email to the existing email address' do
        mail = find_email_for(recipient_email || user)
        expect(mail.subject).to eq(s_('IdentityVerification|Verify your identity'))
      end

      it 'does not send mail to unconfirmed address' do
        mail = find_email_for(user.unconfirmed_email)
        expect(mail).to be_nil
      end
    end
  end

  shared_examples_for 'sends verification instructions for email OTP' do
    let(:recipient_email) { nil }

    it 'sets OTP attributes' do
      user.reload
      expect(user.email_otp).not_to be_nil
      expect(user.email_otp_last_sent_at).not_to be_nil
      expect(user.email_otp_last_sent_to).to eq(recipient_email || user.email)
    end

    it 'does not lock the user' do
      user.reload
      expect(user.unlock_token).to be_nil
      expect(user.locked_at).to be_nil
    end

    it_behaves_like 'sends verification instructions'
  end

  shared_examples_for 'locks the user and sends verification instructions' do
    let(:recipient_email) { nil }

    it 'locks the user' do
      user.reload
      expect(user.unlock_token).not_to be_nil
      expect(user.locked_at).not_to be_nil
    end

    it_behaves_like 'sends verification instructions'
  end

  shared_examples_for 'prompt for email verification' do
    it 'sets the verification_user_id session variable and renders the email verification template',
      :aggregate_failures do
      expect(request.session[:verification_user_id]).to eq(user.id)
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('devise/sessions/email_verification')
    end
  end

  shared_examples_for 'rate limited by login attempts' do
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
    context 'when rate limited by login attempts' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:user_sign_in,
          hash_including(scope: user)).and_return(true)
        sign_in
      end

      it_behaves_like 'rate limited by login attempts'
    end

    context 'when the user already has an unlock_token set' do
      before do
        user.update!(unlock_token: 'token', locked_at: Time.current)
        sign_in
      end

      it_behaves_like 'prompt for email verification'
    end

    context 'when the user is already locked with no token' do
      before do
        user.update!(locked_at: Time.current)
        perform_enqueued_jobs { sign_in }
      end

      let(:log_reason) { 'new unlock token needed' }

      it_behaves_like 'locks the user and sends verification instructions'
      it_behaves_like 'prompt for email verification'
    end

    context 'when the user is signing in from an unknown ip address' do
      before do
        allow(AuthenticationEvent)
          .to receive(:initial_login_or_known_ip_address?)
          .and_return(false)

        perform_enqueued_jobs { sign_in }
      end

      let(:log_reason) { 'sign in from untrusted IP address' }

      it_behaves_like 'locks the user and sends verification instructions'
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
    context 'when user is locked and being asked to enter a code' do
      before do
        encrypted_token = Devise.token_generator.digest(User, user.email, 'token')
        user.update!(locked_at: Time.current, unlock_token: encrypted_token)
        stub_session(session_data: { verification_user_id: user.id })
      end

      context 'when rate limited by code entry and a verification_token param exists' do
        before do
          allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:email_verification,
            hash_including(scope: user.unlock_token)).and_return(true)

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
        end

        it 'returns the success status and a redirect path' do
          submit_token
          expect(json_response).to eq('status' => 'success', 'redirect_path' => users_successful_verification_path)
        end

        context 'when email reset functionality is disabled' do
          shared_examples 'does not perform email reset actions' do
            before do
              user.update!(email: 'new@email')
            end

            it 'does not confirm the email' do
              expect { submit_token }
                .to not_change { user.reload.email }
            end
          end
        end
      end

      context 'when not completing identity verification and logging in with another account' do
        let(:another_user) { create(:user) }
        let(:current_organization) { another_user.organization }

        before do
          post user_session_path, params: { user: { login: another_user.username, password: another_user.password } }
        end

        it 'redirects to the root path', :with_organization_url_helpers do
          expect(response).to redirect_to(root_path)
        end
      end
    end

    context 'when user is being asked to enter an email-based OTP', :with_organization_url_helpers do
      let(:current_organization) { user.organization }

      before do
        encrypted_token = Devise.token_generator.digest(User, user.email, 'token')
        user.update!(email_otp_last_sent_at: Time.current, email_otp: encrypted_token)
        stub_session(session_data: { verification_user_id: user.id })
      end

      context 'when a valid verification_token param exists' do
        subject(:submit_token) { post(user_session_path(user: { verification_token: 'token' })) }

        it 'clears the otp, create logs and records the activity', :freeze_time do
          expect { submit_token }.to change { user.reload.email_otp }.to(nil)
            .and not_change { user.email_otp_last_sent_at }
            .and change { AuditEvent.count }.by(1)
            .and change { AuthenticationEvent.count }.by(1)
            .and change { user.last_activity_on }.to(Date.today)
        end

        it 'returns the success status and a redirect path' do
          submit_token
          expect(json_response).to eq('status' => 'success', 'redirect_path' => users_successful_verification_path)
        end

        # Email-based OTP codes are valid for one hour. It is possible
        # they could get locked, in which case the user needs to enter
        # an unlock_token not an email_otp
        context 'when they were locked between sending and code entry' do
          before do
            user.lock_access!
          end

          it 'maintains the lock' do
            submit_token
            user.reload
            expect(user.access_locked?).to be true
          end

          it 'does not clear the OTP attributes', :freeze_time do
            expect { submit_token }.to not_change { user.reload.email_otp }
              .and not_change { user.email_otp_last_sent_at }
          end

          it 'adds a verification error message' do
            submit_token

            expect(json_response)
              .to include('message' => s_('IdentityVerification|The code is incorrect. '\
                                          'Enter it again, or send a new code.'))
          end
        end
      end

      context 'when rate limited by code entry and a verification_token param exists' do
        before do
          allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:email_verification,
            hash_including(scope: user.email_otp)).and_return(true)

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
          user.update!(email_otp_last_sent_at: 1.hour.ago)
          post(user_session_path(user: { verification_token: 'token' }))
        end

        it 'adds a verification error message' do
          expect(json_response)
            .to include('message' => s_('IdentityVerification|The code has expired. Send a new code and try again.'))
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

    # This happens before the two contexts above - this is the initial
    # sign in flow.
    context 'when signing in with a valid password', :with_organization_url_helpers do
      let(:current_organization) { user.organization }
      let(:headers) { {} }
      let(:sign_in) do
        post user_session_path, params: { user: { login: user.username, password: user.password } }, headers: headers
      end

      it_behaves_like 'not verifying with email'

      context 'when the feature flag is toggled on' do
        before do
          stub_application_setting(require_email_verification_on_account_locked: true)
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

        context 'when email_based_mfa feature flag is disabled' do
          before do
            stub_feature_flags(email_based_mfa: false)
            perform_enqueued_jobs { sign_in }
          end

          it_behaves_like 'two factor prompt or successful login'
        end

        context 'when email_otp_required_after is in the future' do
          let(:user) { create(:user, email_otp_required_after: 1.day.from_now) }

          before do
            perform_enqueued_jobs { sign_in }
          end

          it_behaves_like 'two factor prompt or successful login'
        end

        context 'when email_otp_required_after is in the past and they have completed their first sign in' do
          let(:last_sign_in) { 1.day.ago }
          let(:user) do
            create(:user,
              last_sign_in_at: last_sign_in,
              email_otp_required_after: 1.day.ago
            )
          end

          context 'when an old IP address is seen' do
            before do
              perform_enqueued_jobs { sign_in }
            end

            let(:log_reason) { 'email_otp' }

            it_behaves_like 'sends verification instructions for email OTP'
            it_behaves_like 'prompt for email verification'
          end

          # During the signup flow, Devise:Confirmable will send users
          # a link to click. They then need to sign in again. We don't
          # want them to have to go to their emails a second time.
          context 'when it is their first sign in' do
            let(:last_sign_in) { nil }

            before do
              perform_enqueued_jobs { sign_in }
            end

            it_behaves_like 'two factor prompt or successful login'
          end

          context 'when a new IP address is seen' do
            before do
              allow(AuthenticationEvent)
                .to receive(:initial_login_or_known_ip_address?)
                .and_return(false)
              perform_enqueued_jobs { sign_in }
            end

            let(:log_reason) { 'sign in from untrusted IP address' }

            it_behaves_like 'locks the user and sends verification instructions'
            it_behaves_like 'prompt for email verification'
          end

          it 'calls Authn::EmailOtpEnrollment updater' do
            expect_next_found_instance_of(User) do |instance|
              expect(instance).to receive(:set_email_otp_required_after_based_on_restrictions)
                .with(save: true)
                .at_least(:once)
            end
            sign_in
          end

          # Test an example behaviour of EmailOtpEnrollment for testing
          # in depth - full behavior is tested in
          # email_otp_enrollment_spec.rb
          context 'when email_otp_required_after is unset despite instance requirement', :freeze_time do
            let(:user) do
              create(:user,
                last_sign_in_at: last_sign_in,
                email_otp_required_after: nil
              )
            end

            let(:log_reason) { 'email_otp' }

            before do
              stub_application_setting(require_minimum_email_based_otp_for_users_with_passwords: true)
              perform_enqueued_jobs { sign_in }
            end

            it 'corrects the state during sign-in' do
              expect(user.reload.email_otp_required_after).to eq(Time.current)
            end

            it_behaves_like 'sends verification instructions for email OTP'
            it_behaves_like 'prompt for email verification'
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
        # Simulate the user having been presented the code entry
        # screen
        stub_session(session_data: { verification_user_id: user.id })
      end

      context 'when the user is locked' do
        before do
          user.lock_access!

          perform_enqueued_jobs do
            post(users_resend_verification_code_path, params: params)
          end
        end

        let(:log_reason) { 'resend lock verification code' }

        it_behaves_like 'locks the user and sends verification instructions'

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

      context 'when the user is not locked (email-based OTP)' do
        let(:original_token) { Devise.token_generator.digest(User, user.email, 'token') }
        let(:log_reason) { 'resend email_otp code' }
        let(:request_resend) do
          post(users_resend_verification_code_path, params: params)
        end

        before do
          user.update!(email_otp: original_token, email_otp_last_sent_at: 1.minute.ago)
        end

        context 'when the feature flag is enabled' do
          before do
            perform_enqueued_jobs do
              request_resend
            end
          end

          it_behaves_like 'sends verification instructions for email OTP'

          it 'generates a new email_otp' do
            user.reload
            expect(user.email_otp).not_to eq(original_token)
          end

          it 'does not lock the user' do
            user.reload
            expect(user.unlock_token).to be_nil
            expect(user.locked_at).to be_nil
          end

          context 'when user => email param is present' do
            context 'when email param matches the user\'s verified primary email' do
              let(:params) { { user: { email: user.email } } }

              it_behaves_like 'sends verification instructions for email OTP'
            end

            context 'when email param matches one of the user\'s verified secondary emails' do
              let(:secondary_email) { create(:email, :confirmed, user: user) }
              let(:params) { { user: { email: secondary_email.email } } }

              it_behaves_like 'sends verification instructions for email OTP' do
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

        context 'when the feature flag is disabled' do
          before do
            stub_feature_flags(email_based_mfa: false)
          end

          it 'does not change the user email otp or lock attributes', :freeze_time do
            expect { request_resend }.to not_change { user.reload.email_otp }
              .and not_change { user.email_otp_last_sent_at }
              .and not_change { user.unlock_token }
              .and not_change { user.locked_at }
          end

          it 'adds a verification error message' do
            request_resend
            expect(json_response).to have_key('message')
            expect(json_response['message']).to start_with("Email Verification has been disabled")
          end
        end
      end
    end

    context 'when the user requests the verification code email to be sent to their secondary address' do
      let(:secondary_email) { create(:email, :confirmed, user: user) }
      let(:params) { { user: { email: secondary_email.email } } }

      before do
        stub_session(session_data: { verification_user_id: user.id })
        perform_enqueued_jobs do
          post(users_resend_verification_code_path, params: params)
        end
      end

      it 'sends a notification email to the user\'s primary address' do
        mail = find_email_for(user.email)
        expect(mail.subject).to eq(s_('IdentityVerification|Verification code sent to your secondary email address'))
      end
    end

    context 'when the user requests the verification code to their primary address using the secondary address flow' do
      # when the user enters an email address using the flow dedicated to sending to an alternative address, there's no
      # check that the address entered is not their main address. We want to make sure that if they enter the main one,
      # we don't send both the code and the notification on that same primary email.
      let(:params) { { user: { email: user.email } } }

      before do
        stub_session(session_data: { verification_user_id: user.id })
        perform_enqueued_jobs do
          post(users_resend_verification_code_path, params: params)
        end
      end

      it 'sends the verification code to the primary address but does not send a notification email' do
        verification_mail = ActionMailer::Base.deliveries.find do |email|
          email.to.include?(user.email) &&
            email.subject == s_('IdentityVerification|Verify your identity')
        end

        notification_mail = ActionMailer::Base.deliveries.find do |email|
          email.to.include?(user.email) &&
            email.subject == s_('IdentityVerification|Verification code sent to your secondary email address')
        end

        expect(verification_mail).to be_present
        expect(notification_mail).to be_nil
      end
    end

    context 'when the user does not request the code to be sent to their secondary address' do
      let(:params) { { user: { email: '' } } }

      before do
        stub_session(session_data: { verification_user_id: user.id })
        perform_enqueued_jobs do
          post(users_resend_verification_code_path, params: params)
        end
      end

      it 'doesn\'t send a notification email to the user\'s primary email' do
        notification_mail = ActionMailer::Base.deliveries.find do |email|
          email.to.include?(user.email) &&
            email.subject == s_('IdentityVerification|Verification code sent to your secondary email address')
        end

        expect(notification_mail).to be_nil
      end
    end

    context 'when exceeding the code send rate limit' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:email_verification_code_send,
          hash_including(scope: user)).and_return(true)

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

    context 'when user validation fails during save' do
      let(:validation_error) { ActiveRecord::RecordInvalid.new(user) }

      before do
        user.update!(email_otp_required_after: 1.day.ago)
        stub_session(session_data: { verification_user_id: user.id })

        # Mock the user to fail validation on save!
        allow(User).to receive(:find_by_id).with(user.id).and_return(user)
        allow(user).to receive(:save!).and_raise(validation_error)
        allow(user).to receive(:save).with(validate: false).and_call_original

        perform_enqueued_jobs do
          post(users_resend_verification_code_path, params: { user: { email: '' } })
        end
      end

      it 'logs the validation error' do
        expect(Gitlab::AppLogger).to have_received(:info).with(
          hash_including(
            message: 'Email Verification',
            event: 'Error',
            username: user.username,
            reason: validation_error.to_s
          )
        )
      end

      it 'saves the user without validation' do
        expect(user).to have_received(:save).with(validate: false)
      end

      it 'still sends the verification email' do
        mail = find_email_for(user)
        expect(mail.subject).to eq(s_('IdentityVerification|Verify your identity'))
      end

      it 'still sets the email OTP attributes' do
        user.reload
        expect(user.email_otp).not_to be_nil
        expect(user.email_otp_last_sent_at).not_to be_nil
        expect(user.email_otp_last_sent_to).to eq(user.email)
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

  describe 'skip_verification_for_now' do
    let(:permitted_to_skip_email_otp_in_grace_period) { true }

    before do
      stub_session(session_data: { verification_user_id: user.id })
      allow_next_instance_of(SessionsController) do |controller|
        allow(controller).to receive(
          :permitted_to_skip_email_otp_in_grace_period?
        ).with(user).and_return(permitted_to_skip_email_otp_in_grace_period)
      end
    end

    context 'when user is permitted to skip email OTP in grace period' do
      it 'returns success status and redirects to skip verification confirmation path' do
        post(users_skip_verification_for_now_path(user: { login: user.username }))

        expect(json_response).to match(
          'status' => 'success',
          'redirect_path' => users_skip_verification_confirmation_path
        )
      end

      context 'when user has email_otp set' do
        before do
          encrypted_token = Devise.token_generator.digest(User, user.email, 'token')
          user.update!(email_otp: encrypted_token)
          stub_session(session_data: { verification_user_id: user.id })
        end

        it 'clears the email_otp' do
          expect { post(users_skip_verification_for_now_path(user: { login: user.username })) }
            .to change { user.reload.email_otp }.to(nil)
        end
      end

      it 'logs the verification skip event' do
        post(users_skip_verification_for_now_path(user: { login: user.username }))

        expect(Gitlab::AppLogger).to have_received(:info).with(
          hash_including(
            message: 'Email Verification',
            event: 'Skipped',
            username: user.username,
            reason: 'user chose to skip verification in grace period',
            ip: '127.0.0.1'
          )
        )
      end

      it 'logs user activity', :freeze_time do
        expect { post(users_skip_verification_for_now_path(user: { login: user.username })) }
          .to change { user.reload.last_activity_on }.to(Date.today)
      end

      context 'when user signed in from an unknown remote IP' do
        let(:user) { create(:user, :with_sign_ins) }
        let(:malicious_ip) { '203.0.113.1' }

        it 'calls verify_known_sign_in and notifies the user about this sign in activity' do
          expect_next_instance_of(NotificationService) do |instance|
            expect(instance).to receive(:unknown_sign_in)
          end

          post(users_skip_verification_for_now_path(
            user: { login: user.username }),
            headers: { 'REMOTE_ADDR' => malicious_ip }
          )
        end
      end
    end

    context 'when user is not permitted to skip email OTP in grace period' do
      let(:permitted_to_skip_email_otp_in_grace_period) { false }

      it 'returne a 403 status code and does not remove verification_user_id session key' do
        post(users_skip_verification_for_now_path(user: { login: user.username }))

        expect(request.session[:verification_user_id]).to eq(user.id)
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when no verification_user_id session variable exists' do
      before do
        stub_session(session_data: {})
      end

      it 'returns a 422 status code' do
        post(users_skip_verification_for_now_path(user: { login: user.username }))

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'skip_verification_confirmation' do
    let(:permitted_to_skip_email_otp_in_grace_period) { true }
    let(:email_otp_required_after) { 1.day.from_now }
    let(:expected_redirect_url) { root_path }

    before do
      user.update!(email_otp_required_after: email_otp_required_after)

      allow_next_instance_of(SessionsController) do |controller|
        allow(controller).to receive(
          :permitted_to_skip_email_otp_in_grace_period?
        ).with(user).and_return(permitted_to_skip_email_otp_in_grace_period)

        allow(controller).to receive(:after_sign_in_path_for)
          .with(user).and_return(expected_redirect_url)
      end

      sign_in(user) # to ensure that current_user is populated
    end

    context 'when user is permitted to skip email OTP in grace period' do
      context 'when verification_user_id session exists' do
        before do
          stub_session(session_data: { verification_user_id: user.id })
        end

        it 'renders skip_verification_confirmation template with correct layout and locals' do
          get(users_skip_verification_confirmation_path)

          expect(response).to render_template('skip_verification_confirmation')
          expect(response.body).to include(expected_redirect_url)
          expect(response.body).to include(email_otp_required_after.strftime('%B %d, %Y'))
        end
      end

      context 'when verification_user_id does not exist' do
        before do
          stub_session(session_data: {})
        end

        it 'returns error and does not render the template' do
          get(users_skip_verification_confirmation_path)

          expect(response).not_to render_template('skip_verification_confirmation')
          expect(json_response).to eq('status' => 'failure')
        end
      end

      context 'when email_based_mfa feature flag is disabled' do
        before do
          stub_feature_flags(email_based_mfa: false)
        end

        it 'returns error and does not render the template' do
          get(users_skip_verification_confirmation_path)

          expect(response).not_to render_template('skip_verification_confirmation')
          expect(json_response).to eq('status' => 'failure')
        end
      end

      context 'when current_user is nil (user is signed out)' do
        before do
          sign_out(user)
        end

        it 'returns error and does not render the template' do
          get(users_skip_verification_confirmation_path)

          expect(response).not_to render_template('skip_verification_confirmation')
          expect(json_response).to eq('status' => 'failure')
        end
      end
    end

    context 'when user is not permitted to skip email OTP' do
      let(:permitted_to_skip_email_otp_in_grace_period) { false }

      it 'returns error and does not render the template' do
        get(users_skip_verification_confirmation_path)

        expect(response).not_to render_template('skip_verification_confirmation')
        expect(json_response).to eq('status' => 'failure')
      end
    end
  end

  describe '#fallback_to_email_otp' do
    context 'when user has email_otp_required_after set to nil' do
      let(:user) { create(:user, email_otp_required_after: nil) }

      it 'is not permitted to fallback to email otp' do
        post(users_fallback_to_email_otp_path(user: { login: user.username }))

        expect(json_response).to match({
          'success' => false,
          'message' => 'Not permitted.'
        })
      end
    end

    context 'when user has email_otp_required_after set to the future' do
      let(:user) { create(:user, email_otp_required_after: Time.zone.now + 1.day) }

      it 'is not permitted to fallback to email otp' do
        post(users_fallback_to_email_otp_path(user: { login: user.username }))

        expect(json_response).to match({
          'success' => false,
          'message' => 'Not permitted.'
        })
      end
    end

    context 'when user has email_otp_required_after set to the past' do
      let(:user) { create(:user, email: 'user1@example.org', email_otp_required_after: Time.zone.now - 1.day) }

      context 'when email_based_mfa ff is disabled for the user' do
        before do
          Feature.disable(:email_based_mfa, user)
        end

        it 'is not permitted to fallback to email otp' do
          post(users_fallback_to_email_otp_path(user: { login: user.username }))
          expect(json_response).to match({
            'success' => false,
            'message' => 'Not permitted.'
          })
        end
      end

      context 'when user is locked' do
        before do
          user.lock_access!
        end

        it 'returns error' do
          post(users_fallback_to_email_otp_path(user: { login: user.username }))

          expect(json_response).to match({
            'success' => false,
            'message' => 'Not permitted.'
          })
        end
      end

      context 'when user is not treated as locked' do
        it 'is permitted to fallback to email otp' do
          post(users_fallback_to_email_otp_path(user: { login: user.username }))

          expect(session[:verification_user_id]).to eq(user.id)
          expect(response).to have_gitlab_http_status(:ok)

          expect(json_response).to match({
            "status" => "success"
          })
        end
      end
    end
  end
end
