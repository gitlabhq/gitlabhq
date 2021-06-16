# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureFilledExternalDiffStoreOnMergeRequestDiffs, schema: 20200908095446 do
  let!(:merge_request_diffs) { table(:merge_request_diffs) }
  let!(:merge_requests) { table(:merge_requests) }
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:merge_request) { merge_requests.create!(source_branch: 'x', target_branch: 'master', target_project_id: project.id) }

  before do
    constraint_name = 'check_93ee616ac9'

    # In order to insert a row with a NULL to fill.
    ActiveRecord::Base.connection.execute "ALTER TABLE merge_request_diffs DROP CONSTRAINT #{constraint_name}"

    @external_diff_store_1 = merge_request_diffs.create!(external_diff_store: 1, merge_request_id: merge_request.id)
    @external_diff_store_2 = merge_request_diffs.create!(external_diff_store: 2, merge_request_id: merge_request.id)
    @external_diff_store_nil = merge_request_diffs.create!(external_diff_store: nil, merge_request_id: merge_request.id)

    # revert DB structure
    ActiveRecord::Base.connection.execute "ALTER TABLE merge_request_diffs ADD CONSTRAINT #{constraint_name} CHECK ((external_diff_store IS NOT NULL)) NOT VALID"
  end

  it 'correctly migrates nil external_diff_store to 1' do
    migrate!

    @external_diff_store_1.reload
    @external_diff_store_2.reload
    @external_diff_store_nil.reload

    expect(@external_diff_store_1.external_diff_store).to eq(1)   # unchanged
    expect(@external_diff_store_2.external_diff_store).to eq(2)   # unchanged
    expect(@external_diff_store_nil.external_diff_store).to eq(1) # nil => 1
  end
end
