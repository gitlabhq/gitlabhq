# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveProjectStatisticsPackagesSizeAndProjectIdIndex, feature_category: :consumables_cost_management do
  let(:migration) { described_class.new }
  let(:postgres_async_indexes) { table(:postgres_async_indexes) }

  describe '#up' do
    subject(:up) { migration.up }

    it 'does nothing when not on gitlab.com' do
      expect { up }.not_to change { postgres_async_indexes.count }
    end

    it 'prepares async index removal when on gitlab.com', :saas do
      expect { up }.to change { postgres_async_indexes.count }.from(0).to(1)
    end
  end

  describe '#down' do
    subject(:down) { migration.down }

    before do
      postgres_async_indexes.create!(
        name: 'index_project_statistics_on_packages_size_and_project_id',
        table_name: 'project_statistics',
        definition: 'test index'
      )
    end

    it 'does nothing when not on gitlab.com' do
      expect { down }.not_to change { postgres_async_indexes.count }
    end

    it 'unprepares async index removal when on gitlab.com', :saas do
      expect { down }.to change { postgres_async_indexes.count }.from(1).to(0)
    end
  end
end
