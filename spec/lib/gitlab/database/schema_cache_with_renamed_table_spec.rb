# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaCacheWithRenamedTable do
  let(:old_model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'projects'
    end
  end

  let(:new_model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = '_test_projects_new'
    end
  end

  before do
    stub_const('Gitlab::Database::TABLES_TO_BE_RENAMED', { 'projects' => '_test_projects_new' })
  end

  context 'when table is not renamed yet' do
    before do
      old_model.reset_column_information
      ActiveRecord::Base.connection.schema_cache.clear!
    end

    it 'uses the original table to look up metadata' do
      expect(old_model.primary_key).to eq('id')
    end
  end

  context 'when table is renamed' do
    before do
      ActiveRecord::Base.connection.execute("ALTER TABLE projects RENAME TO _test_projects_new")
      ActiveRecord::Base.connection.execute("CREATE VIEW projects AS SELECT * FROM _test_projects_new")

      old_model.reset_column_information
      ActiveRecord::Base.connection.schema_cache.clear!
    end

    it 'uses the renamed table to look up metadata' do
      expect(old_model.primary_key).to eq('id')
    end

    it 'has primary key' do
      expect(old_model.primary_key).to eq('id')
      expect(old_model.primary_key).to eq(new_model.primary_key)
    end

    it 'has the same column definitions' do
      expect(old_model.columns).to eq(new_model.columns)
    end

    it 'has the same indexes' do
      indexes_for_old_table = ActiveRecord::Base.connection.schema_cache.indexes('projects')
      indexes_for_new_table = ActiveRecord::Base.connection.schema_cache.indexes('_test_projects_new')

      expect(indexes_for_old_table).to eq(indexes_for_new_table)
    end

    it 'has the same column_hash' do
      columns_hash_for_old_table = ActiveRecord::Base.connection.schema_cache.columns_hash('projects')
      columns_hash_for_new_table = ActiveRecord::Base.connection.schema_cache.columns_hash('_test_projects_new')

      expect(columns_hash_for_old_table).to eq(columns_hash_for_new_table)
    end

    describe 'when the table behind a model is actually a view' do
      let(:organization) { create(:organization) }
      let(:group) { create(:group) }
      let(:attrs) do
        attributes_for(
          :project,
          namespace_id: group.id,
          project_namespace_id: group.id,
          organization_id: organization.id
        ).except(:creator)
      end

      let(:record) { old_model.create!(attrs) }

      it 'can persist records' do
        expect(record.reload.attributes).to eq(new_model.find(record.id).attributes)
      end

      it 'can find records' do
        expect(old_model.find_by_id(record.id)).not_to be_nil
      end
    end
  end
end
