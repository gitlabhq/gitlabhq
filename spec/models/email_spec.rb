require 'spec_helper'

describe Email do
  describe 'validations' do
    it_behaves_like 'an object with email-formated attributes', :email do
      subject { build(:email) }
    end
  end

  it 'normalize email value' do
    expect(described_class.new(email: ' inFO@exAMPLe.com ').email)
      .to eq 'info@example.com'
  end

  describe '#update_invalid_gpg_signatures' do
    let(:user) do
      create(:user, email: 'tula.torphy@abshire.ca').tap do |user|
        user.skip_reconfirmation!
      end
    end
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
end
