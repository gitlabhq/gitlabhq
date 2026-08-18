# frozen_string_literal: true

require 'spec_helper'

# Asserts each web access-token endpoint is wired with the right permission; the
# GranularTokenAuthorization mechanism itself is unit tested separately.
RSpec.describe 'Granular PAT authorization on the web access token path', feature_category: :permissions do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group, :private, developers: user) }
  let_it_be(:project) { create(:project, :repository, :private, group: group, developers: user) }

  let(:headers) { { 'PRIVATE-TOKEN' => token.token } }

  subject(:request) { get path, headers: headers }

  shared_examples 'granular web access authorization' do
    context 'with a granular token carrying the permission on the boundary' do
      let(:token) { create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(boundary), permissions: permission) }

      it 'allows access' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with a granular token missing the permission' do
      let(:token) { create(:granular_pat, user: user) }

      it 'responds with not found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with a legacy token' do
      let(:token) { create(:personal_access_token, user: user, scopes: %w[api]) }

      it 'allows access' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'repository archive download' do
    let(:boundary) { project }
    let(:permission) { :download_code }
    let(:path) { "/#{project.full_path}/-/archive/#{project.default_branch}/archive.zip" }

    it_behaves_like 'granular web access authorization'
  end

  describe 'project releases feed' do
    let(:boundary) { project }
    let(:permission) { :read_release }
    let(:path) { "/#{project.full_path}/-/releases.atom" }

    it_behaves_like 'granular web access authorization'
  end

  describe 'project issues feed' do
    let(:boundary) { project }
    let(:permission) { :read_work_item }
    let(:path) { "/#{project.full_path}/-/issues.atom" }

    it_behaves_like 'granular web access authorization'
  end

  describe 'group issues feed' do
    let(:boundary) { group }
    let(:permission) { :read_work_item }
    let(:path) { "/groups/#{group.full_path}/-/issues.atom" }

    it_behaves_like 'granular web access authorization'
  end

  describe 'project merge requests feed' do
    let(:boundary) { project }
    let(:permission) { :read_merge_request }
    let(:path) { "/#{project.full_path}/-/merge_requests.atom" }

    it_behaves_like 'granular web access authorization'
  end

  describe 'group merge requests feed' do
    let(:boundary) { group }
    let(:permission) { :read_merge_request }
    let(:path) { "/groups/#{group.full_path}/-/merge_requests.atom" }

    it_behaves_like 'granular web access authorization'
  end

  describe 'project commits feed' do
    let(:boundary) { project }
    let(:permission) { :read_code }
    let(:path) { project_commits_path(project, project.default_branch, format: :atom) }

    it_behaves_like 'granular web access authorization'
  end

  describe 'project tags feed' do
    let(:boundary) { project }
    let(:permission) { :read_code }
    let(:path) { project_tags_path(project, format: :atom) }

    it_behaves_like 'granular web access authorization'
  end

  describe 'project activity feed' do
    let(:boundary) { project }
    let(:permission) { :read_event }
    let(:path) { "/#{project.full_path}.atom" }

    it_behaves_like 'granular web access authorization'
  end

  describe 'group activity feed' do
    let(:boundary) { group }
    let(:permission) { :read_event }
    let(:path) { "/#{group.full_path}.atom" }

    it_behaves_like 'granular web access authorization'
  end

  # Authorized on the token-owner (user) boundary, not the viewed profile.
  describe 'user activity feed' do
    let(:boundary) { ::Authz::GranularScope::Access::USER }
    let(:permission) { :read_activity }
    let(:path) { "/#{user.username}.atom" }

    it_behaves_like 'granular web access authorization'
  end

  describe 'dashboard projects feed' do
    let(:boundary) { ::Authz::GranularScope::Access::USER }
    let(:permission) { :read_project }
    let(:path) { "/dashboard/projects.atom" }

    it_behaves_like 'granular web access authorization'
  end

  # The :design format maps to read_design, which is granted through the
  # Work Item: Read assignable permission rather than a standalone design
  # permission.
  describe 'design management images' do
    include DesignManagementTestHelpers

    let_it_be(:issue) { create(:issue, project: project) }

    let(:boundary) { project }
    let(:permission) { :read_work_item }

    before do
      enable_design_management
    end

    describe 'raw image' do
      let_it_be(:design) { create(:design, :with_file, issue: issue) }

      let(:path) { project_design_management_designs_raw_image_path(project, design) }

      it_behaves_like 'granular web access authorization'
    end

    describe 'resized image' do
      # Per-example on purpose: resized design images are served from
      # CarrierWave disk storage, and the suite deletes CarrierWave.root after
      # every example. A group-level (let_it_be) record outlives its stored
      # file, so the second example that serves it fails with
      # ActionController::MissingFile. Raw images are served from Git LFS,
      # which is not cleaned between examples, so the raw group can share one.
      let(:design) { create(:design, :with_smaller_image_versions, issue: issue) }
      let(:path) { project_design_management_designs_resized_image_path(project, design, id: 'v432x230') }

      it_behaves_like 'granular web access authorization'
    end

    # A granular token must not be worse than anonymous: on a public
    # project, Authz::BoundaryPolicy grants any assignable permission that
    # anonymous users already hold on the boundary, whatever the token's
    # scopes. For read_design that arrives through a two-hop policy chain
    # (ProjectPolicy grants read_design via can?(:read_issue), then the
    # anonymous_can_read_design condition picks it up), which nothing else
    # pins.
    describe 'raw image on a public project' do
      let_it_be(:public_project) { create(:project, :public) }
      let_it_be(:public_issue) { create(:issue, project: public_project) }
      let_it_be(:public_design) { create(:design, :with_file, issue: public_issue) }

      let(:path) { project_design_management_designs_raw_image_path(public_project, public_design) }

      context 'with a granular token without any scope' do
        let(:token) { create(:granular_pat, user: user) }

        it 'allows access' do
          request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'release downloads' do
    let_it_be_with_reload(:release_project) do
      create(:project, :repository, :private, group: group, developers: user)
    end

    let_it_be_with_reload(:release) { create(:release, project: release_project, tag: 'v1.0.0') }
    let!(:link) do
      create(:release_link, release: release, filepath: '/bin/asset',
        url: "https://#{Gitlab.config.gitlab.host}:#{Gitlab.config.gitlab.port}/abcd")
    end

    let(:path) { "#{project_releases_path(release_project)}/#{release.tag}/downloads/bin/asset" }

    it 'denies a granular token without read_release' do
      token = create(:granular_pat, user: user)

      get path, headers: { 'PRIVATE-TOKEN' => token.token }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'allows a granular token with read_release' do
      token = create(:granular_pat, user: user,
        boundary: ::Authz::Boundary.for(release_project), permissions: :read_release)

      get path, headers: { 'PRIVATE-TOKEN' => token.token }

      expect(response).to have_gitlab_http_status(:redirect)
    end
  end

  # Redirects on success, so we assert the granular gate directly.
  describe 'personal access token expiry calendar' do
    let(:path) { "/-/user_settings/personal_access_tokens.ics" }

    it 'denies a granular token without read_personal_access_token' do
      token = create(:granular_pat, user: user)

      get path, headers: { 'PRIVATE-TOKEN' => token.token }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'allows a granular token with read_personal_access_token' do
      token = create(:granular_pat, user: user,
        boundary: ::Authz::Boundary.for(::Authz::GranularScope::Access::USER),
        permissions: :read_personal_access_token)

      get path, headers: { 'PRIVATE-TOKEN' => token.token }

      expect(response).to have_gitlab_http_status(:redirect)
    end
  end
end
