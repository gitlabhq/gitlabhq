require 'spec_helper'

describe Oauth2::LogoutTokenValidationService, services: true do
  let(:user) { FactoryGirl.create(:user) }
  let(:access_token) { FactoryGirl.create(:doorkeeper_access_token, resource_owner_id: user.id).token }
  let(:logout_state) { Gitlab::Geo::OauthSession.new(access_token: access_token).generate_logout_state }

  context '#execute' do
    it 'return error when params are empty' do
      result = described_class.new(user, {}).execute
      expect(result[:status]).to eq(:error)
    end

    it 'returns error when state param is empty' do
      result = described_class.new(user, { state: nil }).execute
      expect(result[:status]).to eq(:error)

      result = described_class.new(user, { state: '' }).execute
      expect(result[:status]).to eq(:error)
    end

    it 'returns error when incorrect encoding' do
      invalid_token = "\xD800\xD801\xD802"
      allow_any_instance_of(Gitlab::Geo::OauthSession).to receive(:extract_logout_token) { invalid_token }

      result = described_class.new(user, { state: logout_state }).execute
      expect(result[:status]).to eq(:error)
    end

    it 'returns true when token is valid' do
      result = described_class.new(user, { state: logout_state }).execute
      expect(result[:status]).to eq(:success)
    end
  end
end
