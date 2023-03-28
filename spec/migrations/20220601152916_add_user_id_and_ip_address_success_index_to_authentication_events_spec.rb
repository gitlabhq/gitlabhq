# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddUserIdAndIpAddressSuccessIndexToAuthenticationEvents,
  feature_category: :system_access do
  let(:db) { described_class.new }
  let(:old_index) { described_class::OLD_INDEX_NAME }
  let(:new_index) { described_class::NEW_INDEX_NAME }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(db.connection.indexes(:authentication_events).map(&:name)).to include(old_index)
        expect(db.connection.indexes(:authentication_events).map(&:name)).not_to include(new_index)
      }

      migration.after -> {
        expect(db.connection.indexes(:authentication_events).map(&:name)).to include(new_index)
        expect(db.connection.indexes(:authentication_events).map(&:name)).not_to include(old_index)
      }
    end
  end
end
