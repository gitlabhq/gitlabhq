# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe DeviseMailer do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  describe "#confirmation_instructions" do
    subject { described_class.confirmation_instructions(user, 'faketoken', {}) }

    context "when confirming a new account" do
      let(:user) { create(:user, created_at: 1.minute.ago) }

      it "shows the expected text" do
        expect(subject.body.encoded).to have_text "Welcome"
        expect(subject.body.encoded).not_to have_text user.email
      end
    end

    context "when confirming the unconfirmed_email" do
      subject { described_class.confirmation_instructions(user, user.confirmation_token, { to: user.unconfirmed_email }) }

      let(:user) { create(:user) }

      before do
        user.update!(email: 'unconfirmed-email@example.com')
      end

      it "shows the expected text" do
        expect(subject.body.encoded).not_to have_text "Welcome"
        expect(subject.body.encoded).to have_text user.unconfirmed_email
        expect(subject.body.encoded).not_to have_text user.email
      end
    end

    context "when re-confirming the primary email after a security issue" do
      let(:user) { create(:user, created_at: Devise.confirm_within.ago) }

      it "shows the expected text" do
        expect(subject.body.encoded).not_to have_text "Welcome"
        expect(subject.body.encoded).to have_text user.email
      end
    end
  end

  describe '#password_change_by_admin' do
    subject { described_class.password_change_by_admin(user) }

    let_it_be(:user) { create(:user) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject /^Password changed by administrator$/i
    end

    it 'includes the correct content' do
      is_expected.to have_body_text /An administrator changed the password for your GitLab account/
    end

    it 'includes a link to GitLab' do
      is_expected.to have_body_text /#{Gitlab.config.gitlab.url}/
    end
  end

  describe '#user_admin_approval' do
    subject { described_class.user_admin_approval(user) }

    let_it_be(:user) { create(:user) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject 'Welcome to GitLab!'
    end

    it 'greets the user' do
      is_expected.to have_body_text /Hi #{user.name}!/
    end

    it 'includes the correct content' do
      is_expected.to have_body_text /Your GitLab account request has been approved!/
    end

    it 'includes a link to GitLab' do
      is_expected.to have_link(Gitlab.config.gitlab.url)
    end
  end

  describe '#reset_password_instructions' do
    let_it_be(:user) { create(:user) }
    let(:params) { {} }

    subject do
      described_class.reset_password_instructions(user, 'faketoken', params)
    end

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject 'Reset password instructions'
    end

    it 'greets the user' do
      is_expected.to have_body_text /Hello, #{user.name}!/
    end

    it 'includes the correct content' do
      is_expected.to have_text /Someone, hopefully you, has requested to reset the password for your GitLab account on #{Gitlab.config.gitlab.url}/
      is_expected.to have_body_text /If you did not perform this request, you can safely ignore this email./
      is_expected.to have_body_text /Otherwise, click the link below to complete the process./
    end

    it 'includes a link to reset the password' do
      is_expected.to have_link("Reset password", href: "#{Gitlab.config.gitlab.url}/users/password/edit?reset_password_token=faketoken")
    end

    it 'has the mailgun suppression bypass header' do
      is_expected.to have_header 'X-Mailgun-Suppressions-Bypass', 'true'
    end

    context 'with email in params' do
      let(:email) { 'example@example.com' }
      let(:params) { { to: email } }

      it 'is sent to the specified email' do
        is_expected.to deliver_to email
      end
    end
  end

  describe '#email_changed' do
    subject { described_class.email_changed(user, {}) }

    let_it_be(:user) { create(:user) }

    it_behaves_like 'an email sent from GitLab'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject 'Email Changed'
    end

    it 'greets the user' do
      is_expected.to have_body_text /Hello, #{user.name}!/
    end

    context "email contains updated id" do
      before do
        user.update!(email: "new_email@test.com")
      end

      it 'includes changed email id' do
        is_expected.to have_body_text /email is being changed to new_email@test.com./
      end
    end
  end
end
