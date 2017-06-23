require 'spec_helper'

describe Groups::DestroyService, services: true do
  let!(:user)         { create(:user) }
  let!(:group)        { create(:group) }
  let!(:project)      { create(:empty_project, namespace: group) }
  let!(:geo_node) { create(:geo_node, :current, :primary) }

  before do
    group.add_user(user, Gitlab::Access::OWNER)
  end

  it 'creates a Geo event log when project is deleted synchronously' do
    Groups::DestroyService.new(group, user).execute

    expect(Geo::EventLog.count).to eq(1)
    expect(Geo::RepositoryDeletedEvent.count).to eq(1)
  end

  it 'creates a Geo event log when project is deleted asynchronously' do
    Sidekiq::Testing.inline! { Groups::DestroyService.new(group, user).async_execute }

    expect(Geo::EventLog.count).to eq(1)
    expect(Geo::RepositoryDeletedEvent.count).to eq(1)
  end
end
