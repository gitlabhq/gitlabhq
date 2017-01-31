require 'spec_helper'

describe PersonalAccessToken, models: true do
  describe ".generate" do
    it "generates a random token" do
      personal_access_token = PersonalAccessToken.generate({})
      expect(personal_access_token.token).to be_present
    end

    it "doesn't save the record" do
      personal_access_token = PersonalAccessToken.generate({})
      expect(personal_access_token).not_to be_persisted
    end
  end

  describe 'validate_scopes' do
    it "allows creating a token with API scopes" do
      personal_access_token = build(:personal_access_token)
      personal_access_token.scopes = [:api, :read_user]

      expect(personal_access_token).to be_valid
    end

    it "rejects creating a token with non-API scopes" do
      personal_access_token = build(:personal_access_token)
      personal_access_token.scopes = [:openid, :api]

      expect(personal_access_token).not_to be_valid
    end
  end
end
