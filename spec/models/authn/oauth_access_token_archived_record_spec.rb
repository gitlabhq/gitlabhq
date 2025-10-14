# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::OauthAccessTokenArchivedRecord, feature_category: :system_access do
  describe 'factory validity' do
    it 'creates a valid archived record' do
      record = build(:oauth_access_token_archived_record)
      expect(record).to be_valid
    end
  end
end
