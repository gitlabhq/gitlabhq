require 'spec_helper'
require 'email_spec'
require 'mailers/shared/notify'

describe Notify do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  describe 'profile notifications' do
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
          %r{http://localhost(:\d+)?/users/password/edit\?#{params}}
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

      it 'should not contain the new user\'s password' do
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
    end

    describe 'user added email' do
      let(:email) { create(:email) }

      subject { Notify.new_email_email(email.id) }

      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'is sent to the new user' do
        is_expected.to deliver_to email.user.email
      end

      it 'has the correct subject' do
        is_expected.to have_subject /^Email was added to your account$/i
      end

      it 'contains the new email address' do
        is_expected.to have_body_text /#{email.email}/
      end

      it 'includes a link to emails page' do
        is_expected.to have_body_text /#{profile_emails_path}/
      end
    end
  end
end
