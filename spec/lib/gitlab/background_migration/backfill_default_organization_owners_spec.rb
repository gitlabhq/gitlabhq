# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDefaultOrganizationOwners, schema: 20240108182342, feature_category: :cell do
  subject(:migration) do
    described_class.new(
      start_id: 1,
      end_id: 2,
      batch_table: :users,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'runs without error for no-op' do
      migration.perform
    end
  end
end
