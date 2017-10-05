require 'spec_helper'

describe Emails::CreateService do
  let(:user) { create(:user) }
  let(:opts) { { email: 'new@email.com', user: user } }

  subject(:service) { described_class.new(user, opts) }

  describe '#execute' do
    it 'creates an email with valid attributes' do
      expect { service.execute }.to change { Email.count }.by(1)
      expect(Email.where(opts)).not_to be_empty
    end

    it 'creates an email with additional attributes' do
      expect { service.execute(confirmation_token: 'abc') }.to change { Email.count }.by(1)
      expect(Email.where(opts).first.confirmation_token).to eq 'abc'
    end

    it 'has the right user association' do
      service.execute

      expect(user.emails).to eq(Email.where(opts))
    end
  end
end
