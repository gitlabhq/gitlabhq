# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddEntriesDigestToCdVersionSets, migration: :gitlab_main, feature_category: :continuous_delivery do
  describe '#up' do
    it 'adds the entries_digest column' do
      migrate!

      column = ActiveRecord::Base.connection.columns(:cd_version_sets).find { |c| c.name == 'entries_digest' }

      expect(column).to be_present
      expect(column.sql_type).to eq('text')
      expect(column.null).to be true
    end
  end

  describe '#down' do
    it 'removes the entries_digest column' do
      migrate!
      schema_migrate_down!

      column = ActiveRecord::Base.connection.columns(:cd_version_sets).find { |c| c.name == 'entries_digest' }

      expect(column).to be_nil
    end
  end
end
