# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'groups routing' do
  let(:group_path) { 'projects.abc123' }
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

  it "to #runner_setup_scripts" do
    expect(get("/groups/#{group_path}/-/settings/ci_cd/runner_setup_scripts")).to route_to('groups/settings/ci_cd#runner_setup_scripts', group_id: group_path)
  end

  it 'routes to the avatars controller' do
    expect(delete("/groups/#{group_path}/-/avatar"))
      .to route_to(group_id: group_path, controller: 'groups/avatars', action: 'destroy')
  end

  it 'routes to the boards controller' do
    allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

    expect(get('/groups/gitlabhq/-/boards')).to route_to('groups/boards#index', group_id: 'gitlabhq')
  end

  it 'routes to the harbor repositories controller' do
    expect(get("groups/#{group_path}/-/harbor/repositories")).to route_to('groups/harbor/repositories#index', group_id: group_path)
  end

  it 'routes to the harbor artifacts controller' do
    expect(get("groups/#{group_path}/-/harbor/repositories/test/artifacts")).to route_to('groups/harbor/artifacts#index', group_id: group_path, repository_id: 'test')
  end

  it 'routes to the harbor tags controller' do
    expect(get("groups/#{group_path}/-/harbor/repositories/test/artifacts/test/tags")).to route_to('groups/harbor/tags#index', group_id: group_path, repository_id: 'test', artifact_id: 'test')
  end

  it 'routes to the usage quotas controller' do
    expect(get("groups/#{group_path}/-/usage_quotas")).to route_to("groups/usage_quotas#index", group_id: group_path)
  end
end

RSpec.describe "Groups", "routing", feature_category: :groups_and_projects do
  context 'complex group path with dot' do
    include_examples 'groups routing' do
      let(:group_path) { 'complex.group-namegit' }
    end
  end

  context 'group path starting with help' do
    include_examples 'groups routing' do
      let(:group_path) { 'help.abc123' }
    end
  end

  context 'group path starting with projects' do
    include_examples 'groups routing' do
      let(:group_path) { 'projects.abc123' }
    end
  end

  describe 'dependency proxy for containers' do
    it 'routes to #authenticate' do
      expect(get('/v2')).to route_to('groups/dependency_proxy_auth#authenticate')
    end

    it 'routes to #upload_manifest' do
      expect(post('v2/gitlabhq/dependency_proxy/containers/alpine/manifests/latest/upload'))
        .to route_to('groups/dependency_proxy_for_containers#upload_manifest', group_id: 'gitlabhq', image: 'alpine', tag: 'latest')
    end

    it 'routes to #upload_blob' do
      expect(post('v2/gitlabhq/dependency_proxy/containers/alpine/blobs/abc12345/upload'))
        .to route_to('groups/dependency_proxy_for_containers#upload_blob', group_id: 'gitlabhq', image: 'alpine', sha: 'abc12345')
    end

    it 'routes to #upload_manifest_authorize' do
      expect(post('v2/gitlabhq/dependency_proxy/containers/alpine/manifests/latest/upload/authorize'))
        .to route_to('groups/dependency_proxy_for_containers#authorize_upload_manifest', group_id: 'gitlabhq', image: 'alpine', tag: 'latest')
    end

    it 'routes to #upload_blob_authorize' do
      expect(post('v2/gitlabhq/dependency_proxy/containers/alpine/blobs/abc12345/upload/authorize'))
        .to route_to('groups/dependency_proxy_for_containers#authorize_upload_blob', group_id: 'gitlabhq', image: 'alpine', sha: 'abc12345')
    end

    context 'image name without namespace' do
      it 'routes to #manifest' do
        expect(get('/v2/gitlabhq/dependency_proxy/containers/ruby/manifests/2.3.6'))
          .to route_to('groups/dependency_proxy_for_containers#manifest', group_id: 'gitlabhq', image: 'ruby', tag: '2.3.6')
      end

      it 'routes to #blob' do
        expect(get('/v2/gitlabhq/dependency_proxy/containers/ruby/blobs/abc12345'))
          .to route_to('groups/dependency_proxy_for_containers#blob', group_id: 'gitlabhq', image: 'ruby', sha: 'abc12345')
      end

      it 'does not route to #blob with an invalid sha' do
        expect(get('/v2/gitlabhq/dependency_proxy/containers/ruby/blobs/sha256:asdf1234%2f%2e%2e'))
          .not_to route_to(group_id: 'gitlabhq', image: 'ruby', sha: 'sha256:asdf1234%2f%2e%2e')
      end

      it 'does not route to #blob with an invalid image' do
        expect(get('/v2/gitlabhq/dependency_proxy/containers/ru*by/blobs/abc12345'))
          .not_to route_to('groups/dependency_proxy_for_containers#blob', group_id: 'gitlabhq', image: 'ru*by', sha: 'abc12345')
      end
    end

    context 'image name with namespace' do
      it 'routes to #manifest' do
        expect(get('/v2/gitlabhq/dependency_proxy/containers/foo/bar/manifests/2.3.6'))
          .to route_to('groups/dependency_proxy_for_containers#manifest', group_id: 'gitlabhq', image: 'foo/bar', tag: '2.3.6')
      end

      it 'routes to #blob' do
        expect(get('/v2/gitlabhq/dependency_proxy/containers/foo/bar/blobs/abc12345'))
          .to route_to('groups/dependency_proxy_for_containers#blob', group_id: 'gitlabhq', image: 'foo/bar', sha: 'abc12345')
      end
    end
  end

  describe Groups::RedirectController, 'routing' do
    it 'to #redirect_from_id' do
      expect(get('/-/g/1')).to route_to('groups/redirect#redirect_from_id', id: '1')
    end
  end
end
