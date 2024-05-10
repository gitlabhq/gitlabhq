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
    let_it_be(:unconfirmed_user) { create(:user, :unconfirmed) }
    let_it_be(:confirmed_user) { create(:user) }

    let_it_be(:unconfirmed_primary_email) { unconfirmed_user.email }
    let_it_be(:confirmed_primary_email) { described_class.find_by_email(confirmed_user.email) }

    let_it_be(:unconfirmed_secondary_email) { create(:email, user: confirmed_user) }
    let_it_be(:confirmed_secondary_email) { create(:email, :confirmed, user: confirmed_user) }

    describe '.confirmed' do
      it 'returns confirmed emails' do
        expect(described_class.confirmed).to contain_exactly(
          # after user's primary email is confirmed it is stored to 'emails' table
          confirmed_primary_email,
          confirmed_secondary_email
        )
      end
    end

    describe '.unconfirmed' do
      it 'returns unconfirmed secondary emails' do
        expect(described_class.unconfirmed).to contain_exactly(
          # excludes `unconfirmed_primary_email` because
          # user's primary email is not stored to 'emails' table till it is confirmed
          unconfirmed_secondary_email
        )
      end
    end

    describe '.unconfirmed_and_created_before' do
      let(:created_cut_off) { 3.days.ago }

      let!(:unconfirmed_secondary_email_created_before_cut_off) do
        create(:email, created_at: created_cut_off - 1.second)
      end

      let!(:unconfirmed_secondary_email_created_at_cut_off) do
        create(:email, created_at: created_cut_off)
      end

      let!(:unconfirmed_secondary_email_created_after_cut_off) do
        create(:email, created_at: created_cut_off + 1.second)
      end

      let!(:confirmed_secondary_email_created_before_cut_off) do
        create(:email, :confirmed, created_at: created_cut_off - 1.second)
      end

      let!(:confirmed_secondary_email_created_at_cut_off) do
        create(:email, :confirmed, created_at: created_cut_off)
      end

      let!(:confirmed_secondary_email_created_after_cut_off) do
        create(:email, :confirmed, created_at: created_cut_off + 1.second)
      end

      it 'returns unconfirmed secondary emails created before timestamp passed in' do
        expect(described_class.unconfirmed_and_created_before(created_cut_off)).to contain_exactly(
          unconfirmed_secondary_email_created_before_cut_off
        )
      end
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
