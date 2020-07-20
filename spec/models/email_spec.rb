# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Email do
  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(AsyncDeviseEmail) }
  end

  describe 'validations' do
    it_behaves_like 'an object with RFC3696 compliant email-formated attributes', :email do
      subject { build(:email) }
    end
  end

  it 'normalize email value' do
    expect(described_class.new(email: ' inFO@exAMPLe.com ').email)
      .to eq 'info@example.com'
  end

  describe '#update_invalid_gpg_signatures' do
    let(:user) { create(:user) }

    it 'synchronizes the gpg keys when the email is updated' do
      email = user.emails.create(email: 'new@email.com')

      expect(user).to receive(:update_invalid_gpg_signatures)

      email.confirm
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }

    it 'scopes confirmed emails' do
      create(:email, :confirmed, user: user)
      create(:email, user: user)

      expect(user.emails.count).to eq 2
      expect(user.emails.confirmed.count).to eq 1
    end
  end

  describe 'delegation' do
    let(:user) { create(:user) }

    it 'delegates to :user' do
      expect(build(:email, user: user).username).to eq user.username
    end
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
end
