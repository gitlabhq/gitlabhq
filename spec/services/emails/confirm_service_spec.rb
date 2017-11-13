require 'spec_helper'

describe Emails::ConfirmService do
  let(:user) { create(:user) }

  subject(:service) { described_class.new(user) }

  describe '#execute' do
    it 'sends a confirmation email again' do
      email = user.emails.create(email: 'new@email.com')
      mail  = service.execute(email)
      expect(mail.subject).to eq('Confirmation instructions')
    end
  end
end
