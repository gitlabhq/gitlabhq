# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Email do
  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(AsyncDeviseEmail) }
  end

  describe 'validations' do
    it_behaves_like 'an object with email-formatted attributes', :email do
      subject { build(:email) }
    end

    context 'when the email conflicts with the primary email of a different user' do
      let(:user) { create(:user) }
      let(:email) { build(:email, email: user.email) }

      it 'is invalid' do
        expect(email).to be_invalid
      end
    end
  end

  it 'normalize email value' do
    expect(described_class.new(email: ' inFO@exAMPLe.com ').email)
      .to eq 'info@example.com'
  end

  describe '#update_invalid_gpg_signatures' do
    let(:user) { create(:user) }

    it 'synchronizes the gpg keys when the email is updated' do
      email = user.emails.create!(email: 'new@email.com')

      expect(user).to receive(:update_invalid_gpg_signatures)

      email.confirm
    end
  end

  describe 'scopes' do
    let(:user) { create(:user, :unconfirmed) }

    it 'scopes confirmed emails' do
      create(:email, :confirmed, user: user)
      create(:email, user: user)

      expect(user.emails.count).to eq 2
      expect(user.emails.confirmed.count).to eq 1
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:can?).to(:user) }
    it { is_expected.to delegate_method(:username).to(:user) }
    it { is_expected.to delegate_method(:pending_invitations).to(:user) }
    it { is_expected.to delegate_method(:accept_pending_invitations!).to(:user) }
  end

  describe 'Devise emails' do
    let!(:user) { create(:user) }

    describe 'behaviour' do
      it 'sends emails asynchronously' do
        expect do
          user.emails.create!(email: 'hello@hello.com')
        end.to have_enqueued_job.on_queue('mailers')
      end
    end
  end

  describe '#confirm' do
    let(:expired_confirmation_sent_at) { Date.today - described_class.confirm_within - 7.days }
    let(:extant_confirmation_sent_at) { Date.today }

    let(:email) do
      create(:email, email: 'test@gitlab.com').tap do |email|
        email.update!(confirmation_sent_at: confirmation_sent_at)
      end
    end

    shared_examples_for 'unconfirmed email' do
      it 'returns unconfirmed' do
        expect(email.confirmed?).to be_falsey
      end
    end

    context 'when the confirmation period has expired' do
      let(:confirmation_sent_at) { expired_confirmation_sent_at }

      it_behaves_like 'unconfirmed email'

      it 'does not confirm the email' do
        email.confirm

        expect(email.confirmed?).to be_falsey
      end
    end

    context 'when the confirmation period has not expired' do
      let(:confirmation_sent_at) { extant_confirmation_sent_at }

      it_behaves_like 'unconfirmed email'

      it 'confirms the email' do
        email.confirm

        expect(email.confirmed?).to be_truthy
      end
    end
  end

  describe '#force_confirm' do
    let(:expired_confirmation_sent_at) { Date.today - described_class.confirm_within - 7.days }
    let(:extant_confirmation_sent_at) { Date.today }

    let(:email) do
      create(:email, email: 'test@gitlab.com').tap do |email|
        email.update!(confirmation_sent_at: confirmation_sent_at)
      end
    end

    shared_examples_for 'unconfirmed email' do
      it 'returns unconfirmed' do
        expect(email.confirmed?).to be_falsey
      end
    end

    shared_examples_for 'confirms the email on force_confirm' do
      it 'confirms an email' do
        email.force_confirm

        expect(email.reload.confirmed?).to be_truthy
      end
    end

    context 'when the confirmation period has expired' do
      let(:confirmation_sent_at) { expired_confirmation_sent_at }

      it_behaves_like 'unconfirmed email'
      it_behaves_like 'confirms the email on force_confirm'
    end

    context 'when the confirmation period has not expired' do
      let(:confirmation_sent_at) {  extant_confirmation_sent_at }

      it_behaves_like 'unconfirmed email'
      it_behaves_like 'confirms the email on force_confirm'
    end
  end
end
