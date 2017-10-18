require 'spec_helper'

describe Email do
  describe 'validations' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it_behaves_like 'an object with email-formated attributes', :email do
      subject { build(:email) }
    end
    
    it 'can not add the same email to same user' do
      create(:email, email: 'new@email.com', user: user1)

      expect(build(:email, email: 'new@email.com', user: user1)).not_to be_valid
    end

    it 'can add the same email for different users' do
      create(:email, email: 'new@email.com', user: user1)

      expect(build(:email, email: 'new@email.com', user: user2)).to be_valid
    end

    it 'does not add duplicate email if the other one is already confirmed' do
      create(:email, :confirmed, email: 'new@email.com', user: user1)

      expect(build(:email, email: 'new@email.com', user: user2)).not_to be_valid
    end

    it 'adds if another user has same email and not confirmed' do
      expect(build(:email, email: user1.email, user: user2)).not_to be_valid

      user1.update_attribute(:confirmed_at, nil)

      expect(build(:email, email: user1.email, user: user2)).to be_valid
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
