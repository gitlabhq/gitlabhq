# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RevalidateWebHookLogsDailyShardingKeyConstraint, migration: :gitlab_main_org, feature_category: :webhooks do
  let(:connection) { ApplicationRecord.connection }
  let(:constraint_name) { described_class::CONSTRAINT_NAME }

  before do
    # Reset the constraint to NOT VALID so the migration has something to validate.
    connection.execute(<<~SQL)
      ALTER TABLE web_hook_logs_daily DROP CONSTRAINT IF EXISTS #{constraint_name};
      ALTER TABLE web_hook_logs_daily
        ADD CONSTRAINT #{constraint_name}
        CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;
    SQL
  end

  it 'validates the sharding-key constraint' do
    expect { migrate! }.to change { constraint_validated? }.from(false).to(true)
  end

  def constraint_validated?
    connection.select_value(<<~SQL)
      SELECT convalidated FROM pg_constraint WHERE conname = '#{constraint_name}'
    SQL
  end
end
