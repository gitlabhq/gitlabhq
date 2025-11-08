# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe DeviseMailer, feature_category: :user_management do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  shared_examples 'it validates recipients' do
    let(:opts) { { to: ['example@example.com', 'example2@example.com'] } }

    # The error is only raised when delivery occurs
    it 'raises an error when delivering now' do
      expect { subject.deliver_now }.to raise_error(Gitlab::Email::MultipleRecipientsError)
    end
  end

  let(:opts) { {} }

  describe "#confirmation_instructions" do
    subject { described_class.confirmation_instructions(user, 'faketoken', opts) }

    let(:user) { create(:user, created_at: 1.minute.ago) }

    it_behaves_like 'it validates recipients'

    context "when confirming a new account" do
      it "shows the expected text" do
        expect(subject.body.encoded).to have_text "Welcome"
        expect(subject.body.encoded).not_to have_text user.email
      end
    end

    context "when confirming the unconfirmed_email" do
      subject { described_class.confirmation_instructions(user, user.confirmation_token, { to: user.unconfirmed_email }) }

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

    context 'for secondary email' do
      let(:secondary_email) { create(:email) }

      subject { described_class.confirmation_instructions(secondary_email, 'faketoken', opts) }

      it_behaves_like 'it validates recipients'

      it 'has the correct subject and body', :aggregate_failures do
        is_expected.to have_subject I18n.t('devise.mailer.confirmation_instructions.subject')

        is_expected.to have_text_part_content(
          format(_("%{name}, confirm your email address now!"), name: secondary_email.user.name)
        )
        is_expected.to have_html_part_content(
          format(_("%{name}, confirm your email address now!"), name: secondary_email.user.name)
        )

        is_expected.to have_text_part_content(
          secondary_email.email
        )
        is_expected.to have_html_part_content(
          secondary_email.email
        )

        is_expected.to have_text_part_content(
          format(_('Confirm this email address within %{cut_off_days} days, otherwise the email address is removed.'), cut_off_days: ApplicationSetting::USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS)
        )
        is_expected.to have_html_part_content(
          format(_('Confirm this email address within %{cut_off_days} days, otherwise the email address is removed.'), cut_off_days: ApplicationSetting::USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS)
        )
      end
    end
  end

  describe '#password_change_by_admin' do
    subject { described_class.password_change_by_admin(user, opts) }

    let_it_be(:user) { create(:user) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'it validates recipients'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject(/^Password changed by administrator$/i)
    end

    it 'includes the correct content' do
      is_expected.to have_body_text(/An administrator changed the password for your GitLab account/)
    end

    it 'includes a link to GitLab' do
      is_expected.to have_body_text(/#{Gitlab.config.gitlab.url}/)
    end
  end

  describe '#user_admin_approval' do
    subject { described_class.user_admin_approval(user, opts) }

    let_it_be(:user) { create(:user) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'it validates recipients'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject 'Welcome to GitLab!'
    end

    it 'greets the user' do
      is_expected.to have_body_text(/Hi #{user.name}!/)
    end

    it 'includes the correct content' do
      is_expected.to have_body_text(/Your GitLab account request has been approved!/)
    end

    it 'includes a link to GitLab' do
      is_expected.to have_link(Gitlab.config.gitlab.url)
    end
  end

  describe '#reset_password_instructions' do
    let_it_be(:user) { create(:user) }

    subject do
      described_class.reset_password_instructions(user, 'faketoken', opts)
    end

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'it validates recipients'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject 'Reset password instructions'
    end

    it 'greets the user' do
      is_expected.to have_body_text(/Hello, #{user.name}!/)
    end

    it 'includes the correct content' do
      is_expected.to have_text(/Someone, hopefully you, has requested to reset the password for your GitLab account on #{Gitlab.config.gitlab.url}/)
      is_expected.to have_body_text(/If you did not perform this request, you can safely ignore this email./)
      is_expected.to have_body_text(/Otherwise, click the link below to complete the process./)
    end

    it 'includes a link to reset the password' do
      is_expected.to have_link("Reset password", href: "#{Gitlab.config.gitlab.url}/users/password/edit?reset_password_token=faketoken")
    end

    it 'has the mailgun suppression bypass header' do
      is_expected.to have_header 'X-Mailgun-Suppressions-Bypass', 'true'
    end

    context 'with email in opts' do
      let(:email) { 'example@example.com' }
      let(:opts) { { to: email } }

      it 'is sent to the specified email' do
        is_expected.to deliver_to email
      end
    end
  end

  describe '#email_changed' do
    let(:content_saas) { 'If you did not initiate this change, please contact your group owner immediately. If you have a Premium or Ultimate tier subscription, you can also contact GitLab support.' }
    let(:content_self_managed) { 'If you did not initiate this change, please contact your administrator immediately.' }
    let_it_be(:user) { create(:user) }

    subject { described_class.email_changed(user, opts) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it validates recipients'

    it 'is sent to the user' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject 'Email Changed'
    end

    it 'greets the user' do
      is_expected.to have_body_text(/Hello, #{user.name}!/)
    end

    context 'when self-managed' do
      it 'has the expected content of self managed instance' do
        is_expected.to have_body_text content_self_managed
      end
    end

    context 'when saas', :saas do
      it 'has the expected content of saas instance' do
        is_expected.to have_body_text content_saas
      end
    end

    context "email contains updated id" do
      before do
        user.update!(email: "new_email@test.com")
      end

      it 'includes changed email id' do
        is_expected.to have_body_text(/email is being changed to new_email@test.com./)
      end
    end
  end
end
