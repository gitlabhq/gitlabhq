# frozen_string_literal: true

require 'rails_helper'

describe Gitlab::BackgroundMigration::PopulateMergeRequestAssigneesTable, :migration, schema: 20190315191339 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }

  let(:user) { users.create!(email: 'test@example.com', projects_limit: 100, username: 'test') }
  let(:user_2) { users.create!(email: 'test2@example.com', projects_limit: 100, username: 'test') }
  let(:user_3) { users.create!(email: 'test3@example.com', projects_limit: 100, username: 'test') }

  let(:namespace) { namespaces.create(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create(namespace_id: namespace.id, name: 'foo') }
  let(:merge_requests) { table(:merge_requests) }
  let(:merge_request_assignees) { table(:merge_request_assignees) }

  def create_merge_request(id, params = {})
    params.merge!(id: id,
                  target_project_id: project.id,
                  target_branch: 'master',
                  source_project_id: project.id,
                  source_branch: 'mr name',
                  title: "mr name#{id}")

    merge_requests.create(params)
  end

  before do
    create_merge_request(2, assignee_id: user.id)
    create_merge_request(3, assignee_id: user_2.id)
    create_merge_request(4, assignee_id: user_3.id)

    # Test filtering MRs without assignees
    create_merge_request(5, assignee_id: nil)
    # Test filtering already migrated row
    merge_request_assignees.create!(merge_request_id: 2, user_id: user_3.id)
  end

  describe '#perform' do
    it 'creates merge_request_assignees rows according to merge_requests' do
      subject.perform(1, 4)

      rows = merge_request_assignees.order(:id).map { |row| row.attributes.slice('merge_request_id', 'user_id') }
      existing_rows = [
        { 'merge_request_id' => 2, 'user_id' => user_3.id }
      ]
      created_rows = [
        { 'merge_request_id' => 3, 'user_id' => user_2.id },
        { 'merge_request_id' => 4, 'user_id' => user_3.id }
      ]
      expected_rows = existing_rows + created_rows

      expect(rows.size).to eq(expected_rows.size)
      expected_rows.each do |expected_row|
        expect(rows).to include(expected_row)
      end
    end
  end

  describe '#perform_all_sync' do
    it 'executes peform for all merge requests in batches' do
      expect(subject).to receive(:perform).with(2, 4).ordered
      expect(subject).to receive(:perform).with(5, 5).ordered

      subject.perform_all_sync(batch_size: 3)
    end
  end
end
