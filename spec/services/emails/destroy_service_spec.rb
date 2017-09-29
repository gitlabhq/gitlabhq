require 'spec_helper'

describe Emails::DestroyService do
  let!(:user) { create(:user) }
  let!(:email) { create(:email, user: user) }

  subject(:service) { described_class.new(user, user: user, email: email.email) }
<<<<<<< HEAD

  before do
    stub_licensed_features(extended_audit_events: true)
  end
=======
>>>>>>> upstream/master

  describe '#execute' do
    it 'removes an email' do
      expect { service.execute }.to change { user.emails.count }.by(-1)
    end

    it 'registers a security event' do
      expect { service.execute }.to change { SecurityEvent.count }.by(1)
    end
  end
end
