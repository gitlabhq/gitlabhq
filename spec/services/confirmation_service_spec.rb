require 'spec_helper'

describe ConfirmationService do

  describe '#execute' do
    let(:user)  { create(:user) }
    let(:user2) { create(:user) }

    context 'confirming secondary email' do
      it 'removes secondary email duplicates' do
        user.emails.create(email: 'new@email.com', confirmation_token: 'token_1')
        user2.emails.create(email: 'new@email.com')
        
        expect(Email.where(email: 'new@email.com').count).to eq 2

        service  = described_class.new(Email, 'token_1')
        resource = service.execute

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

        service  = described_class.new(Email, 'token_1')
        resource = service.execute

        expect(resource.errors.empty?).to be_falsy
        expect(User.confirmed.count).to eq 2
        expect(Email.confirmed.count).to eq 0
      end

      it 'does not confirm with a confirmed secondary with same email' do
        user.emails.create(email: 'new@email.com', confirmation_token: 'token_1')
        user2.emails.create(email: 'new@email.com', confirmed_at: Time.now)
        
        expect(Email.confirmed.count).to eq 1

        service  = described_class.new(Email, 'token_1')
        resource = service.execute

        expect(resource.errors.empty?).to be_falsy
        expect(Email.confirmed.count).to eq 1
      end
    end
    
    context 'confirming user email' do
      it 'removes secondary email duplicates' do
        user.update_attributes(confirmed_at: nil, confirmation_token: 'token_1')
        user2.emails.create(email: user.email)
        
        service  = described_class.new(User, 'token_1')
        resource = service.execute

        expect(resource.errors.empty?).to be_truthy
        expect(Email.count).to eq 0
      end
    end
  end
end
