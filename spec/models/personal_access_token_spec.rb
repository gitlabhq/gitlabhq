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

  describe ".active?" do
    let(:active_personal_access_token) { build(:personal_access_token) }
    let(:revoked_personal_access_token) { build(:revoked_personal_access_token) }
    let(:expired_personal_access_token) { build(:expired_personal_access_token) }

    it "returns false if the personal_access_token is revoked" do
      expect(revoked_personal_access_token).not_to be_active
    end

    it "returns false if the personal_access_token is expired" do
      expect(expired_personal_access_token).not_to be_active
    end

    it "returns true if the personal_access_token is not revoked and not expired" do
      expect(active_personal_access_token).to be_active
    end
  end
end
