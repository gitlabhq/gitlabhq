# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GoProxy do
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let_it_be(:user) { create :user }
  let_it_be(:project) { create :project_empty_repo, creator: user, path: 'my-go-lib' }
  let_it_be(:base) { "#{Settings.build_gitlab_go_url}/#{project.full_path}" }

  let_it_be(:oauth) { create :oauth_access_token, scopes: 'api', resource_owner: user }
  let_it_be(:job) { create :ci_build, user: user, status: :running, project: project }
  let_it_be(:pa_token) { create :personal_access_token, user: user }

  let_it_be(:modules) do
    commits = [
      create(:go_module_commit, :files,   project: project, tag: 'v1.0.0', files: { 'README.md' => 'Hi' }       ),
      create(:go_module_commit, :module,  project: project, tag: 'v1.0.1'                                       ),
      create(:go_module_commit, :package, project: project, tag: 'v1.0.2', path: 'pkg'                          ),
      create(:go_module_commit, :module,  project: project, tag: 'v1.0.3', name: 'mod'                          ),
      create(:go_module_commit, :files,   project: project,                files: { 'y.go' => "package a\n" }   ),
      create(:go_module_commit, :module,  project: project,                name: 'v2'                           ),
      create(:go_module_commit, :files,   project: project, tag: 'v2.0.0', files: { 'v2/x.go' => "package a\n" })
    ]

    { sha: [commits[4].sha, commits[5].sha] }
  end

  before do
    project.add_developer(user)

    stub_feature_flags(go_proxy_disable_gomod_validation: false)

    modules
  end

  shared_examples 'an unavailable resource' do
    it 'returns not found' do
      get_resource(user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'a module version list resource' do |*versions, path: ''|
    let(:module_name) { "#{base}#{path}" }
    let(:resource) { "list" }

    it "returns #{versions.empty? ? 'nothing' : versions.join(', ')}" do
      get_resource(user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body.split("\n").to_set).to eq(versions.to_set)
    end
  end

  shared_examples 'a missing module version list resource' do |path: ''|
    let(:module_name) { "#{base}#{path}" }
    let(:resource) { "list" }

    it_behaves_like 'an unavailable resource'
  end

  shared_examples 'a module version information resource' do |version, path: ''|
    let(:module_name) { "#{base}#{path}" }
    let(:resource) { "#{version}.info" }

    it "returns information for #{version}" do
      get_resource(user)

      time = project.repository.find_tag(version).dereferenced_target.committed_date

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_kind_of(Hash)
      expect(json_response['Version']).to eq(version)
      expect(json_response['Time']).to eq(time.strftime('%Y-%m-%dT%H:%M:%S.%L%:z'))
    end
  end

  shared_examples 'a missing module version information resource' do |version, path: ''|
    let(:module_name) { "#{base}#{path}" }
    let(:resource) { "#{version}.info" }

    it_behaves_like 'an unavailable resource'
  end

  shared_examples 'a module pseudo-version information resource' do |prefix, path: ''|
    let(:module_name) { "#{base}#{path}" }
    let(:commit) { project.repository.commit_by(oid: sha) }
    let(:version) { fmt_pseudo_version prefix, commit }
    let(:resource) { "#{version}.info" }

    it "returns information for #{prefix}yyyymmddhhmmss-abcdefabcdef" do
      get_resource(user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_kind_of(Hash)
      expect(json_response['Version']).to eq(version)
      expect(json_response['Time']).to eq(commit.committed_date.strftime('%Y-%m-%dT%H:%M:%S.%L%:z'))
    end
  end

  shared_examples 'a missing module pseudo-version information resource' do |path: ''|
    let(:module_name) { "#{base}#{path}" }
    let(:commit) do
      raise "tried to reference :commit without defining :sha" unless defined?(sha)

      project.repository.commit_by(oid: sha)
    end

    let(:resource) { "#{version}.info" }

    it_behaves_like 'an unavailable resource'
  end

  shared_examples 'a module file resource' do |version, path: ''|
    let(:module_name) { "#{base}#{path}" }
    let(:resource) { "#{version}.mod" }

    it "returns #{path}/go.mod from the repo" do
      get_resource(user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body.split("\n", 2).first).to eq("module #{module_name}")
    end
  end

  shared_examples 'a missing module file resource' do |version, path: ''|
    let(:module_name) { "#{base}#{path}" }
    let(:resource) { "#{version}.mod" }

    it_behaves_like 'an unavailable resource'
  end

  shared_examples 'a module archive resource' do |version, entries, path: ''|
    let(:module_name) { "#{base}#{path}" }
    let(:resource) { "#{version}.zip" }

    it "returns an archive of #{path.empty? ? '/' : path} @ #{version} from the repo" do
      get_resource(user)

      expect(response).to have_gitlab_http_status(:ok)

      entries = entries.map { |e| "#{module_name}@#{version}/#{e}" }.to_set
      actual = Set[]
      Zip::InputStream.open(StringIO.new(response.body)) do |zip|
        while (entry = zip.get_next_entry)
          actual.add(entry.name)
        end
      end

      expect(actual).to eq(entries)
    end
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/list' do
    context 'for the root module' do
      it_behaves_like 'a module version list resource', 'v1.0.1', 'v1.0.2', 'v1.0.3'
    end

    context 'for the package' do
      it_behaves_like 'a module version list resource', path: '/pkg'
    end

    context 'for the submodule' do
      it_behaves_like 'a module version list resource', 'v1.0.3', path: '/mod'
    end

    context 'for the root module v2' do
      it_behaves_like 'a module version list resource', 'v2.0.0', path: '/v2'
    end

    context 'with a URL encoded relative path component' do
      it_behaves_like 'a missing module version list resource', path: '/%2E%2E%2Fxyz'
    end

    context 'with the feature disabled' do
      before do
        stub_feature_flags(go_proxy: false)
      end

      it_behaves_like 'a missing module version list resource'
    end
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.info' do
    context 'with the root module v1.0.1' do
      it_behaves_like 'a module version information resource', 'v1.0.1'
    end

    context 'with the submodule v1.0.3' do
      it_behaves_like 'a module version information resource', 'v1.0.3', path: '/mod'
    end

    context 'with the root module v2.0.0' do
      it_behaves_like 'a module version information resource', 'v2.0.0', path: '/v2'
    end

    context 'with an invalid path' do
      it_behaves_like 'a missing module version information resource', 'v1.0.3', path: '/pkg'
    end

    context 'with an invalid version' do
      it_behaves_like 'a missing module version information resource', 'v1.0.1', path: '/mod'
    end

    context 'with a pseudo-version for v1' do
      it_behaves_like 'a module pseudo-version information resource', 'v1.0.4-0.' do
        let(:sha) { modules[:sha][0] }
      end
    end

    context 'with a pseudo-version for v2' do
      it_behaves_like 'a module pseudo-version information resource', 'v2.0.0-', path: '/v2' do
        let(:sha) { modules[:sha][1] }
      end
    end

    context 'with a pseudo-version with an invalid timestamp' do
      it_behaves_like 'a missing module pseudo-version information resource' do
        let(:version) { "v1.0.4-0.00000000000000-#{modules[:sha][0][0..11]}" }
      end
    end

    context 'with a pseudo-version with an invalid commit sha' do
      it_behaves_like 'a missing module pseudo-version information resource' do
        let(:sha) { modules[:sha][0] }
        let(:version) { "v1.0.4-0.#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-000000000000" }
      end
    end

    context 'with a pseudo-version with a short commit sha' do
      it_behaves_like 'a missing module pseudo-version information resource' do
        let(:sha) { modules[:sha][0] }
        let(:version) { "v1.0.4-0.#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-#{modules[:sha][0][0..10]}" }
      end
    end
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.mod' do
    context 'with the root module v1.0.1' do
      it_behaves_like 'a module file resource', 'v1.0.1'
    end

    context 'with the submodule v1.0.3' do
      it_behaves_like 'a module file resource', 'v1.0.3', path: '/mod'
    end

    context 'with the root module v2.0.0' do
      it_behaves_like 'a module file resource', 'v2.0.0', path: '/v2'
    end

    context 'with an invalid path' do
      it_behaves_like 'a missing module file resource', 'v1.0.3', path: '/pkg'
    end

    context 'with an invalid version' do
      it_behaves_like 'a missing module file resource', 'v1.0.1', path: '/mod'
    end
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.zip' do
    context 'with the root module v1.0.1' do
      it_behaves_like 'a module archive resource', 'v1.0.1', ['README.md', 'go.mod', 'a.go']
    end

    context 'with the root module v1.0.2' do
      it_behaves_like 'a module archive resource', 'v1.0.2', ['README.md', 'go.mod', 'a.go', 'pkg/b.go']
    end

    context 'with the root module v1.0.3' do
      it_behaves_like 'a module archive resource', 'v1.0.3', ['README.md', 'go.mod', 'a.go', 'pkg/b.go']
    end

    context 'with the submodule v1.0.3' do
      it_behaves_like 'a module archive resource', 'v1.0.3', ['go.mod', 'a.go'], path: '/mod'
    end

    context 'with the root module v2.0.0' do
      it_behaves_like 'a module archive resource', 'v2.0.0', ['go.mod', 'a.go', 'x.go'], path: '/v2'
    end
  end

  context 'with an invalid module directive' do
    let_it_be(:project) { create :project_empty_repo, :public, creator: user }
    let_it_be(:base) { "#{Settings.build_gitlab_go_url}/#{project.full_path}" }

    let_it_be(:modules) do
      create(:go_module_commit, :files, project: project,                files: { 'a.go' => "package\a" }                   )
      create(:go_module_commit, :files, project: project, tag: 'v1.0.0', files: { 'go.mod' => "module not/a/real/module\n" })
      create(:go_module_commit, :files, project: project,                files: { 'v2/a.go' => "package a\n" }              )
      create(:go_module_commit, :files, project: project, tag: 'v2.0.0', files: { 'v2/go.mod' => "module #{base}\n" }       )
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/list' do
      context 'with a completely wrong directive for v1' do
        it_behaves_like 'a module version list resource'
      end

      context 'with a directive omitting the suffix for v2' do
        it_behaves_like 'a module version list resource', path: '/v2'
      end
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.info' do
      context 'with a completely wrong directive for v1' do
        it_behaves_like 'a missing module version information resource', 'v1.0.0'
      end

      context 'with a directive omitting the suffix for v2' do
        it_behaves_like 'a missing module version information resource', 'v2.0.0', path: '/v2'
      end
    end
  end

  context 'with a case sensitive project and versions' do
    let_it_be(:project) { create :project_empty_repo, :public, creator: user, path: 'MyGoLib' }
    let_it_be(:base) { "#{Settings.build_gitlab_go_url}/#{project.full_path}" }
    let_it_be(:base_encoded) { base.gsub(/[A-Z]/) { |s| "!#{s.downcase}"} }

    let_it_be(:modules) do
      create(:go_module_commit, :files,   project: project, files: { 'README.md' => "Hi" })
      create(:go_module_commit, :module,  project: project, tag: 'v1.0.1-prerelease')
      create(:go_module_commit, :package, project: project, tag: 'v1.0.1-Prerelease', path: 'pkg')
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/list' do
      let(:resource) { "list" }

      context 'with a case encoded path' do
        it_behaves_like 'a module version list resource', 'v1.0.1-prerelease', 'v1.0.1-Prerelease' do
          let(:module_name) { base_encoded }
        end
      end

      context 'without a case encoded path' do
        it_behaves_like 'a missing module version list resource' do
          let(:module_name) { base.downcase }
        end
      end
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.info' do
      context 'with a case encoded path' do
        it_behaves_like 'a module version information resource', 'v1.0.1-Prerelease' do
          let(:module_name) { base_encoded }
          let(:resource) { "v1.0.1-!prerelease.info" }
        end
      end

      context 'without a case encoded path' do
        it_behaves_like 'a module version information resource', 'v1.0.1-prerelease' do
          let(:module_name) { base_encoded }
          let(:resource) { "v1.0.1-prerelease.info" }
        end
      end
    end
  end

  context 'with a private project' do
    let(:module_name) { base }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/list' do
      let(:resource) { "list" }

      it 'returns ok with an oauth token' do
        get_resource(oauth_access_token: oauth)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns ok with a job token' do
        get_resource(oauth_access_token: job)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns ok with a personal access token' do
        get_resource(personal_access_token: pa_token)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns ok with a personal access token and basic authentication' do
        get_resource(headers: basic_auth_header(user.username, pa_token.token))

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns unauthorized with a failed job token' do
        job.update!(status: :failed)
        get_resource(oauth_access_token: job)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns unauthorized with no authentication' do
        get_resource

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  context 'with a public project' do
    let(:module_name) { base }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/list' do
      let(:resource) { "list" }

      it 'returns ok with no authentication' do
        get_resource

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  context 'with a non-existent project' do
    def get_resource(user = nil, **params)
      get api("/projects/not%2fa%2fproject/packages/go/#{base}/@v/list", user, **params)
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/list' do
      it 'returns not found with a user' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns not found with an oauth token' do
        get_resource(oauth_access_token: oauth)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns not found with a job token' do
        get_resource(oauth_access_token: job)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns not found with a personal access token' do
        get_resource(personal_access_token: pa_token)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns unauthorized with no authentication' do
        get_resource

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  def get_resource(user = nil, headers: {}, **params)
    get api("/projects/#{project.id}/packages/go/#{module_name}/@v/#{resource}", user, **params), headers: headers
  end

  def fmt_pseudo_version(prefix, commit)
    "#{prefix}#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-#{commit.sha[0..11]}"
  end
end
