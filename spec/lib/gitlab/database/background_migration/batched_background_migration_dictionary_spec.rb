# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Database::BackgroundMigration::BatchedBackgroundMigrationDictionary, feature_category: :database do
  describe '.entry' do
    it 'returns a single dictionary entry for the given migration job' do
      entry = described_class.entry('MigrateHumanUserType')
      expect(entry.migration_job_name).to eq('MigrateHumanUserType')
      expect(entry.finalized_by).to eq(20230523101514)
    end
  end
end
