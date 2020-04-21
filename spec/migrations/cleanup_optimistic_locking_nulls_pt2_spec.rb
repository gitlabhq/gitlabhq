# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200217210353_cleanup_optimistic_locking_nulls_pt2')

describe CleanupOptimisticLockingNullsPt2, :migration do
  let(:ci_stages) { table(:ci_stages) }
  let(:ci_builds) { table(:ci_builds) }
  let(:ci_pipelines) { table(:ci_pipelines) }
  let(:tables) { [ci_stages, ci_builds, ci_pipelines] }

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
