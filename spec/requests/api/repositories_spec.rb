# frozen_string_literal: true

require 'spec_helper'
require 'mime/types'

RSpec.describe API::Repositories do
  include RepoHelpers
  include WorkhorseHelpers
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:guest) { create(:user).tap { |u| create(:project_member, :guest, user: u, project: project) } }
  let!(:project) { create(:project, :repository, creator: user) }
  let!(:maintainer) { create(:project_member, :maintainer, user: user, project: project) }

  describe "GET /projects/:id/repository/tree" do
    let(:route) { "/projects/#{project.id}/repository/tree" }

    shared_examples_for 'repository tree' do
      it 'returns the repository tree' do
        get api(route, current_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        first_commit = json_response.first
        expect(first_commit['name']).to eq('bar')
        expect(first_commit['type']).to eq('tree')
        expect(first_commit['mode']).to eq('040000')
      end

      context 'when ref does not exist' do
        it_behaves_like '404 response' do
          let(:request) { get api("#{route}?ref=foo", current_user) }
          let(:message) { '404 Tree Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route, current_user) }
        end
      end

      context 'with recursive=1' do
        it 'returns recursive project paths tree' do
          get api("#{route}?recursive=1", current_user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(response).to include_pagination_headers
          expect(json_response[4]['name']).to eq('html')
          expect(json_response[4]['path']).to eq('files/html')
          expect(json_response[4]['type']).to eq('tree')
          expect(json_response[4]['mode']).to eq('040000')
        end

        context 'when repository is disabled' do
          include_context 'disabled repository'

          it_behaves_like '403 response' do
            let(:request) { get api(route, current_user) }
          end
        end

        context 'when ref does not exist' do
          it_behaves_like '404 response' do
            let(:request) { get api("#{route}?recursive=1&ref=foo", current_user) }
            let(:message) { '404 Tree Not Found' }
          end
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository tree' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository tree' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end
  end

  describe "GET /projects/:id/repository/blobs/:sha" do
    let(:route) { "/projects/#{project.id}/repository/blobs/#{sample_blob.oid}" }

    shared_examples_for 'repository blob' do
      it 'returns blob attributes as json' do
        get api(route, current_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['size']).to eq(111)
        expect(json_response['encoding']).to eq("base64")
        expect(Base64.decode64(json_response['content']).lines.first).to eq("class Commit\n")
        expect(json_response['sha']).to eq(sample_blob.oid)
      end

      context 'when sha does not exist' do
        it_behaves_like '404 response' do
          let(:request) { get api(route.sub(sample_blob.oid, 'abcd9876'), current_user) }
          let(:message) { '404 Blob Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository blob' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository blob' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end
  end

  describe "GET /projects/:id/repository/blobs/:sha/raw" do
    let(:route) { "/projects/#{project.id}/repository/blobs/#{sample_blob.oid}/raw" }

    shared_examples_for 'repository raw blob' do
      it 'returns the repository raw blob' do
        expect(Gitlab::Workhorse).to receive(:send_git_blob)

        get api(route, current_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(headers[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
      end

      it 'sets inline content disposition by default' do
        get api(route, current_user)

        expect(headers['Content-Disposition']).to eq 'inline'
      end

      it 'defines an uncached header response' do
        get api(route, current_user)

        expect(response.headers["Cache-Control"]).to eq("max-age=0, private, must-revalidate, no-store, no-cache")
        expect(response.headers["Pragma"]).to eq("no-cache")
        expect(response.headers["Expires"]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
      end

      context 'when sha does not exist' do
        it_behaves_like '404 response' do
          let(:request) { get api(route.sub(sample_blob.oid, 'abcd9876'), current_user) }
          let(:message) { '404 Blob Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository raw blob' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository raw blob' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end
  end

  describe "GET /projects/:id/repository/archive(.:format)?:sha" do
    let(:project_id) { CGI.escape(project.full_path) }
    let(:route) { "/projects/#{project_id}/repository/archive" }

    before do
      allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
    end

    shared_examples_for 'repository archive' do
      it 'returns the repository archive' do
        get api(route, current_user)

        expect(response).to have_gitlab_http_status(:ok)

        type, params = workhorse_send_data

        expect(type).to eq('git-archive')
        expect(params['ArchivePath']).to match(/#{project.path}\-[^\.]+\.tar.gz/)
      end

      it 'returns the repository archive archive.zip' do
        get api("/projects/#{project_id}/repository/archive.zip", user)

        expect(response).to have_gitlab_http_status(:ok)

        type, params = workhorse_send_data

        expect(type).to eq('git-archive')
        expect(params['ArchivePath']).to match(/#{project.path}\-[^\.]+\.zip/)
      end

      it 'returns the repository archive archive.tar.bz2' do
        get api("/projects/#{project_id}/repository/archive.tar.bz2", user)

        expect(response).to have_gitlab_http_status(:ok)

        type, params = workhorse_send_data

        expect(type).to eq('git-archive')
        expect(params['ArchivePath']).to match(/#{project.path}\-[^\.]+\.tar.bz2/)
      end

      context 'when sha does not exist' do
        it_behaves_like '404 response' do
          let(:request) { get api("#{route}?sha=xxx", current_user) }
          let(:message) { '404 File Not Found' }
        end
      end

      it 'rate limits user when thresholds hit' do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

        get api("/projects/#{project_id}/repository/archive.tar.bz2", user)

        expect(response).to have_gitlab_http_status(:too_many_requests)
      end

      context "when hotlinking detection is enabled" do
        before do
          stub_feature_flags(repository_archive_hotlinking_interception: true)
        end

        it_behaves_like "hotlink interceptor" do
          let(:http_request) do
            get api(route, current_user), headers: headers
          end
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository archive' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated and project path has dots' do
      it_behaves_like 'repository archive' do
        let(:project) { create(:project, :public, :repository, path: 'path.with.dot') }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository archive' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end
  end

  describe 'GET /projects/:id/repository/compare' do
    let(:route) { "/projects/#{project.id}/repository/compare" }

    shared_examples_for 'repository compare' do
      it "compares branches" do
        expect(::Gitlab::Git::Compare).to receive(:new).with(anything, anything, anything, {
          straight: false
        }).and_call_original
        get api(route, current_user), params: { from: 'master', to: 'feature' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['commits']).to be_present
        expect(json_response['diffs']).to be_present
      end

      it "compares branches with explicit merge-base mode" do
        expect(::Gitlab::Git::Compare).to receive(:new).with(anything, anything, anything, {
          straight: false
        }).and_call_original
        get api(route, current_user), params: { from: 'master', to: 'feature', straight: false }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['commits']).to be_present
        expect(json_response['diffs']).to be_present
      end

      it "compares branches with explicit straight mode" do
        expect(::Gitlab::Git::Compare).to receive(:new).with(anything, anything, anything, {
          straight: true
        }).and_call_original
        get api(route, current_user), params: { from: 'master', to: 'feature', straight: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['commits']).to be_present
        expect(json_response['diffs']).to be_present
      end

      it "compares tags" do
        get api(route, current_user), params: { from: 'v1.0.0', to: 'v1.1.0' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['commits']).to be_present
        expect(json_response['diffs']).to be_present
      end

      it "compares commits" do
        get api(route, current_user), params: { from: sample_commit.id, to: sample_commit.parent_id }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['commits']).to be_empty
        expect(json_response['diffs']).to be_empty
        expect(json_response['compare_same_ref']).to be_falsey
      end

      it "compares commits in reverse order" do
        get api(route, current_user), params: { from: sample_commit.parent_id, to: sample_commit.id }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['commits']).to be_present
        expect(json_response['diffs']).to be_present
      end

      it "compare commits between different projects with non-forked relation" do
        public_project = create(:project, :repository, :public)

        get api(route, current_user), params: { from: sample_commit.parent_id, to: sample_commit.id, from_project_id: public_project.id }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "compare commits between different projects" do
        group = create(:group)
        group.add_owner(current_user)

        forked_project = fork_project(project, current_user, repository: true, namespace: group)
        forked_project.repository.create_ref('refs/heads/improve/awesome', 'refs/heads/improve/more-awesome')

        get api(route, current_user), params: { from: 'improve/awesome', to: 'feature', from_project_id: forked_project.id }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['commits']).to be_present
        expect(json_response['diffs']).to be_present
      end

      it "compares same refs" do
        get api(route, current_user), params: { from: 'master', to: 'master' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['commits']).to be_empty
        expect(json_response['diffs']).to be_empty
        expect(json_response['compare_same_ref']).to be_truthy
      end

      it "returns an empty string when the diff overflows" do
        allow(Gitlab::Git::DiffCollection)
          .to receive(:default_limits)
          .and_return({ max_files: 2, max_lines: 2 })

        get api(route, current_user), params: { from: 'master', to: 'feature' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['commits']).to be_present
        expect(json_response['diffs']).to be_present
        expect(json_response['diffs'].first['diff']).to be_empty
      end

      it "returns a 404 when from ref is unknown" do
        get api(route, current_user), params: { from: 'unknown_ref', to: 'master' }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "returns a 404 when to ref is unknown" do
        get api(route, current_user), params: { from: 'master', to: 'unknown_ref' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository compare' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository compare' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end

    context 'api_caching_rate_limit_repository_compare is disabled' do
      before do
        stub_feature_flags(api_caching_rate_limit_repository_compare: false)
      end

      it_behaves_like 'repository compare' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'api_caching_repository_compare is disabled' do
      before do
        stub_feature_flags(api_caching_repository_compare: false)
      end

      it_behaves_like 'repository compare' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end
  end

  describe 'GET /projects/:id/repository/contributors' do
    let(:route) { "/projects/#{project.id}/repository/contributors" }

    shared_examples_for 'repository contributors' do
      it 'returns valid data' do
        get api(route, current_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        first_contributor = json_response.first
        expect(first_contributor['email']).to eq('tiagonbotelho@hotmail.com')
        expect(first_contributor['name']).to eq('tiagonbotelho')
        expect(first_contributor['commits']).to eq(1)
        expect(first_contributor['additions']).to eq(0)
        expect(first_contributor['deletions']).to eq(0)
      end

      context 'using sorting' do
        context 'by commits desc' do
          it 'returns the repository contribuors sorted by commits desc' do
            get api(route, current_user), params: { order_by: 'commits', sort: 'desc' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('contributors')
            expect(json_response.first['commits']).to be > json_response.last['commits']
          end
        end

        context 'by name desc' do
          it 'returns the repository contribuors sorted by name asc case insensitive' do
            get api(route, current_user), params: { order_by: 'name', sort: 'asc' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('contributors')
            expect(json_response.first['name'].downcase).to be < json_response.last['name'].downcase
          end
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository contributors' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository contributors' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end

    # Regression: https://gitlab.com/gitlab-org/gitlab-foss/issues/45363
    describe 'Links header contains working URLs when no `order_by` nor `sort` is given' do
      let(:project) { create(:project, :public, :repository) }
      let(:current_user) { nil }

      it 'returns `Link` header that includes URLs with default value for `order_by` & `sort`' do
        get api(route, current_user)

        first_link_url = response.headers['Link'].split(';').first

        expect(first_link_url).to include('order_by=commits')
        expect(first_link_url).to include('sort=asc')
      end
    end
  end

  describe 'GET :id/repository/merge_base' do
    let(:refs) do
      %w(304d257dcb821665ab5110318fc58a007bd104ed 0031876facac3f2b2702a0e53a26e89939a42209 570e7b2abdd848b95f2f578043fc23bd6f6fd24d)
    end

    subject(:request) do
      get(api("/projects/#{project.id}/repository/merge_base", current_user), params: { refs: refs })
    end

    shared_examples 'merge base' do
      it 'returns the common ancestor' do
        request

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['id']).to be_present
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'merge base' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:current_user) { nil }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'merge base' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:current_user) { guest }
      end
    end

    context 'when passing refs that do not exist' do
      it_behaves_like '400 response' do
        let(:refs) { %w(304d257dcb821665ab5110318fc58a007bd104ed missing) }
        let(:current_user) { user }
        let(:message) { 'Could not find ref: missing' }
      end
    end

    context 'when passing refs that do not have a merge base' do
      it_behaves_like '404 response' do
        let(:refs) { ['304d257dcb821665ab5110318fc58a007bd104ed', TestEnv::BRANCH_SHA['orphaned-branch']] }
        let(:current_user) { user }
        let(:message) { '404 Merge Base Not Found' }
      end
    end

    context 'when not enough refs are passed' do
      let(:refs) { %w(only-one) }
      let(:current_user) { user }

      it 'renders a bad request error' do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('Provide at least 2 refs')
      end
    end
  end

  describe 'POST /projects/:id/repository/changelog' do
    it 'generates the changelog for a version' do
      spy = instance_spy(Repositories::ChangelogService)

      allow(Repositories::ChangelogService)
        .to receive(:new)
        .with(
          project,
          user,
          version: '1.0.0',
          from: 'foo',
          to: 'bar',
          date: DateTime.new(2020, 1, 1),
          branch: 'kittens',
          trailer: 'Foo',
          file: 'FOO.md',
          message: 'Commit message'
        )
        .and_return(spy)

      allow(spy).to receive(:execute)

      post(
        api("/projects/#{project.id}/repository/changelog", user),
        params: {
          version: '1.0.0',
          from: 'foo',
          to: 'bar',
          date: '2020-01-01',
          branch: 'kittens',
          trailer: 'Foo',
          file: 'FOO.md',
          message: 'Commit message'
        }
      )

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'supports leaving out the from and to attribute' do
      spy = instance_spy(Repositories::ChangelogService)

      allow(Repositories::ChangelogService)
        .to receive(:new)
        .with(
          project,
          user,
          version: '1.0.0',
          date: DateTime.new(2020, 1, 1),
          branch: 'kittens',
          trailer: 'Foo',
          file: 'FOO.md',
          message: 'Commit message'
        )
        .and_return(spy)

      expect(spy).to receive(:execute)

      post(
        api("/projects/#{project.id}/repository/changelog", user),
        params: {
          version: '1.0.0',
          date: '2020-01-01',
          branch: 'kittens',
          trailer: 'Foo',
          file: 'FOO.md',
          message: 'Commit message'
        }
      )

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'produces an error when generating the changelog fails' do
      spy = instance_spy(Repositories::ChangelogService)

      allow(Repositories::ChangelogService)
        .to receive(:new)
        .with(
          project,
          user,
          version: '1.0.0',
          from: 'foo',
          to: 'bar',
          date: DateTime.new(2020, 1, 1),
          branch: 'kittens',
          trailer: 'Foo',
          file: 'FOO.md',
          message: 'Commit message'
        )
        .and_return(spy)

      allow(spy)
        .to receive(:execute)
        .and_raise(Gitlab::Changelog::Error.new('oops'))

      post(
        api("/projects/#{project.id}/repository/changelog", user),
        params: {
          version: '1.0.0',
          from: 'foo',
          to: 'bar',
          date: '2020-01-01',
          branch: 'kittens',
          trailer: 'Foo',
          file: 'FOO.md',
          message: 'Commit message'
        }
      )

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
      expect(json_response['message']).to eq('Failed to generate the changelog: oops')
    end
  end
end
