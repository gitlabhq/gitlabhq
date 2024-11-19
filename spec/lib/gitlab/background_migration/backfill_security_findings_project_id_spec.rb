# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSecurityFindingsProjectId,
  feature_category: :vulnerability_management,
  schema: 20241014114621,
  migration: :gitlab_sec do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :security_findings }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :vulnerability_scanners }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :scanner_id }
  end
end
