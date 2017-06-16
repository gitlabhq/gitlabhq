require 'spec_helper'

describe Emails::CreateService, services: true do
  let(:user) { create(:user) }
  let(:opts) { { email: 'new@email.com' } }

  subject(:service) { described_class.new(user, user, opts) }

  describe '#execute' do
    it 'creates an email with valid attributes' do
      expect { service.execute }.to change { Email.count }.by(1)
      expect(Email.where(opts)).not_to be_empty
    end

    it 'has the right user association' do
      service.execute

      expect(user.emails).to eq(Email.where(opts))
    end

    it 'does not create an email if the user has no permissions' do
      expect { described_class.new(create(:user), user, opts).execute }.not_to change { Email.count }
    end

    it 'creates an email if we skip authorization' do
      expect do
        described_class.new(create(:user), user, opts).execute(skip_authorization: true)
      end.to change { Email.count }.by(1)
    end
  end
end
