# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddExpiryNotifiedAtToMember, feature_category: :system_access do
  let(:members) { table(:members) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(members.column_names).not_to include('expiry_notified_at')
      }

      migration.after -> {
        members.reset_column_information
        expect(members.column_names).to include('expiry_notified_at')
      }
    end
  end
end
