# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddPasswordExpirationMigration, feature_category: :user_profile do
  let(:application_setting) { table(:application_settings).create! }

  describe "#up" do
    it 'allows to read password expiration fields' do
      migrate!

      expect(application_setting.password_expiration_enabled).to eq false
      expect(application_setting.password_expires_in_days).to eq 90
      expect(application_setting.password_expires_notice_before_days).to eq 7
    end
  end
end
