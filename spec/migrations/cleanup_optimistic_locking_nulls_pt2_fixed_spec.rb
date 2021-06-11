# frozen_string_literal: true

require 'spec_helper'
require_migration!('cleanup_optimistic_locking_nulls_pt2_fixed')

RSpec.describe CleanupOptimisticLockingNullsPt2Fixed, :migration, schema: 20200219193117 do
  test_tables = %w(ci_stages ci_builds ci_pipelines).freeze
  test_tables.each do |table|
    let(table.to_sym) { table(table.to_sym) }
  end
  let(:tables) { test_tables.map { |t| method(t.to_sym).call } }

  before do
    # Create necessary rows
    ci_stages.create!
    ci_builds.create!
    ci_pipelines.create!

    # Nullify `lock_version` column for all rows
    # Needs to be done with a SQL fragment, otherwise Rails will coerce it to 0
    tables.each do |table|
      table.update_all('lock_version = NULL')
    end
  end

  it 'correctly migrates nullified lock_version column', :sidekiq_might_not_need_inline do
    tables.each do |table|
      expect(table.where(lock_version: nil).count).to eq(1)
    end

    tables.each do |table|
      expect(table.where(lock_version: 0).count).to eq(0)
    end

    migrate!

    tables.each do |table|
      expect(table.where(lock_version: nil).count).to eq(0)
    end

    tables.each do |table|
      expect(table.where(lock_version: 0).count).to eq(1)
    end
  end
end
