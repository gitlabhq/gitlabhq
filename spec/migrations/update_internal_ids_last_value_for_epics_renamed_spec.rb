# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateInternalIdsLastValueForEpicsRenamed, :migration, schema: 20201124185639 do
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:epics) { table(:epics) }
  let(:internal_ids) { table(:internal_ids) }

  let!(:author) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 0) }
  let!(:group1) { namespaces.create!(type: 'Group', name: 'group1', path: 'group1') }
  let!(:group2) { namespaces.create!(type: 'Group', name: 'group2', path: 'group2') }
  let!(:group3) { namespaces.create!(type: 'Group', name: 'group3', path: 'group3') }
  let!(:epic_last_value1) { internal_ids.create!(usage: 4, last_value: 5, namespace_id: group1.id) }
  let!(:epic_last_value2) { internal_ids.create!(usage: 4, last_value: 5, namespace_id: group2.id) }
  let!(:epic_last_value3) { internal_ids.create!(usage: 4, last_value: 5, namespace_id: group3.id) }
  let!(:epic_1) { epics.create!(iid: 110, title: 'from epic 1', group_id: group1.id, author_id: author.id, title_html: 'any') }
  let!(:epic_2) { epics.create!(iid: 5, title: 'from epic 1', group_id: group2.id, author_id: author.id, title_html: 'any') }
  let!(:epic_3) { epics.create!(iid: 3, title: 'from epic 1', group_id: group3.id, author_id: author.id, title_html: 'any') }

  it 'updates out of sync internal_ids last_value' do
    migrate!

    expect(internal_ids.find_by(usage: 4, namespace_id: group1.id).last_value).to eq(110)
    expect(internal_ids.find_by(usage: 4, namespace_id: group2.id).last_value).to eq(5)
    expect(internal_ids.find_by(usage: 4, namespace_id: group3.id).last_value).to eq(5)
  end
end
