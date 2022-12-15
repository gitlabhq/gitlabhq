# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateIndexOnAlertsToExcludeNullFingerprints, feature_category: :incident_management do
  let(:alerts) { 'alert_management_alerts' }
  let(:old_index) { described_class::OLD_INDEX_NAME }
  let(:new_index) { described_class::NEW_INDEX_NAME }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(subject.index_exists_by_name?(alerts, old_index)).to be_truthy
        expect(subject.index_exists_by_name?(alerts, new_index)).to be_falsey
      }

      migration.after -> {
        expect(subject.index_exists_by_name?(alerts, old_index)).to be_falsey
        expect(subject.index_exists_by_name?(alerts, new_index)).to be_truthy
      }
    end
  end
end
