require 'spec_helper'

describe Oauth2::LogoutTokenValidationService, services: true do
  let(:user) { FactoryGirl.create(:user) }
  let(:access_token) { FactoryGirl.create(:doorkeeper_access_token, resource_owner_id: user.id).token }

  context '#validate' do
    it 'returns false when empty' do
      expect(described_class.new(user, nil).validate).to be_falsey
    end

    it 'returns false when incorrect encoding' do
      invalid_token = "\xD800\xD801\xD802"
      expect(described_class.new(user, invalid_token).validate).to be_falsey
    end

    it 'returns true when token is valid' do
      expect(described_class.new(user, access_token).validate).to be_truthy
    end
  end
end
