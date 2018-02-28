require 'spec_helper'

describe Emails::DestroyService do
  let!(:user) { create(:user) }
  let!(:email) { create(:email, user: user) }

  subject(:service) { described_class.new(user, email: email.email) }

  describe '#execute' do
    it 'removes an email' do
      expect { service.execute }.to change { user.emails.count }.by(-1)
    end
  end
end
