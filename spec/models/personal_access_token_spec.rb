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
end
