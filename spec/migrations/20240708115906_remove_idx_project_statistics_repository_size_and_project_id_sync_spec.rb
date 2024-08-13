# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveIdxProjectStatisticsRepositorySizeAndProjectIdSync,
  feature_category: :consumables_cost_management,
  schema: 20240708115906 do
  let(:migration) { described_class.new }

  describe '#up' do
    it 'does nothing when not on gitlab.com' do
      expect(migration).not_to receive(:remove_concurrent_index_by_name)

      migration.up
    end

    it 'removes the index when on gitlab.com', :saas do
      expect(migration).to receive(:remove_concurrent_index_by_name)

      migration.up
    end
  end

  describe '#down' do
    it 'does nothing when not on gitlab.com' do
      expect(migration).not_to receive(:add_concurrent_index)

      migration.down
    end

    it 're-adds the index when on gitlab.com', :saas do
      expect(migration).to receive(:add_concurrent_index)

      migration.down
    end
  end
end
