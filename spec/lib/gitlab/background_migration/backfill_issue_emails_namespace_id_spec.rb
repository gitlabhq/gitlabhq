# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIssueEmailsNamespaceId,
  feature_category: :service_desk,
  schema: 20241203080305 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :issue_emails }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :issue_id }
  end
end
