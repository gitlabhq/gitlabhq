require 'spec_helper'

describe DeviseConfirmable do

  describe '#confirm' do
    let(:user)  { create(:user) }
    let(:user2) { create(:user) }

    context 'confirming secondary Email' do
      it 'removes secondary email duplicates' do
        user.emails.create(email: 'new@email.com', confirmation_token: 'token_1')
        user2.emails.create(email: 'New@email.com')

        expect(Email.where(email: 'new@email.com').count).to eq 2

        resource = Email.confirm_by_token('token_1')

        expect(resource.errors.empty?).to be_truthy
        expect(Email.where(email: 'new@email.com').count).to eq 1
        expect(Email.confirmed.count).to eq 1
      end

      it 'does not confirm with a confirmed user with same email' do
        user.update_attribute(:confirmed_at, nil)
        user2.emails.create(email: user.email, confirmation_token: 'token_1')
        user.update_attribute(:confirmed_at, Time.now)

        expect(User.confirmed.count).to eq 2
        expect(Email.confirmed.count).to eq 0

        resource = Email.confirm_by_token('token_1')

        expect(resource.errors.empty?).to be_falsy
        expect(resource.errors[:base]).to include('This email address was confirmed to belong to another account')
        expect(User.confirmed.count).to eq 2
        expect(Email.confirmed.count).to eq 0
      end

      it 'does not confirm with a confirmed secondary with same email' do
        user.emails.create(email: 'new@email.com', confirmation_token: 'token_1')
        user2.emails.create(email: 'New@email.com', confirmed_at: Time.now)

        expect(Email.confirmed.count).to eq 1

        resource = Email.confirm_by_token('token_1')

        expect(resource.errors.empty?).to be_falsy
        expect(resource.errors[:base]).to include('This email address was confirmed to belong to another account')
        expect(Email.confirmed.count).to eq 1
      end
    end

    context 'confirming User email' do
      it 'removes secondary email duplicates' do
        user.update_attributes(confirmed_at: nil, confirmation_token: 'token_1')
        user2.emails.create(email: user.email)

        resource = User.confirm_by_token('token_1')

        expect(resource.errors.empty?).to be_truthy
        expect(Email.count).to eq 0
      end
    end
  end
end
