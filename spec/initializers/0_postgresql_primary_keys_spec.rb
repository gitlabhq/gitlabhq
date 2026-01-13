# frozen_string_literal: true

require 'spec_helper'
RSpec.describe 'PostgreSQL primary keys', feature_category: :database do
  let(:connection) { ApplicationRecord.connection }

  describe 'Rails version guard' do
    it 'raises error if Rails 8.1.0 or higher is detected' do
      allow(Rails).to receive(:gem_version).and_return(Gem::Version.new('8.1.0'))

      expect do
        load Rails.root.join('config/initializers/0_postgresql_primary_keys.rb')
      end.to raise_error(RuntimeError, /PostgreSQLAdapterCustomPrimaryKeys patch is no longer needed/)
    end

    it 'does not raise error for versions less than Rails 8.1.0' do
      allow(Rails).to receive(:gem_version).and_return(Gem::Version.new('7.2.0'))

      expect do
        load Rails.root.join('config/initializers/0_postgresql_primary_keys.rb')
      end.not_to raise_error
    end
  end

  describe '#primary_keys' do
    context 'with single column primary key' do
      let(:table_name) { :_test_single_pk }

      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name} (
            id bigserial PRIMARY KEY,
            name text
          )
        SQL
      end

      after do
        connection.execute("DROP TABLE IF EXISTS #{table_name}")
      end

      it 'returns the primary key column name' do
        expect(connection.primary_keys(table_name)).to eq(['id'])
      end
    end

    context 'with composite primary key' do
      let(:table_name) { :_test_composite_pk }

      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name} (
            organization_id bigint NOT NULL,
            resource_id bigint NOT NULL,
            name text,
            PRIMARY KEY (organization_id, resource_id)
          )
        SQL
      end

      after do
        connection.execute("DROP TABLE IF EXISTS #{table_name}")
      end

      it 'returns all primary key columns in correct order' do
        expect(connection.primary_keys(table_name))
          .to eq(%w[organization_id resource_id])
      end

      it 'preserves the order defined in PRIMARY KEY constraint' do
        primary_keys = connection.primary_keys(table_name)

        expect(primary_keys.first).to eq('organization_id')
        expect(primary_keys.second).to eq('resource_id')
      end
    end

    context 'with reversed composite primary key order' do
      let(:table_name) { :_test_reversed_pk }

      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name} (
            organization_id bigint NOT NULL,
            resource_id bigint NOT NULL,
            PRIMARY KEY (resource_id, organization_id)
          )
        SQL
      end

      after do
        connection.execute("DROP TABLE IF EXISTS #{table_name}")
      end

      it 'returns columns in PRIMARY KEY definition order' do
        expect(connection.primary_keys(table_name))
          .to eq(%w[resource_id organization_id])
      end
    end
  end
end
