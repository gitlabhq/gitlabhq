require 'spec_helper'

describe UserRetrievalService, services: true do
  context 'user retrieval' do
    it 'retrieves the correct user' do
      user = create(:user)
      retrieved_user = described_class.new(user.username, user.password).execute

      expect(retrieved_user).to eq(user)
    end

    it 'returns nil when 2FA is enabled' do
      user = create(:user, :two_factor)
      retrieved_user = described_class.new(user.username, user.password).execute

      expect(retrieved_user).to be_nil
    end
  end
end
