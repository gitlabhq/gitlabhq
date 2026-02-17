# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillDisplayGitlabCreditsUserDataForApplicationSetting, feature_category: :consumables_cost_management do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    context 'when application_settings has empty usage_billing' do
      before do
        application_settings.create!(usage_billing: {})
      end

      it 'sets display_gitlab_credits_user_data to true' do
        migrate!

        expect(application_settings.first.usage_billing).to eq(
          { 'display_gitlab_credits_user_data' => true }
        )
      end
    end

    context 'when application_settings has display_gitlab_credits_user_data set to false' do
      before do
        application_settings.create!(usage_billing: { 'display_gitlab_credits_user_data' => false })
      end

      it 'updates display_gitlab_credits_user_data to true' do
        migrate!

        expect(application_settings.first.usage_billing).to eq(
          { 'display_gitlab_credits_user_data' => true }
        )
      end
    end

    context 'when application_settings has other keys in usage_billing' do
      before do
        application_settings.create!(usage_billing: { 'other_key' => 'value' })
      end

      it 'preserves other keys and adds display_gitlab_credits_user_data' do
        migrate!

        expect(application_settings.first.usage_billing).to eq(
          { 'other_key' => 'value', 'display_gitlab_credits_user_data' => true }
        )
      end
    end
  end

  describe '#down' do
    before do
      application_settings.create!(usage_billing: { 'display_gitlab_credits_user_data' => true })
    end

    it 'sets display_gitlab_credits_user_data back to false' do
      migrate!

      schema_migrate_down!

      expect(application_settings.first.usage_billing).to eq(
        { 'display_gitlab_credits_user_data' => false }
      )
    end
  end
end
