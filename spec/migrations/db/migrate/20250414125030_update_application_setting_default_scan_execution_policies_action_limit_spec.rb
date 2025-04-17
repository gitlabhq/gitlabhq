# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateApplicationSettingDefaultScanExecutionPoliciesActionLimit, '#up',
  feature_category: :security_policy_management,
  migration: :gitlab_main do
  let(:connection) { ApplicationRecord.connection }

  context 'without application setting' do
    specify do
      expect { migrate! }.not_to raise_error
    end
  end

  context 'with application setting' do
    before do
      connection.execute('DELETE FROM application_settings')
    end

    shared_examples 'resets' do |expected|
      it 'updates `scan_execution_policies_action_limit`' do
        migrate!

        all = connection.select_all <<~SQL
          SELECT
            security_policies ->> 'foo' AS foo,
            security_policies ->> 'scan_execution_policies_action_limit' AS action_limit
          FROM
            application_settings;
        SQL

        expect(all).to contain_exactly(expected)
      end

      it 'stores a number/numeric' do
        migrate!

        all = connection.select_all <<~SQL
          SELECT jsonb_typeof(
            jsonb_path_query_first(
              security_policies,
              '$.scan_execution_policies_action_limit'
            )
          ) AS type
          FROM application_settings;
        SQL

        expect(all).to contain_exactly('type' => 'number')
      end
    end

    context 'with empty setting hash' do
      before do
        connection.execute <<~SQL
          INSERT INTO application_settings (security_policies)
          VALUES ('{}')
        SQL
      end

      it_behaves_like 'resets', 'action_limit' => '0', 'foo' => nil
    end

    context 'without existing setting value' do
      before do
        connection.execute <<~SQL
          INSERT INTO application_settings (security_policies)
          VALUES ('{"foo": "bar"}')
        SQL
      end

      it_behaves_like 'resets', 'action_limit' => '0', 'foo' => 'bar'
    end

    context 'with existing setting value' do
      before do
        connection.execute <<~SQL
          INSERT INTO application_settings (security_policies)
          VALUES ('{"foo": "bar", "scan_execution_policies_action_limit": "31"}')
        SQL
      end

      it_behaves_like 'resets', 'action_limit' => '0', 'foo' => 'bar'
    end
  end
end
