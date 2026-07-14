# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveNamespacesPushRuleIdColumn, feature_category: :source_code_management do
  let(:connection) { described_class.new.connection }

  describe '#up' do
    it 'removes the push_rule_id column' do
      expect { migrate! }.to change {
        connection.column_exists?(:namespaces, :push_rule_id)
      }.from(true).to(false)
    end
  end

  describe '#down' do
    it 'restores the push_rule_id column as bigint', :aggregate_failures do
      migrate!
      schema_migrate_down!

      column = connection.columns(:namespaces).find { |c| c.name == 'push_rule_id' }

      expect(column).to be_present
      expect(column.sql_type).to eq('bigint')
    end
  end
end
