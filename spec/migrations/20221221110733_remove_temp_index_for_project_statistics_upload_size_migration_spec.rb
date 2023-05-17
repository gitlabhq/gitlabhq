# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveTempIndexForProjectStatisticsUploadSizeMigration,
  feature_category: :consumables_cost_management do
  let(:table_name) { 'project_statistics' }
  let(:index_name) { described_class::INDEX_NAME }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(subject.index_exists_by_name?(table_name, index_name)).to be_truthy
      }

      migration.after -> {
        expect(subject.index_exists_by_name?(table_name, index_name)).to be_falsy
      }
    end
  end
end
