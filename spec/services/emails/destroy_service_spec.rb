# frozen_string_literal: true

require 'spec_helper'

describe Emails::DestroyService do
  let!(:user) { create(:user) }
  let!(:email) { create(:email, user: user) }

  subject(:service) { described_class.new(user, user: user) }

  describe '#execute' do
    it 'removes an email' do
      response = service.execute(email)

      expect(user.emails).not_to include(email)
      expect(response).to be true
    end
  end
end
