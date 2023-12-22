# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecoverableByAnyEmail, feature_category: :system_access do
  describe '.send_reset_password_instructions' do
    let_it_be(:user) { create(:user, email: 'test@example.com') }
    let_it_be(:verified_email) { create(:email, :confirmed, user: user) }
    let_it_be(:unverified_email) { create(:email, user: user) }

    subject(:send_reset_password_instructions) do
      User.send_reset_password_instructions(email: email)
    end

    shared_examples 'sends the password reset email' do
      it 'finds the user' do
        expect(send_reset_password_instructions).to eq(user)
      end

      it 'sends the email' do
        expect { send_reset_password_instructions }.to have_enqueued_mail(DeviseMailer, :reset_password_instructions)
      end
    end

    shared_examples 'does not send the password reset email' do
      it 'does not find the user' do
        expect(subject.id).to be_nil
        expect(subject.errors).not_to be_empty
      end

      it 'does not send any email' do
        subject

        expect { subject }.not_to have_enqueued_mail(DeviseMailer, :reset_password_instructions)
      end
    end

    context 'with user primary email' do
      let(:email) { user.email }

      it_behaves_like 'sends the password reset email'
    end

    context 'with user verified email' do
      let(:email) { verified_email.email }

      it_behaves_like 'sends the password reset email'
    end

    context 'with user unverified email' do
      let(:email) { unverified_email.email }

      it_behaves_like 'does not send the password reset email'
    end

    context 'with one email matching user and one not matching' do
      let(:email) { [verified_email.email, 'other_email@example.com'] }

      it 'sends an email only to the user verified email' do
        expect { send_reset_password_instructions }
          .to have_enqueued_mail(DeviseMailer, :reset_password_instructions)
                .with(
                  user,
                  anything, # reset token
                  to: user.verified_emails(include_private_email: false)
                )
      end
    end
  end
end
