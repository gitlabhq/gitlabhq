# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateActiveBillableUsersIndex, feature_category: :database do
  let(:db) { described_class.new }
  let(:table_name) { described_class::TABLE_NAME }
  let(:old_index_name) { described_class::OLD_INDEX_NAME }
  let(:new_index_name) { described_class::NEW_INDEX_NAME }
  let(:old_filter_condition) { "(user_type <> ALL ('{2,6,1,3,7,8}'::smallint[])))" }
  let(:new_filter_condition) { "(user_type <> ALL ('{1,2,3,4,5,6,7,8,9,11}'::smallint[])))" }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(subject.index_exists_by_name?(table_name, new_index_name)).to be_falsy
        expect(subject.index_exists_by_name?(table_name, old_index_name)).to be_truthy
        expect(db.connection.indexes(table_name).find do |i|
                 i.name == old_index_name
               end.where).to include(old_filter_condition)
      }

      migration.after -> {
        expect(subject.index_exists_by_name?(table_name, old_index_name)).to be_falsy
        expect(subject.index_exists_by_name?(table_name, new_index_name)).to be_truthy
        expect(db.connection.indexes(table_name).find do |i|
                 i.name == new_index_name
               end.where).to include(new_filter_condition)
      }
    end
  end
end
