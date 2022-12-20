# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddEpicsRelativePosition, :migration, feature_category: :portfolio_management do
  let(:groups) { table(:namespaces) }
  let(:epics) { table(:epics) }
  let(:users) { table(:users) }
  let(:user) { users.create!(name: 'user', email: 'email@example.org', projects_limit: 100) }
  let(:group) { groups.create!(name: 'gitlab', path: 'gitlab-org', type: 'Group') }

  let!(:epic1) { epics.create!(title: 'epic 1', title_html: 'epic 1', author_id: user.id, group_id: group.id, iid: 1) }
  let!(:epic2) { epics.create!(title: 'epic 2', title_html: 'epic 2', author_id: user.id, group_id: group.id, iid: 2) }
  let!(:epic3) { epics.create!(title: 'epic 3', title_html: 'epic 3', author_id: user.id, group_id: group.id, iid: 3) }

  it 'does nothing if epics table contains relative_position' do
    expect { migrate! }.not_to change { epics.pluck(:relative_position) }
  end

  it 'adds relative_position if missing and backfills it with ID value', :aggregate_failures do
    ActiveRecord::Base.connection.execute('ALTER TABLE epics DROP relative_position')

    migrate!

    expect(epics.pluck(:relative_position)).to match_array([epic1.id * 500, epic2.id * 500, epic3.id * 500])
  end
end
