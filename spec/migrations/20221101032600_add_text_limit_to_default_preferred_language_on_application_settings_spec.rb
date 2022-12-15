# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddTextLimitToDefaultPreferredLanguageOnApplicationSettings, feature_category: :internationalization do
  let(:application_setting) { table(:application_settings).create! }
  let(:too_long_text) { SecureRandom.alphanumeric(described_class::MAXIMUM_LIMIT + 1) }

  subject { application_setting.update_column(:default_preferred_language, too_long_text) }

  describe "#up" do
    it 'adds text limit to default_preferred_language' do
      migrate!

      expect { subject }.to raise_error ActiveRecord::StatementInvalid
    end
  end

  describe "#down" do
    it 'deletes text limit to default_preferred_language' do
      migrate!
      schema_migrate_down!

      expect { subject }.not_to raise_error
    end
  end
end
