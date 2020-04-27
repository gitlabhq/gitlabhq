# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200427064130_cleanup_optimistic_locking_nulls_pt2_fixed.rb')

describe CleanupOptimisticLockingNullsPt2Fixed, :migration do
  TABLES = %w(ci_stages ci_builds ci_pipelines).freeze
  TABLES.each do |table|
    let(table.to_sym) { table(table.to_sym) }
  end
  let(:tables) { TABLES.map { |t| method(t.to_sym).call } }

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
