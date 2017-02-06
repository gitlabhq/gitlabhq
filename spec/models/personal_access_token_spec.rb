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

  context "validations" do
    let(:personal_access_token) { build(:personal_access_token) }

    it "requires at least one scope" do
      personal_access_token.scopes = []

      expect(personal_access_token).not_to be_valid
      expect(personal_access_token.errors[:scopes].first).to eq "can't be blank"
    end

    it "allows creating a token with API scopes" do
      personal_access_token.scopes = [:api, :read_user]

      expect(personal_access_token).to be_valid
    end

    it "rejects creating a token with non-API scopes" do
      personal_access_token.scopes = [:openid, :api]

      expect(personal_access_token).not_to be_valid
      expect(personal_access_token.errors[:scopes].first).to eq "can only contain API scopes"
    end
  end
end
