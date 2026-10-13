# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropEnabledFoundationalFlowCheckResults, feature_category: :duo_agent_platform do
  let(:connection) { described_class.new.connection }
  let(:table_name) { :enabled_foundational_flow_check_results }

  describe '#up' do
    it 'drops the table' do
      expect { migrate! }.to change { connection.table_exists?(table_name) }.from(true).to(false)
    end
  end

  describe '#down', :aggregate_failures do
    before do
      migrate!
      schema_migrate_down!
    end

    it 'recreates the table with its columns and indexes' do
      expect(connection.table_exists?(table_name)).to be(true)
      expect(connection.columns(table_name).map(&:name)).to contain_exactly(
        'id', 'organization_id', 'enabled_foundational_flow_id', 'check_id', 'status', 'message',
        'created_at', 'updated_at'
      )
      expect(connection.indexes(table_name).map(&:name)).to contain_exactly(
        'idx_enabled_foundational_flow_check_results_on_organization',
        'idx_enabled_foundational_flow_check_results_on_flow_and_check'
      )
    end
  end
end
