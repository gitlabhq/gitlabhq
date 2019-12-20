# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

describe Emails::Profile do
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

    subject { Notify.access_token_about_to_expire_email(user) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject /^Your Personal Access Tokens will expire in 7 days or less$/i
    end

    it 'mentions the access tokens will expire' do
      is_expected.to have_body_text /One or more of your personal access tokens will expire in 7 days or less/
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
end
