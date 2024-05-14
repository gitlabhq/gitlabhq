# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecoverableByAnyEmail, feature_category: :system_access do
  describe '.send_reset_password_instructions' do
    include EmailHelpers

    subject(:send_reset_password_instructions) do
      User.send_reset_password_instructions(email: email)
    end

    let_it_be(:user) { create(:user) }
    let_it_be(:user_confirmed_primary_email) { user.email }

    let_it_be(:user_confirmed_secondary_email) do
      create(:email, :confirmed, user: user, email: 'confirmed-secondary-email@example.com').email
    end

    let_it_be(:user_unconfirmed_secondary_email) do
      create(:email, user: user, email: 'unconfirmed-secondary-email@example.com').email
    end

    let_it_be(:unknown_email) { 'attacker@example.com' }
    let_it_be(:invalid_email) { 'invalid_email' }
    let_it_be(:sql_injection_email) { 'sql-injection-email@example.com OR 1=1' }

    let_it_be(:another_user_confirmed_primary_email) { create(:user).email }

    let_it_be(:another_user) { create(:user, :unconfirmed) }
    let_it_be(:another_user_unconfirmed_primary_email) { another_user.email }

    shared_examples "sends 'Reset password instructions' email" do
      it 'finds the user' do
        expect(send_reset_password_instructions).to eq(expected_user)
      end

      it 'sends the email' do
        reset_delivered_emails!

        expect { send_reset_password_instructions }.to have_enqueued_mail(DeviseMailer, :reset_password_instructions)

        perform_enqueued_jobs

        expect_only_one_email_to_be_sent(subject: 'Reset password instructions', to: [email])
      end
    end

    shared_examples "does not send 'Reset password instructions' email" do
      # If user is not found, returns a new user with errors.
      # See https://github.com/heartcombo/devise/blob/main/lib/devise/models/recoverable.rb
      it 'does not find the user' do
        expect(send_reset_password_instructions).to be_instance_of User
        expect(send_reset_password_instructions).to be_new_record
        expect(send_reset_password_instructions.errors).not_to be_empty
      end

      it 'does not send email to anyone' do
        reset_delivered_emails!

        expect { send_reset_password_instructions }
          .not_to have_enqueued_mail(DeviseMailer, :reset_password_instructions)

        perform_enqueued_jobs

        should_not_email_anyone
      end
    end

    shared_examples "does not send 'Reset password instructions' email when password auth is not allowed" do
      it 'finds the user' do
        expect(send_reset_password_instructions).to eq(expected_user)
      end

      it 'returns the user with error' do
        expect(send_reset_password_instructions.errors[:password])
          .to include(_('Password authentication is unavailable.'))
      end

      it 'does not send email to anyone' do
        reset_delivered_emails!

        expect { send_reset_password_instructions }
          .not_to have_enqueued_mail(DeviseMailer, :reset_password_instructions)

        perform_enqueued_jobs

        should_not_email_anyone
      end
    end

    context "when email param matches user's confirmed primary email" do
      let(:expected_user) { user }
      let(:email) { user_confirmed_primary_email }

      it_behaves_like "sends 'Reset password instructions' email"
    end

    context "when email param matches user's unconfirmed primary email" do
      let(:expected_user) { another_user }
      let(:email) { another_user_unconfirmed_primary_email }

      it_behaves_like "sends 'Reset password instructions' email"
    end

    context "when email param matches user's confirmed secondary email" do
      let(:expected_user) { user }
      let(:email) { user_confirmed_secondary_email }

      it_behaves_like "sends 'Reset password instructions' email"
    end

    context "when email param matches user's unconfirmed secondary email" do
      let(:email) { user_unconfirmed_secondary_email }

      it_behaves_like "does not send 'Reset password instructions' email"
    end

    context 'when email param is unknown email' do
      let(:email) { unknown_email }

      it_behaves_like "does not send 'Reset password instructions' email"
    end

    context 'when email param is invalid email' do
      let(:email) { invalid_email }

      it_behaves_like "does not send 'Reset password instructions' email"
    end

    context 'when email param with attempt to cause SQL injection' do
      let(:email) { sql_injection_email }

      it_behaves_like "does not send 'Reset password instructions' email"
    end

    context 'when email param is nil' do
      let(:email) { nil }

      it_behaves_like "does not send 'Reset password instructions' email"
    end

    context 'when email param is empty string' do
      let(:email) { '' }

      it_behaves_like "does not send 'Reset password instructions' email"
    end

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/436084
    context 'when email param with multiple emails' do
      let(:email) do
        [
          user_confirmed_primary_email,
          user_confirmed_secondary_email,
          user_unconfirmed_secondary_email,
          unknown_email,
          another_user_confirmed_primary_email,
          another_user_unconfirmed_primary_email
        ]
      end

      it_behaves_like "does not send 'Reset password instructions' email"
    end

    context 'for password authentication availability' do
      let(:expected_user) { create(:user) }
      let(:email) { expected_user.email }

      it_behaves_like "sends 'Reset password instructions' email"

      context 'when password authentication is disabled for web' do
        before do
          stub_application_setting(password_authentication_enabled_for_web: false)
        end

        it_behaves_like "sends 'Reset password instructions' email"
      end

      context 'when password authentication is disabled for git' do
        before do
          stub_application_setting(password_authentication_enabled_for_git: false)
        end

        it_behaves_like "sends 'Reset password instructions' email"
      end

      context 'when password authentication is disabled' do
        before do
          stub_application_setting(password_authentication_enabled_for_web: false)
          stub_application_setting(password_authentication_enabled_for_git: false)
        end

        it_behaves_like "does not send 'Reset password instructions' email when password auth is not allowed"
      end

      context 'for an LDAP user' do
        let(:expected_user) { create(:omniauth_user, :ldap) }

        context "when email param is user's primary email" do
          it_behaves_like "does not send 'Reset password instructions' email when password auth is not allowed"
        end

        context "when email param is user's confirmed secondary email" do
          let(:email) do
            create(:email, :confirmed, user: expected_user, email: 'confirmed-secondary-ldap-email@example.com').email
          end

          it_behaves_like "does not send 'Reset password instructions' email when password auth is not allowed"
        end
      end
    end
  end
end
