# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProtectedTagCreateAccessLevelsProjectId,
  feature_category: :source_code_management,
  schema: 20240618122507 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :protected_tag_create_access_levels }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :protected_tags }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :protected_tag_id }
  end
end
