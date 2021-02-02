# frozen_string_literal: true

RSpec.shared_examples 'git repository routes' do
  let(:params) { { repository_path: path.delete_prefix('/') } }
  let(:container_path) { path.delete_suffix('.git') }

  it 'routes Git endpoints' do
    expect(get("#{path}/info/refs")).to route_to('repositories/git_http#info_refs', **params)
    expect(post("#{path}/git-upload-pack")).to route_to('repositories/git_http#git_upload_pack', **params)
    expect(post("#{path}/git-receive-pack")).to route_to('repositories/git_http#git_receive_pack', **params)
  end

  context 'requests without .git format' do
    it 'redirects requests to /info/refs', type: :request do
      expect(get("#{container_path}/info/refs")).to redirect_to("#{container_path}.git/info/refs")
      expect(get("#{container_path}/info/refs?service=git-upload-pack")).to redirect_to("#{container_path}.git/info/refs?service=git-upload-pack")
      expect(get("#{container_path}/info/refs?service=git-receive-pack")).to redirect_to("#{container_path}.git/info/refs?service=git-receive-pack")
    end
  end

  it 'routes LFS endpoints' do
    oid = generate(:oid)

    expect(post("#{path}/info/lfs/objects/batch")).to route_to('repositories/lfs_api#batch', **params)
    expect(post("#{path}/info/lfs/objects")).to route_to('repositories/lfs_api#deprecated', **params)
    expect(get("#{path}/info/lfs/objects/#{oid}")).to route_to('repositories/lfs_api#deprecated', oid: oid, **params)

    expect(post("#{path}/info/lfs/locks/123/unlock")).to route_to('repositories/lfs_locks_api#unlock', id: '123', **params)
    expect(post("#{path}/info/lfs/locks/verify")).to route_to('repositories/lfs_locks_api#verify', **params)

    expect(get("#{path}/gitlab-lfs/objects/#{oid}")).to route_to('repositories/lfs_storage#download', oid: oid, **params)
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/456/authorize")).to route_to('repositories/lfs_storage#upload_authorize', oid: oid, size: '456', **params)
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/456")).to route_to('repositories/lfs_storage#upload_finalize', oid: oid, size: '456', **params)
  end
end

RSpec.shared_examples 'git repository routes without fallback' do
  let(:container_path) { path.delete_suffix('.git') }

  context 'requests without .git format' do
    it 'does not redirect other requests' do
      expect(post("#{container_path}/git-upload-pack")).not_to be_routable
    end
  end

  it 'routes LFS endpoints for unmatched routes' do
    oid = generate(:oid)

    expect(put("#{path}/gitlab-lfs/objects/foo")).not_to be_routable
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo")).not_to be_routable
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo/authorize")).not_to be_routable
  end
end

RSpec.shared_examples 'git repository routes with fallback' do
  let(:container_path) { path.delete_suffix('.git') }

  context 'requests without .git format' do
    it 'does not redirect other requests' do
      expect(post("#{container_path}/git-upload-pack")).to route_to_route_not_found
    end
  end

  it 'routes LFS endpoints' do
    oid = generate(:oid)

    expect(put("#{path}/gitlab-lfs/objects/foo")).to route_to_route_not_found
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo")).to route_to_route_not_found
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo/authorize")).to route_to_route_not_found
  end
end

RSpec.shared_examples 'git repository routes with fallback for git-upload-pack' do
  let(:container_path) { path.delete_suffix('.git') }

  context 'requests without .git format' do
    it 'does not redirect other requests' do
      expect(post("#{container_path}/git-upload-pack")).to route_to_route_not_found
    end
  end

  it 'routes LFS endpoints for unmatched routes' do
    oid = generate(:oid)

    expect(put("#{path}/gitlab-lfs/objects/foo")).not_to be_routable
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo")).not_to be_routable
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo/authorize")).not_to be_routable
  end
end
