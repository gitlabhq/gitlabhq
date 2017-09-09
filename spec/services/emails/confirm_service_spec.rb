require 'spec_helper'

describe Emails::ConfirmService do
  let(:user) { create(:user) }
  let(:opts) { { email: 'new@email.com' } }

  subject(:service) { described_class.new(user, opts) }

  describe '#execute' do
    it 'sends a confirmation email again' do
      email = user.emails.create(email: opts[:email])
      mail  = service.execute
      expect(mail.subject).to eq('Confirmation instructions')
    end
  end
end
