# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Profile do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  shared_examples 'a new user email' do
    it 'is sent to the new user with the correct subject and body' do
      aggregate_failures do
        is_expected.to deliver_to new_user_address
        is_expected.to have_subject(/^Account was created for you$/i)
        is_expected.to have_body_text(new_user_address)
      end
    end
  end

  describe 'for new users, the email' do
    let(:example_site_path) { root_path }
    let(:new_user) { create(:user, email: new_user_address, created_by_id: 1) }
    let(:token) { 'kETLwRaayvigPq_x3SNM' }

    subject { Notify.new_user_email(new_user.id, token) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'a new user email'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'contains the password text' do
      is_expected.to have_body_text /Click here to set your password/
    end

    it 'includes a link for user to set password' do
      params = "reset_password_token=#{token}"
      is_expected.to have_body_text(
        %r{http://#{Gitlab.config.gitlab.host}(:\d+)?/users/password/edit\?#{params}}
      )
    end

    it 'explains the reset link expiration' do
      is_expected.to have_body_text(/This link is valid for \d+ (hours?|days?)/)
      is_expected.to have_body_text(new_user_password_url)
      is_expected.to have_body_text(/\?user_email=.*%40.*/)
    end
  end

  describe 'for users that signed up, the email' do
    let(:example_site_path) { root_path }
    let(:new_user) { create(:user, email: new_user_address, password: "securePassword") }

    subject { Notify.new_user_email(new_user.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'a new user email'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'does not contain the new user\'s password' do
      is_expected.not_to have_body_text /password/
    end
  end

  describe 'user added ssh key' do
    let(:key) { create(:personal_key) }

    subject { Notify.new_ssh_key_email(key.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the new user' do
      is_expected.to deliver_to key.user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject /^SSH key was added to your account$/i
    end

    it 'contains the new ssh key title' do
      is_expected.to have_body_text /#{key.title}/
    end

    it 'includes a link to ssh keys page' do
      is_expected.to have_body_text /#{profile_keys_path}/
    end

    context 'with SSH key that does not exist' do
      it { expect { Notify.new_ssh_key_email('foo') }.not_to raise_error }
    end
  end

  describe 'user added gpg key' do
    let(:gpg_key) { create(:gpg_key) }

    subject { Notify.new_gpg_key_email(gpg_key.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the new user' do
      is_expected.to deliver_to gpg_key.user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject /^GPG key was added to your account$/i
    end

    it 'contains the new gpg key title' do
      is_expected.to have_body_text /#{gpg_key.fingerprint}/
    end

    it 'includes a link to gpg keys page' do
      is_expected.to have_body_text /#{profile_gpg_keys_path}/
    end

    context 'with GPG key that does not exist' do
      it { expect { Notify.new_gpg_key_email('foo') }.not_to raise_error }
    end
  end

  describe 'user personal access token is about to expire' do
    let_it_be(:user) { create(:user) }
    let_it_be(:expiring_token) { create(:personal_access_token, user: user, expires_at: 5.days.from_now) }

    subject { Notify.access_token_about_to_expire_email(user, [expiring_token.name]) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject /^Your personal access tokens will expire in 7 days or less$/i
    end

    it 'mentions the access tokens will expire' do
      is_expected.to have_body_text /One or more of your personal access tokens will expire in 7 days or less/
    end

    it 'provides the names of expiring tokens' do
      is_expected.to have_body_text /#{expiring_token.name}/
    end

    it 'includes a link to personal access tokens page' do
      is_expected.to have_body_text /#{profile_personal_access_tokens_path}/
    end

    it 'includes the email reason' do
      is_expected.to have_body_text /You're receiving this email because of your account on localhost/
    end

    context 'with User does not exist' do
      it { expect { Notify.access_token_about_to_expire_email('foo') }.not_to raise_error }
    end
  end

  describe 'user personal access token has expired' do
    let_it_be(:user) { create(:user) }

    context 'when valid' do
      subject { Notify.access_token_expired_email(user) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'is sent to the user' do
        is_expected.to deliver_to user.email
      end

      it 'has the correct subject' do
        is_expected.to have_subject /Your personal access token has expired/
      end

      it 'mentions the access token has expired' do
        is_expected.to have_body_text /One or more of your personal access tokens has expired/
      end

      it 'includes a link to personal access tokens page' do
        is_expected.to have_body_text /#{profile_personal_access_tokens_path}/
      end

      it 'includes the email reason' do
        is_expected.to have_body_text /You're receiving this email because of your account on localhost/
      end
    end

    context 'when invalid' do
      context 'when user does not exist' do
        it do
          expect { Notify.access_token_expired_email(nil) }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end

      context 'when user is not active' do
        before do
          user.block!
        end

        it do
          expect { Notify.access_token_expired_email(user) }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end
  end

  describe 'SSH key notification' do
    let_it_be_with_reload(:user) { create(:user) }
    let_it_be(:fingerprints) { ["aa:bb:cc:dd:ee:zz"] }

    shared_examples 'is sent to the user' do
      it { is_expected.to deliver_to user.email }
    end

    shared_examples 'has the correct subject' do |subject_text|
      it { is_expected.to have_subject subject_text }
    end

    shared_examples 'has the correct body text' do |body_text|
      it { is_expected.to have_body_text body_text }
    end

    shared_examples 'includes a link to ssh key page' do
      it { is_expected.to have_body_text /#{profile_keys_url}/ }
    end

    shared_examples 'includes the email reason' do
      it { is_expected.to have_body_text /You're receiving this email because of your account on localhost/ }
    end

    shared_examples 'valid use case' do
      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'
      it_behaves_like 'is sent to the user'
      it_behaves_like 'includes a link to ssh key page'
      it_behaves_like 'includes the email reason'
    end

    shared_examples 'does not send email' do
      it do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    shared_context 'block user' do
      before do
        user.block!
      end
    end

    context 'notification email for expired ssh key' do
      context 'when valid' do
        subject { Notify.ssh_key_expired_email(user, fingerprints) }

        include_examples 'valid use case'

        it_behaves_like 'has the correct subject', /Your SSH key has expired/
        it_behaves_like 'has the correct body text', /SSH keys with the following fingerprints have expired/
      end

      context 'when invalid' do
        context 'when user does not exist' do
          subject { Notify.ssh_key_expired_email(nil, fingerprints) }

          it_behaves_like 'does not send email'
        end

        context 'when user is not active' do
          subject { Notify.ssh_key_expired_email(user, fingerprints) }

          include_context 'block user'

          it_behaves_like 'does not send email'
        end
      end
    end

    context 'notification email for expiring ssh key' do
      context 'when valid' do
        subject { Notify.ssh_key_expiring_soon_email(user, fingerprints) }

        include_examples 'valid use case'

        it_behaves_like 'has the correct subject', /Your SSH key is expiring soon/
        it_behaves_like 'has the correct body text', /SSH keys with the following fingerprints are scheduled to expire soon/
      end

      context 'when invalid' do
        context 'when user does not exist' do
          subject { Notify.ssh_key_expiring_soon_email(nil, fingerprints) }

          it_behaves_like 'does not send email'
        end

        context 'when user is not active' do
          subject { Notify.ssh_key_expiring_soon_email(user, fingerprints) }

          include_context 'block user'

          it_behaves_like 'does not send email'
        end
      end
    end
  end

  describe 'user unknown sign in email' do
    let_it_be(:user) { create(:user) }
    let_it_be(:ip) { '169.0.0.1' }
    let_it_be(:current_time) { Time.current }
    let_it_be(:email) { Notify.unknown_sign_in_email(user, ip, current_time) }

    subject { email }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject "#{Gitlab.config.gitlab.host} sign-in from new location"
    end

    it 'mentions the new sign-in IP' do
      is_expected.to have_body_text ip
    end

    it 'mentioned the time' do
      is_expected.to have_body_text current_time.strftime('%Y-%m-%d %H:%M:%S %Z')
    end

    it 'includes a link to the change password documentation' do
      is_expected.to have_body_text 'https://docs.gitlab.com/ee/user/profile/#changing-your-password'
    end

    it 'mentions two factor authentication when two factor is not enabled' do
      is_expected.to have_body_text 'two-factor authentication'
    end

    it 'includes a link to two-factor authentication documentation' do
      is_expected.to have_body_text 'https://docs.gitlab.com/ee/user/profile/account/two_factor_authentication.html'
    end

    context 'when two factor authentication is enabled' do
      let(:user) { create(:user, :two_factor) }

      it 'does not mention two factor authentication' do
        expect( Notify.unknown_sign_in_email(user, ip, current_time) )
          .not_to have_body_text /two-factor authentication/
      end
    end
  end

  describe 'disabled two-factor authentication email' do
    let_it_be(:user) { create(:user) }

    subject { Notify.disabled_two_factor_email(user) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject /^Two-factor authentication disabled$/i
    end

    it 'includes a link to two-factor authentication settings page' do
      is_expected.to have_body_text /#{profile_two_factor_auth_path}/
    end
  end
end
