# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesignManagementRepositoriesNamespaceId,
  feature_category: :design_management,
  schema: 20240515155719 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :design_management_repositories }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :projects }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :project_id }
  end
end
