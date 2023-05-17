# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetEmailConfirmationSettingFromSoftEmailConfirmationFf, feature_category: :feature_flags do
  let(:migration) { described_class.new }
  let(:application_settings_table) { table(:application_settings) }
  let(:feature_gates_table) { table(:feature_gates) }

  describe '#up' do
    context 'when feature gate for `soft_email_confirmation` does not exist' do
      it 'does not update `email_confirmation_setting`' do
        application_settings_table.create!(email_confirmation_setting: 0)

        migration.up

        expect(application_settings_table.last.email_confirmation_setting).to eq 0
      end
    end

    context 'when feature gate for `soft_email_confirmation` does exist' do
      context 'when feature gate value is `false`' do
        before do
          feature_gates_table.create!(feature_key: 'soft_email_confirmation', key: 'boolean', value: 'false')
        end

        it 'does not update `email_confirmation_setting`' do
          application_settings_table.create!(email_confirmation_setting: 0)

          migration.up

          expect(application_settings_table.last.email_confirmation_setting).to eq 0
        end
      end

      context 'when feature gate value is `true`' do
        before do
          feature_gates_table.create!(feature_key: 'soft_email_confirmation', key: 'boolean', value: 'true')
        end

        it "updates `email_confirmation_setting` to '1' (soft)" do
          application_settings_table.create!(email_confirmation_setting: 0)

          migration.up

          expect(application_settings_table.last.email_confirmation_setting).to eq 1
        end
      end
    end
  end

  describe '#down' do
    it "updates 'email_confirmation_setting' to default value: '0' (off)" do
      application_settings_table.create!(email_confirmation_setting: 1)

      migration.down

      expect(application_settings_table.last.email_confirmation_setting).to eq 0
    end
  end
end
