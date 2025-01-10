# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Profile, feature_category: :user_profile do
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
      is_expected.to have_body_text(/Click here to set your password/)
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
    let(:new_user) { create(:user, email: new_user_address) }

    subject { Notify.new_user_email(new_user.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'a new user email'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'does not contain the new user\'s password' do
      is_expected.not_to have_body_text(new_user.password)
      is_expected.not_to have_body_text(/password/)
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
      is_expected.to have_subject(/^SSH key was added to your account$/i)
    end

    it 'contains the new ssh key title' do
      is_expected.to have_body_text(/#{key.title}/)
    end

    it 'includes a link to ssh keys page' do
      is_expected.to have_body_text(/#{user_settings_ssh_keys_path}/)
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
      is_expected.to have_subject(/^GPG key was added to your account$/i)
    end

    it 'contains the new gpg key title' do
      is_expected.to have_body_text(/#{gpg_key.fingerprint}/)
    end

    it 'includes a link to gpg keys page' do
      is_expected.to have_body_text(/#{user_settings_gpg_keys_path}/)
    end

    context 'with GPG key that does not exist' do
      it { expect { Notify.new_gpg_key_email('foo') }.not_to raise_error }
    end
  end

  describe 'user personal access token has been created' do
    let_it_be(:user) { create(:user) }
    let_it_be(:token) { create(:personal_access_token, user: user) }

    context 'when valid' do
      subject { Notify.access_token_created_email(user, token.name) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'is sent to the user' do
        is_expected.to deliver_to user.email
      end

      it 'has the correct subject' do
        is_expected.to have_subject(/^A new personal access token has been created$/i)
      end

      it 'provides the names of the token' do
        is_expected.to have_body_text(/#{token.name}/)
      end

      it 'includes a link to personal access tokens page' do
        is_expected.to have_body_text(/#{user_settings_personal_access_tokens_path}/)
      end

      it 'includes the email reason' do
        is_expected.to have_body_text %r{You're receiving this email because of your account on <a .*>localhost</a>}
      end
    end
  end

  describe 'personal access token is about to expire' do
    let_it_be(:user) { create(:user) }

    subject { Notify.access_token_about_to_expire_email(user, ['example token']) }

    it { is_expected.to deliver_to(user) }
    it { is_expected.to have_subject(/^Your personal access tokens will expire in 7 days or less$/i) }
    it { is_expected.to have_body_text(/#{user_settings_personal_access_tokens_path}/) }
    it { is_expected.to have_body_text(/example token/) }

    context 'when passed days_to_expire parameter' do
      subject { Notify.access_token_about_to_expire_email(user, ['example token'], days_to_expire: 42) }

      it { is_expected.to have_subject(/^Your personal access tokens will expire in 42 days or less$/i) }
      it { is_expected.to have_body_text('42') }
    end
  end

  describe 'resource access token is about to expire' do
    let_it_be(:user) { create(:user) }

    shared_examples 'resource about to expire email' do
      it 'is sent to the owners' do
        is_expected.to deliver_to user
      end

      it 'has the correct subject' do
        is_expected.to have_subject(/^Your resource access tokens will expire in 7 days or less$/i)
      end

      it 'includes a link to access tokens page' do
        is_expected.to have_body_text(/#{resource_access_tokens_path}/)
      end

      it 'provides the names of expiring tokens' do
        is_expected.to have_body_text(/#{expiring_token.name}/)
      end

      it 'includes the email reason' do
        is_expected.to have_body_text %r{You're receiving this email because of your account on <a .*>localhost</a>}
      end
    end

    context 'when access token belongs to a group' do
      let_it_be(:project_bot) { create(:user, :project_bot) }
      let_it_be(:expiring_token) { create(:personal_access_token, user: project_bot, expires_at: 5.days.from_now) }
      let_it_be(:resource) { create(:group) }
      let_it_be(:resource_access_tokens_path) { group_settings_access_tokens_path(resource) }

      before_all do
        resource.add_owner(user)
        resource.add_developer(project_bot)
      end

      subject { Notify.bot_resource_access_token_about_to_expire_email(user, resource, expiring_token.name) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'
      it_behaves_like 'resource about to expire email'
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it 'includes the email reason' do
        is_expected.to have_body_text _('You are receiving this email because you are an Owner of the Group.')
      end

      context 'when passed days_to_expire parameter' do
        subject { Notify.bot_resource_access_token_about_to_expire_email(user, resource, expiring_token.name, days_to_expire: 42) }

        it { is_expected.to have_body_text('42') }
      end
    end

    context 'when access token belongs to a project' do
      let_it_be(:project_bot) { create(:user, :project_bot) }
      let_it_be(:expiring_token) { create(:personal_access_token, user: project_bot, expires_at: 5.days.from_now) }
      let_it_be(:resource) { create(:project) }
      let_it_be(:resource_access_tokens_path) { project_settings_access_tokens_path(resource) }

      before_all do
        resource.add_maintainer(user)
        resource.add_reporter(project_bot)
      end

      subject { Notify.bot_resource_access_token_about_to_expire_email(user, resource, expiring_token.name) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'
      it_behaves_like 'resource about to expire email'
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it 'includes the email reason' do
        is_expected.to have_body_text _('You are receiving this email because you are either an Owner or Maintainer of the project.')
      end

      context 'when passed days_to_expire parameter' do
        subject { Notify.bot_resource_access_token_about_to_expire_email(user, resource, expiring_token.name, days_to_expire: 42) }

        it { is_expected.to have_body_text('42') }
      end
    end
  end

  describe 'user personal access token has expired' do
    let_it_be(:user) { create(:user) }
    let_it_be(:pat) { create(:personal_access_token, user: user) }

    context 'when valid' do
      subject { Notify.access_token_expired_email(user, [pat.name]) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'is sent to the user' do
        is_expected.to deliver_to user.email
      end

      it 'has the correct subject' do
        is_expected.to have_subject(/Your personal access tokens have expired/)
      end

      it 'mentions the access token has expired' do
        is_expected.to have_body_text(/The following personal access tokens have expired:/)
        is_expected.to have_body_text(/#{pat.name}/)
      end

      it 'includes a link to personal access tokens page' do
        is_expected.to have_body_text(/#{user_settings_personal_access_tokens_path}/)
      end

      it 'includes the email reason' do
        is_expected.to have_body_text %r{You're receiving this email because of your account on <a .*>localhost</a>}
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

  describe 'user personal access token has been revoked' do
    let_it_be(:user) { create(:user) }
    let_it_be(:token) { create(:personal_access_token, user: user) }

    context 'when valid' do
      subject { Notify.access_token_revoked_email(user, token.name) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'is sent to the user' do
        is_expected.to deliver_to user.email
      end

      it 'has the correct subject' do
        is_expected.to have_subject(/^Your personal access token has been revoked$/i)
      end

      it 'provides the names of the token' do
        is_expected.to have_body_text(/#{token.name}/)
      end

      it 'wont include the revocation reason' do
        is_expected.not_to have_body_text %r{We found your token in a public project and have automatically revoked it to protect your account.$}
      end

      it 'includes the email reason' do
        is_expected.to have_body_text %r{You're receiving this email because of your account on <a .*>localhost</a>}
      end
    end

    context 'when source is provided' do
      subject { Notify.access_token_revoked_email(user, token.name, :secret_detection) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'is sent to the user' do
        is_expected.to deliver_to user.email
      end

      it 'has the correct subject' do
        is_expected.to have_subject(/^Your personal access token has been revoked$/i)
      end

      it 'provides the names of the token' do
        is_expected.to have_body_text(/#{token.name}/)
      end

      it 'includes the revocation reason' do
        is_expected.to have_body_text %r{We found your token in a public project and have automatically revoked it to protect your account.$}
      end

      it 'includes the email reason' do
        is_expected.to have_body_text %r{You're receiving this email because of your account on <a .*>localhost</a>}
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
      it { is_expected.to have_body_text(/#{user_settings_ssh_keys_url}/) }
    end

    shared_examples 'includes the email reason' do
      it { is_expected.to have_body_text %r{You're receiving this email because of your account on <a .*>localhost</a>} }
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
    let(:user) { create(:user) }
    let(:ip) { '169.0.0.1' }
    let(:current_time) { Time.current }
    let(:country) { 'Germany' }
    let(:city) { 'Frankfurt' }
    let(:email) { Notify.unknown_sign_in_email(user, ip, current_time, country: country, city: city) }

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

    it 'mentions the username' do
      is_expected.to have_body_text user.name
      is_expected.to have_body_text user.username
    end

    it 'mentions the new sign-in IP' do
      is_expected.to have_body_text ip
    end

    it 'mentions the time' do
      is_expected.to have_body_text current_time.strftime('%Y-%m-%d %H:%M:%S %Z')
    end

    it 'includes a link to the change password documentation' do
      is_expected.to have_body_text help_page_url('user/profile/user_passwords.md', anchor: 'change-your-password')
    end

    it 'mentions two factor authentication when two factor is not enabled' do
      is_expected.to have_body_text 'two-factor authentication'
    end

    it 'includes a link to two-factor authentication documentation' do
      is_expected.to have_body_text help_page_url('user/profile/account/two_factor_authentication.md')
    end

    it 'shows location information' do
      is_expected.to have_body_text _('Location')
      is_expected.to have_body_text country
      is_expected.to have_body_text city
    end

    context 'when no location information was given' do
      let(:country) { nil }
      let(:city) { nil }

      it { is_expected.not_to have_body_text _('Location') }
    end

    context 'when two factor authentication is enabled' do
      let(:user) { create(:user, :two_factor) }

      it 'does not mention two factor authentication' do
        expect(Notify.unknown_sign_in_email(user, ip, current_time))
          .not_to have_body_text(/two-factor authentication/)
      end
    end
  end

  describe 'user attempted sign in with wrong 2FA OTP email' do
    let_it_be(:user) { create(:user) }
    let_it_be(:ip) { '169.0.0.1' }
    let_it_be(:current_time) { Time.current }
    let_it_be(:email) { Notify.two_factor_otp_attempt_failed_email(user, ip, current_time) }

    subject { email }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject "Attempted sign in to #{Gitlab.config.gitlab.host} using an incorrect verification code"
    end

    it 'mentions the IP address' do
      is_expected.to have_body_text ip
    end

    it 'mentioned the time' do
      is_expected.to have_body_text current_time.strftime('%Y-%m-%d %H:%M:%S %Z')
    end

    it 'includes a link to the change password documentation' do
      is_expected.to have_body_text help_page_url('user/profile/user_passwords.md', anchor: 'change-your-password')
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
      is_expected.to have_subject(/^Two-factor authentication disabled$/i)
    end

    it 'includes a link to two-factor authentication settings page' do
      is_expected.to have_body_text(/#{profile_two_factor_auth_path}/)
    end
  end

  describe 'added a new email address' do
    let_it_be(:user) { create(:user) }
    let_it_be(:email) { create(:email, user: user) }

    subject { Notify.new_email_address_added_email(user, email) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject(/^New email address added$/i)
    end

    it 'includes a link to the email address page' do
      is_expected.to have_body_text(/#{profile_emails_path}/)
    end
  end

  describe 'awarded a new achievement' do
    let(:user) { build(:user) }
    let(:achievement) { build(:achievement) }

    subject { Notify.new_achievement_email(user, achievement) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject("#{achievement.namespace.full_path} awarded you the #{achievement.name} achievement")
    end

    it 'includes a link to the profile page' do
      is_expected.to have_body_text(group_url(achievement.namespace))
    end

    it 'includes a link to the awarding group' do
      is_expected.to have_body_text(user_url(user))
    end
  end
end
