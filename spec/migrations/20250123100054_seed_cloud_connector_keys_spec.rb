# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SeedCloudConnectorKeys, migration: :gitlab_main, feature_category: :cloud_connector do
  it 'seeds Cloud Connector keys' do
    settings = table(:application_settings).create!

    reversible_migration do |migration|
      migration.before -> {
        expect(settings.reload.cloud_connector_keys).to be_nil
      }

      migration.after -> {
        # Should contain encryption data as a hash
        expect(settings.reload.cloud_connector_keys).to include("h" => instance_of(Hash))
      }
    end
  end
end
