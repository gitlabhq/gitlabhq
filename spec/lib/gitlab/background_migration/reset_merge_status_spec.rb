# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::ResetMergeStatus, :migration, schema: 20190528180441 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:namespace) { namespaces.create(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create(namespace_id: namespace.id, name: 'foo') }
  let(:merge_requests) { table(:merge_requests) }

  def create_merge_request(id, extra_params = {})
    params = {
      id: id,
      target_project_id: project.id,
      target_branch: 'master',
      source_project_id: project.id,
      source_branch: 'mr name',
      title: "mr name#{id}"
    }.merge(extra_params)

    merge_requests.create!(params)
  end

  it 'correctly updates opened mergeable MRs to unchecked' do
    create_merge_request(1, state: 'opened', merge_status: 'can_be_merged')
    create_merge_request(2, state: 'opened', merge_status: 'can_be_merged')
    create_merge_request(3, state: 'opened', merge_status: 'can_be_merged')
    create_merge_request(4, state: 'merged', merge_status: 'can_be_merged')
    create_merge_request(5, state: 'opened', merge_status: 'cannot_be_merged')

    subject.perform(1, 5)

    expected_rows = [
      { id: 1, state: 'opened', merge_status: 'unchecked' },
      { id: 2, state: 'opened', merge_status: 'unchecked' },
      { id: 3, state: 'opened', merge_status: 'unchecked' },
      { id: 4, state: 'merged', merge_status: 'can_be_merged' },
      { id: 5, state: 'opened', merge_status: 'cannot_be_merged' }
    ]

    rows = merge_requests.order(:id).map do |row|
      row.attributes.slice('id', 'state', 'merge_status').symbolize_keys
    end

    expect(rows).to eq(expected_rows)
  end
end
