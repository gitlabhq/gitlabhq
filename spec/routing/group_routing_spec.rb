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

  it "to #activity" do
    expect(get("/groups/#{group_path}/activity")).to route_to('groups#activity', id: group_path)
  end

  it "to #issues" do
    expect(get("/groups/#{group_path}/issues")).to route_to('groups#issues', id: group_path)
  end

  it "to #members" do
    expect(get("/groups/#{group_path}/-/group_members")).to route_to('groups/group_members#index', group_id: group_path)
  end

  describe 'legacy redirection' do
    shared_examples 'canonical groups route' do |path|
      it "#{path} routes to the correct controller" do
        expect(get("/groups/#{group_path}/-/#{path}"))
          .to route_to(group_id: group_path,
                       controller: "groups/#{path}",
                       action: 'index')
      end

      it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/#{path}", "/groups/complex.group-namegit/-/#{path}/" do
        let(:resource) { create(:group, parent: group, path: path) }
      end
    end

    describe 'labels' do
      it_behaves_like 'canonical groups route', 'labels'
    end

    describe 'group_members' do
      it_behaves_like 'canonical groups route', 'group_members'
    end

    describe 'avatar' do
      it 'routes to the avatars controller' do
        expect(delete("/groups/#{group_path}/-/avatar"))
          .to route_to(group_id: group_path,
                       controller: 'groups/avatars',
                       action: 'destroy')
      end
    end

    describe 'milestones' do
      it_behaves_like 'canonical groups route', 'milestones'

      context 'nested routes' do
        include RSpec::Rails::RequestExampleGroup

        let(:milestone) { create(:milestone, group: group) }

        it 'redirects the nested routes' do
          request = get("/groups/#{group_path}/milestones/#{milestone.id}/merge_requests")
          expect(request).to redirect_to("/groups/#{group_path}/-/milestones/#{milestone.id}/merge_requests")
        end
      end
    end
  end
end
