# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateOrganizationIsolations, migration: :gitlab_main, feature_category: :organization do
  let(:migration) { described_class.new }
  let(:organization_isolations) { table(:organization_isolations) }

  describe '#up' do
    it 'creates the organization_isolations table' do
      migrate!

      expect(organization_isolations.table_exists?).to be true
    end

    it 'creates the table with the correct columns' do
      migrate!

      expect(organization_isolations.column_names).to include(
        'id', 'organization_id', 'isolated', 'created_at', 'updated_at'
      )
    end

    it 'sets the correct column types and constraints' do
      migrate!

      organization_id_column = organization_isolations.columns.find { |c| c.name == 'organization_id' }
      isolated_column = organization_isolations.columns.find { |c| c.name == 'isolated' }

      expect(organization_id_column.type).to eq(:integer)
      expect(organization_id_column.null).to be false

      expect(isolated_column.type).to eq(:boolean)
      expect(isolated_column.null).to be false
      expect(isolated_column.default).to eq "false"
    end

    it 'creates the unique index on organization_id' do
      migrate!

      indexes = ActiveRecord::Base.connection.indexes(:organization_isolations)
      organization_id_index = indexes.find { |i| i.columns == ['organization_id'] }

      expect(organization_id_index).to be_present
      expect(organization_id_index.unique).to be true
    end

    it 'creates the foreign key constraint on organization_id' do
      migrate!

      foreign_keys = ActiveRecord::Base.connection.foreign_keys(:organization_isolations)
      organization_fk = foreign_keys.find { |fk| fk.column == 'organization_id' }

      expect(organization_fk).to be_present
      expect(organization_fk.to_table).to eq('organizations')
      expect(organization_fk.on_delete).to eq(:cascade)
    end
  end

  describe '#down' do
    it 'drops the organization_isolations table' do
      migrate!
      schema_migrate_down!

      expect(organization_isolations.table_exists?).to be false
    end
  end
end
