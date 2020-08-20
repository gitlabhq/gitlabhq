# frozen_string_literal: true

require 'spec_helper'

# The test setup must begin before
# 20200804041930_add_not_null_constraint_on_external_diff_store_to_merge_request_diffs.rb
# has run, or else we cannot insert a row with `NULL` `external_diff_store` to
# test against.
RSpec.describe Gitlab::BackgroundMigration::SetNullExternalDiffStoreToLocalValue, schema: 20200804035230 do
  let!(:merge_request_diffs) { table(:merge_request_diffs) }
  let!(:merge_requests)      { table(:merge_requests) }
  let!(:namespaces)          { table(:namespaces) }
  let!(:projects)            { table(:projects) }
  let!(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:merge_request) { merge_requests.create!(source_branch: 'x', target_branch: 'master', target_project_id: project.id) }

  it 'correctly migrates nil external_diff_store to 1' do
    external_diff_store_1 = merge_request_diffs.create!(external_diff_store: 1, merge_request_id: merge_request.id)
    external_diff_store_2 = merge_request_diffs.create!(external_diff_store: 2, merge_request_id: merge_request.id)
    external_diff_store_nil = merge_request_diffs.create!(external_diff_store: nil, merge_request_id: merge_request.id)

    described_class.new.perform(external_diff_store_1.id, external_diff_store_nil.id)

    external_diff_store_1.reload
    external_diff_store_2.reload
    external_diff_store_nil.reload

    expect(external_diff_store_1.external_diff_store).to eq(1)   # unchanged
    expect(external_diff_store_2.external_diff_store).to eq(2)   # unchanged
    expect(external_diff_store_nil.external_diff_store).to eq(1) # nil => 1
  end
end
