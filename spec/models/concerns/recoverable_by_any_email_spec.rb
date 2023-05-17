# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecoverableByAnyEmail, feature_category: :system_access do
  describe '.send_reset_password_instructions' do
    let_it_be(:user) { create(:user, email: 'test@example.com') }
    let_it_be(:verified_email) { create(:email, :confirmed, user: user) }
    let_it_be(:unverified_email) { create(:email, user: user) }

    let(:ff_enabled) { true }

    before do
      stub_feature_flags(password_reset_any_verified_email: ff_enabled)
    end

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

      context 'when password_reset_any_verified_email FF is enabled' do
        it_behaves_like 'sends the password reset email'
      end

      context 'when password_reset_any_verified_email FF is not enabled' do
        let(:ff_enabled) { false }

        it_behaves_like 'does not send the password reset email'
      end
    end

    context 'with user unverified email' do
      let(:email) { unverified_email.email }

      it_behaves_like 'does not send the password reset email'
    end
  end

  describe '#send_reset_password_instructions' do
    let_it_be(:user) { create(:user) }
    let_it_be(:opts) { { email: 'random@email.com' } }
    let_it_be(:token) { 'passwordresettoken' }

    before do
      stub_feature_flags(password_reset_any_verified_email: ff_enabled)

      allow(user).to receive(:set_reset_password_token).and_return(token)
    end

    subject { user.send_reset_password_instructions(opts) }

    context 'when password_reset_any_verified_email FF is not enabled' do
      let(:ff_enabled) { false }

      # original Devise behavior
      it 'calls send_reset_password_instructions_notification just with token' do
        expect(user).to receive(:send_reset_password_instructions_notification).with(token)

        subject
      end
    end

    context 'when password_reset_any_verified_email FF is enabled' do
      let(:ff_enabled) { true }

      it 'sends the email' do
        expect { subject }.to have_enqueued_mail(DeviseMailer, :reset_password_instructions)
      end

      it 'calls send_reset_password_instructions_notification with correct arguments' do
        expect(user).to receive(:send_reset_password_instructions_notification).with(token, opts)

        subject
      end

      it 'returns the generated token' do
        expect(subject).to eq(token)
      end
    end
  end
end
