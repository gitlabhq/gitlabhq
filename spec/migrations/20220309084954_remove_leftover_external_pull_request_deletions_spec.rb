# frozen_string_literal: true
require 'spec_helper'

require_migration!

RSpec.describe RemoveLeftoverExternalPullRequestDeletions, feature_category: :cell do
  let(:deleted_records) { table(:loose_foreign_keys_deleted_records) }

  let(:pending_record1) { deleted_records.create!(id: 1, fully_qualified_table_name: 'public.external_pull_requests', primary_key_value: 1, status: 1) }
  let(:pending_record2) { deleted_records.create!(id: 2, fully_qualified_table_name: 'public.external_pull_requests', primary_key_value: 2, status: 1) }
  let(:other_pending_record1) { deleted_records.create!(id: 3, fully_qualified_table_name: 'public.projects', primary_key_value: 1, status: 1) }
  let(:other_pending_record2) { deleted_records.create!(id: 4, fully_qualified_table_name: 'public.ci_builds', primary_key_value: 1, status: 1) }
  let(:processed_record1) { deleted_records.create!(id: 5, fully_qualified_table_name: 'public.external_pull_requests', primary_key_value: 3, status: 2) }
  let(:other_processed_record1) { deleted_records.create!(id: 6, fully_qualified_table_name: 'public.ci_builds', primary_key_value: 2, status: 2) }

  let!(:persisted_ids_before) do
    [
      pending_record1,
      pending_record2,
      other_pending_record1,
      other_pending_record2,
      processed_record1,
      other_processed_record1
    ].map(&:id).sort
  end

  let!(:persisted_ids_after) do
    [
      other_pending_record1,
      other_pending_record2,
      processed_record1,
      other_processed_record1
    ].map(&:id).sort
  end

  def all_ids
    deleted_records.all.map(&:id).sort
  end

  it 'deletes pending external_pull_requests records' do
    expect { migrate! }.to change { all_ids }.from(persisted_ids_before).to(persisted_ids_after)
  end
end
