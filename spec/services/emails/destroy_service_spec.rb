require 'spec_helper'

describe Emails::DestroyService, services: true do
  let!(:user) { create(:user) }
  let!(:email) { create(:email, user: user) }

  subject(:service) { described_class.new(user, opts) }

  describe '#execute' do
    it 'creates an email with valid attributes' do
      expect { service.execute }.to change { user.emails.count }.by(-1)
    end
  end
end
