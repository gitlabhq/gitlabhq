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

  describe 'legacy redirection' do
    describe 'labels' do
      it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/labels", "/groups/complex.group-namegit/-/labels" do
        let(:resource) { create(:group, parent: group, path: 'labels') }
      end

      context 'when requesting JSON' do
        it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/labels.json", "/groups/complex.group-namegit/-/labels.json" do
          let(:resource) { create(:group, parent: group, path: 'labels') }
        end
      end
    end

    describe 'group_members' do
      it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/group_members", "/groups/complex.group-namegit/-/group_members" do
        let(:resource) { create(:group, parent: group, path: 'group_members') }
      end
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
      it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/milestones", "/groups/complex.group-namegit/-/milestones" do
        let(:resource) { create(:group, parent: group, path: 'milestones') }
      end

      context 'nested routes' do
        include RSpec::Rails::RequestExampleGroup

        let(:milestone) { create(:milestone, group: group) }

        it 'redirects the nested routes' do
          request = get("/groups/#{group_path}/milestones/#{milestone.id}/merge_requests")
          expect(request).to redirect_to("/groups/#{group_path}/-/milestones/#{milestone.id}/merge_requests")
        end
      end

      context 'with a query string' do
        it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/milestones?hello=world", "/groups/complex.group-namegit/-/milestones?hello=world" do
          let(:resource) { create(:group, parent: group, path: 'milestones') }
        end

        it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/milestones?milestones=/milestones", "/groups/complex.group-namegit/-/milestones?milestones=/milestones" do
          let(:resource) { create(:group, parent: group, path: 'milestones') }
        end
      end
    end

    describe 'edit' do
      it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/edit", "/groups/complex.group-namegit/-/edit" do
        let(:resource) do
          pending('still rejected because of the wildcard reserved word')
          create(:group, parent: group, path: 'edit')
        end
      end
    end

    describe 'issues' do
      it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/issues", "/groups/complex.group-namegit/-/issues" do
        let(:resource) { create(:group, parent: group, path: 'issues') }
      end
    end

    describe 'merge_requests' do
      it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/merge_requests", "/groups/complex.group-namegit/-/merge_requests" do
        let(:resource) { create(:group, parent: group, path: 'merge_requests') }
      end
    end

    describe 'projects' do
      it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/projects", "/groups/complex.group-namegit/-/projects" do
        let(:resource) { create(:group, parent: group, path: 'projects') }
      end
    end

    describe 'activity' do
      it_behaves_like 'redirecting a legacy path', "/groups/complex.group-namegit/activity", "/groups/complex.group-namegit/-/activity" do
        let(:resource) { create(:group, parent: group, path: 'activity') }
      end

      it_behaves_like 'redirecting a legacy path', "/groups/activity/activity", "/groups/activity/-/activity" do
        let!(:parent) { create(:group, path: 'activity') }
        let(:resource) { create(:group, parent: parent, path: 'activity') }
      end
    end
  end
end
