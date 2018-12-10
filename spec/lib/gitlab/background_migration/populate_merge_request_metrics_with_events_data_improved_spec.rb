# frozen_string_literal: true

require 'rails_helper'

describe Gitlab::BackgroundMigration::PopulateMergeRequestMetricsWithEventsDataImproved, :migration, schema: 20181204154019 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:events) { table(:events) }

  let(:user) { users.create!(email: 'test@example.com', projects_limit: 100, username: 'test') }

  let(:namespace) { namespaces.create(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create(namespace_id: namespace.id, name: 'foo') }
  let(:merge_requests) { table(:merge_requests) }

  def create_merge_request(id, params = {})
    params.merge!(id: id,
                  target_project_id: project.id,
                  target_branch: 'master',
                  source_project_id: project.id,
                  source_branch: 'mr name',
                  title: "mr name#{id}")

    merge_requests.create(params)
  end

  def create_merge_request_event(id, params = {})
    params.merge!(id: id,
                  project_id: project.id,
                  author_id: user.id,
                  target_type: 'MergeRequest')

    events.create(params)
  end

  describe '#perform' do
    it 'creates and updates closed and merged events' do
      timestamp = Time.new('2018-01-01 12:00:00').utc

      create_merge_request(1)
      create_merge_request_event(1, target_id: 1, action: 3, updated_at: timestamp)
      create_merge_request_event(2, target_id: 1, action: 3, updated_at: timestamp + 10.seconds)

      create_merge_request_event(3, target_id: 1, action: 7, updated_at: timestamp)
      create_merge_request_event(4, target_id: 1, action: 7, updated_at: timestamp + 10.seconds)

      subject.perform(1, 1)

      merge_request = MergeRequest.first

      expect(merge_request.metrics).to have_attributes(latest_closed_by_id: user.id,
                                                       latest_closed_at: timestamp + 10.seconds,
                                                       merged_by_id: user.id)
    end
  end
end
