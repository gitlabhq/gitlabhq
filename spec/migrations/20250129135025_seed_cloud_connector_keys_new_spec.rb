# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SeedCloudConnectorKeysNew, migration: :gitlab_main, feature_category: :cloud_connector do
  it 'seeds Cloud Connector keys' do
    keys_table = table(:cloud_connector_keys)

    reversible_migration do |migration|
      migration.before -> {
        expect(keys_table.all).to be_empty
      }

      migration.after -> {
        # Should contain encryption data as a hash
        key_record = keys_table.first
        expect(key_record).not_to be_nil
        expect(key_record.secret_key).to include("h" => instance_of(Hash))
      }
    end
  end
end
