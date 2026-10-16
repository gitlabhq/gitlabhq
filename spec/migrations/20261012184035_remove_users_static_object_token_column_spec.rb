# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveUsersStaticObjectTokenColumn, feature_category: :source_code_management do
  let(:connection) { described_class.new.connection }
  let(:column_name) { described_class::COLUMN_NAME }

  describe '#up' do
    it 'removes the column' do
      expect { migrate! }.to change {
        connection.column_exists?(:users, column_name)
      }.from(true).to(false)
    end
  end

  describe '#down' do
    it 'restores the column', :aggregate_failures do
      migrate!
      schema_migrate_down!

      column = connection.columns(:users).find { |c| c.name == column_name.to_s }

      expect(column).to be_present
      expect(column.sql_type).to eq('character varying(255)')
    end
  end
end
