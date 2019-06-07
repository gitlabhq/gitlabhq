require 'spec_helper'

describe "Groups", "routing" do
  let(:group_path) { 'complex.group-namegit' }
  let!(:group) { create(:group, path: group_path) }

  it "to #show" do
    expect(get("/groups/#{group_path}")).to route_to('groups#show', id: group_path)
  end

  it "also supports nested groups" do
    nested_group = create(:group, parent: group)
    expect(get("/#{group_path}/#{nested_group.path}")).to route_to('groups#show', id: "#{group_path}/#{nested_group.path}")
  end

  it "also display group#show on the short path" do
    expect(get("/#{group_path}")).to route_to('groups#show', id: group_path)
  end

  it "to #details" do
    expect(get("/groups/#{group_path}/-/details")).to route_to('groups#details', id: group_path)
  end

  it "to #activity" do
    expect(get("/groups/#{group_path}/-/activity")).to route_to('groups#activity', id: group_path)
  end

  it "to #issues" do
    expect(get("/groups/#{group_path}/-/issues")).to route_to('groups#issues', id: group_path)
  end

  it "to #members" do
    expect(get("/groups/#{group_path}/-/group_members")).to route_to('groups/group_members#index', group_id: group_path)
  end

  it "to #labels" do
    expect(get("/groups/#{group_path}/-/labels")).to route_to('groups/labels#index', group_id: group_path)
  end

  it "to #milestones" do
    expect(get("/groups/#{group_path}/-/milestones")).to route_to('groups/milestones#index', group_id: group_path)
  end

  it 'routes to the avatars controller' do
    expect(delete("/groups/#{group_path}/-/avatar"))
      .to route_to(group_id: group_path,
                   controller: 'groups/avatars',
                   action: 'destroy')
  end

  it 'routes to the boards controller' do
    allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

    expect(get('/groups/gitlabhq/-/boards')).to route_to('groups/boards#index', group_id: 'gitlabhq')
  end
end
