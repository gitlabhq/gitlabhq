# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetEmailConfirmationSettingBeforeRemovingSendUserConfirmationEmailColumn,
  feature_category: :user_profile do
  let(:migration) { described_class.new }
  let(:application_settings_table) { table(:application_settings) }

  describe '#up' do
    context "when 'send_user_confirmation_email' is set to 'true'" do
      it "updates 'email_confirmation_setting' to '2' (hard)" do
        application_settings_table.create!(send_user_confirmation_email: true, email_confirmation_setting: 0)

        migration.up

        expect(application_settings_table.last.email_confirmation_setting).to eq 2
      end
    end

    context "when 'send_user_confirmation_email' is set to 'false'" do
      it "updates 'email_confirmation_setting' to '0' (off)" do
        application_settings_table.create!(send_user_confirmation_email: false, email_confirmation_setting: 0)

        migration.up

        expect(application_settings_table.last.email_confirmation_setting).to eq 0
      end
    end
  end

  describe '#down' do
    it "updates 'email_confirmation_setting' to default value: '0' (off)" do
      application_settings_table.create!(send_user_confirmation_email: true, email_confirmation_setting: 2)

      migration.down

      expect(application_settings_table.last.email_confirmation_setting).to eq 0
    end
  end
end
