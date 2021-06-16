# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeduplicateEpicIids, :migration, schema: 20201106082723 do
  let(:routes) { table(:routes) }
  let(:epics) { table(:epics) }
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }

  let!(:group) { create_group('foo') }
  let!(:user) { users.create!(email: 'test@example.com', projects_limit: 100, username: 'test') }
  let!(:dup_epic1) { epics.create!(iid: 1, title: 'epic 1', group_id: group.id, author_id: user.id, created_at: Time.now, updated_at: Time.now, title_html: 'any') }
  let!(:dup_epic2) { epics.create!(iid: 1, title: 'epic 2', group_id: group.id, author_id: user.id, created_at: Time.now, updated_at: Time.now, title_html: 'any') }
  let!(:dup_epic3) { epics.create!(iid: 1, title: 'epic 3', group_id: group.id, author_id: user.id, created_at: Time.now, updated_at: Time.now, title_html: 'any') }

  it 'deduplicates epic iids', :aggregate_failures do
    duplicate_epics_count = epics.where(iid: 1, group_id: group.id).count
    expect(duplicate_epics_count).to eq 3

    migrate!

    duplicate_epics_count = epics.where(iid: 1, group_id: group.id).count
    expect(duplicate_epics_count).to eq 1
    expect(dup_epic1.reload.iid).to eq 1
    expect(dup_epic2.reload.iid).to eq 2
    expect(dup_epic3.reload.iid).to eq 3
  end

  def create_group(path)
    namespaces.create!(name: path, path: path, type: 'Group').tap do |namespace|
      routes.create!(path: namespace.path, name: namespace.name, source_id: namespace.id, source_type: 'Namespace')
    end
  end
end
