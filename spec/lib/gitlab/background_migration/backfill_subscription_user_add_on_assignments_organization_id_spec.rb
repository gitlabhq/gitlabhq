# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSubscriptionUserAddOnAssignmentsOrganizationId,
  feature_category: :seat_cost_management,
  schema: 20240826120425 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :subscription_user_add_on_assignments }
    let(:backfill_column) { :organization_id }
    let(:backfill_via_table) { :subscription_add_on_purchases }
    let(:backfill_via_column) { :organization_id }
    let(:backfill_via_foreign_key) { :add_on_purchase_id }
  end
end
