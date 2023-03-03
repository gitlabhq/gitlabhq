# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::DestroyService, feature_category: :user_management do
  let!(:user) { create(:user) }
  let!(:email) { create(:email, user: user) }

  subject(:service) { described_class.new(user, user: user) }

  describe '#execute' do
    it 'removes an email' do
      response = service.execute(email)

      expect(user.emails).not_to include(email)
      expect(response).to be true
    end

    context 'when it corresponds to the user primary email' do
      let(:email) { user.emails.find_by!(email: user.email) }

      it 'does not remove the email and raises an exception' do
        expect { service.execute(email) }.to raise_error(StandardError, 'Cannot delete primary email')

        expect(user.emails).to include(email)
      end
    end
  end
end
