# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiSecureFileStatesProjectId,
  feature_category: :secrets_management,
  schema: 20240930125308,
  migration: :gitlab_ci do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ci_secure_file_states }
    let(:batch_column) { :ci_secure_file_id }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :ci_secure_files }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :ci_secure_file_id }
  end
end
