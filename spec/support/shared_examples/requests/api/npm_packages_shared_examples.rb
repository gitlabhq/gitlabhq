# frozen_string_literal: true

RSpec.shared_examples 'handling get metadata requests' do |scope: :project|
  include PackagesManagerApiSpecHelpers

  using RSpec::Parameterized::TableSyntax

  let_it_be(:package_dependency_link1) { create(:packages_dependency_link, package: package, dependency_type: :dependencies) }
  let_it_be(:package_dependency_link2) { create(:packages_dependency_link, package: package, dependency_type: :devDependencies) }
  let_it_be(:package_dependency_link3) { create(:packages_dependency_link, package: package, dependency_type: :bundleDependencies) }
  let_it_be(:package_dependency_link4) { create(:packages_dependency_link, package: package, dependency_type: :peerDependencies) }

  let_it_be(:package_metadatum) { create(:npm_metadatum, package: package) }

  let(:headers) { {} }

  subject(:request) { get(url, headers: headers) }

  shared_examples 'accept metadata request' do |status:|
    it 'accepts the metadata request' do
      subject

      expect(response).to have_gitlab_http_status(status)
      expect(response.media_type).to eq('application/json')
      expect(response).to match_response_schema('public_api/v4/packages/npm_package')
      expect(json_response['name']).to eq(package.name)
      expect(json_response['versions'][package.version]).to match_schema('public_api/v4/packages/npm_package_version')
      ::Packages::DependencyLink.dependency_types.keys.each do |dependency_type|
        expect(json_response.dig('versions', package.version, dependency_type.to_s)).to be_any
      end
      expect(json_response['dist-tags']).to match_schema('public_api/v4/packages/npm_package_tags')
    end
  end

  shared_examples 'reject metadata request' do |status:|
    it_behaves_like 'returning response status', status
  end

  shared_examples 'redirect metadata request' do |status:|
    it 'redirects metadata request' do
      subject

      expect(response).to have_gitlab_http_status(:found)
      expect(response.headers['Location']).to eq("https://registry.npmjs.org/#{package_name}")
    end
  end

  shared_examples 'handles authentication' do
    include_context 'dependency proxy helpers context'

    let(:package_name) { 'unscoped-package' }

    before do
      package.update!(name: package_name)

      set_npm_package_requests_forwarding(true, scope)
    end

    # No need to test the instance scope here.
    # Instance scope handling of unscoped packages is already tested in L180
    context 'with project or group scope', if: scope.in?(%i[project group]) do
      context 'when unauthenticated' do
        let(:headers) { {} }

        where(:visibility, :expected_result, :expected_status) do
          'public'   | 'accept metadata request' | :ok
          'internal' | 'reject metadata request' | :unauthorized
          'private'  | 'reject metadata request' | :unauthorized
        end

        with_them do
          before do
            set_visibility(visibility, scope)
          end

          it_behaves_like params[:expected_result], status: params[:expected_status]
        end
      end

      context 'when authenticated' do
        let(:headers) { build_token_auth_header(token.plaintext_token) }

        context 'with guest user' do
          before do
            set_user_role('guest', scope)
          end

          context 'with a non-private project' do
            before do
              set_visibility('internal', scope)
            end

            it_behaves_like 'accept metadata request', status: :ok
          end

          context 'with a private project' do
            before do
              set_visibility('private', scope)
            end

            it_behaves_like 'accept metadata request', status: :ok
          end
        end

        context 'with reporter user' do
          before do
            set_visibility('private', scope)
            set_user_role('reporter', scope)
          end

          it_behaves_like 'accept metadata request', status: :ok
        end

        context 'with authentication methods' do
          %i[oauth personal_access_token job_token deploy_token].each do |auth|
            context "with #{auth}" do
              let(:headers) do
                build_headers_for_auth_type(auth)
              end

              before do
                set_visibility('private', scope)
                set_user_role('reporter', scope)
              end

              it_behaves_like 'accept metadata request', status: :ok
            end
          end
        end
      end
    end
  end

  it_behaves_like 'enforcing job token policies', :read_packages do
    let(:headers) { build_token_auth_header(target_job.token) }
  end

  context 'with a group namespace' do
    it_behaves_like 'handles authentication'
  end

  context 'with a user namespace', if: scope != :project do
    let_it_be(:namespace) { user.namespace }

    it_behaves_like 'handles authentication'
  end

  context 'with a developer' do
    let(:headers) { build_token_auth_header(personal_access_token.token) }

    before do
      group.add_developer(user) if scope == :group
      project.add_developer(user)
    end

    context 'project path with a dot' do
      before do
        project.update!(path: 'foo.bar')
      end

      it_behaves_like 'accept metadata request', status: :ok
    end

    context 'with a job token for a completed job' do
      let(:headers) { build_token_auth_header(job.token) }

      before do
        job.update!(status: :success)
      end

      it_behaves_like 'reject metadata request', status: :unauthorized
    end
  end

  context 'with naming conventions', if: scope == :instance do
    where(:package_name_type, :expected_result, :expected_status) do
      :scoped_naming_convention    | 'accept metadata request'   | :ok
      :scoped_no_naming_convention | 'redirect metadata request' | :redirected
      :unscoped                    | 'redirect metadata request' | :redirected
    end

    with_them do
      include_context 'set package name from package name type'

      before do
        package.update!(name: package_name)
      end

      it_behaves_like params[:expected_result], status: params[:expected_status]
    end
  end

  context 'when the package does not exist' do
    include_context 'dependency proxy helpers context'

    let(:package_name) { 'non-existing-package' }
    let(:headers) do
      user_role ? build_token_auth_header(personal_access_token.token) : {}
    end

    before do
      set_npm_package_requests_forwarding(request_forward, scope)
      set_user_role(user_role, scope) if user_role
      set_visibility(visibility.to_s, scope) if visibility
    end

    context 'with project scope', if: scope == :project do
      where(:request_forward, :visibility, :user_role, :expected_result, :expected_status) do
        true  | :public  | nil       | 'redirect metadata request'            | :redirected
        false | :public  | nil       | 'returning response status with error' | :not_found
        false | :private | nil       | 'reject metadata request'              | :unauthorized
        false | :private | :guest    | 'returning response status with error' | :not_found
        false | :private | :reporter | 'returning response status with error' | :not_found
      end

      with_them do
        it_behaves_like params[:expected_result], status: params[:expected_status]
      end
    end

    context 'with group scope', if: scope == :group do
      where(:request_forward, :visibility, :user_role, :expected_result, :expected_status) do
        true  | :public  | nil    | 'redirect metadata request'            | :redirected
        true  | :public  | nil    | 'redirect metadata request'            | :redirected
        false | :private | nil    | 'reject metadata request'              | :unauthorized
        false | :private | :guest | 'returning response status with error' | :not_found
      end

      with_them do
        it_behaves_like params[:expected_result], status: params[:expected_status]
      end
    end

    context 'with instance scope', if: scope == :instance do
      where(:request_forward, :expected_result, :expected_status) do
        true  | 'redirect metadata request'            | :redirected
        false | 'returning response status with error' | :not_found
      end

      with_them do
        let(:user_role) { nil }
        let(:visibility) { nil }

        it_behaves_like params[:expected_result], status: params[:expected_status]
      end
    end
  end

  def set_user_role(user_role, scope)
    project.send(:"add_#{user_role}", user)
    group.send(:"add_#{user_role}", user) if scope == :group
  end

  def set_visibility(visibility, scope)
    project.update!(visibility: visibility)
    group.update!(visibility: visibility) if scope == :group
  end
end

RSpec.shared_examples 'handling audit request' do |path:, scope: :project|
  using RSpec::Parameterized::TableSyntax

  let(:headers) { {} }
  let(:params) do
    ActiveSupport::Gzip.compress(
      Gitlab::Json.dump({
                          '@gitlab-org/npm-test': ['1.0.6'],
                          'call-bind': ['1.0.2']
                        })
    )
  end

  let(:default_headers) do
    { 'HTTP_CONTENT_ENCODING' => 'gzip', 'CONTENT_TYPE' => 'application/json' }
  end

  subject(:request) { post(url, headers: headers.merge(default_headers), params: params) }

  shared_examples 'accept audit request' do |status:|
    it 'accepts the audit request' do
      subject

      expect(response).to have_gitlab_http_status(status)
      expect(response.media_type).to eq('application/json')
      expect(json_response).to eq([])
    end
  end

  shared_examples 'reject audit request' do |status:|
    it_behaves_like 'returning response status', status
  end

  shared_examples 'reject audit request with error' do |status:|
    it_behaves_like 'returning response status with error', status: status, error: 'Project not found'
  end

  shared_examples 'redirect audit request' do |status:|
    it 'redirects audit request' do
      subject

      expect(response).to have_gitlab_http_status(status)
      expect(response.headers['Location']).to eq("https://registry.npmjs.org/-/npm/v1/security/#{path}")
    end
  end

  context 'authentication' do
    include_context 'dependency proxy helpers context'

    context 'when unauthenticated' do
      let(:auth) { nil }
      let(:headers) { {} }

      it_behaves_like 'reject audit request', status: :unauthorized
    end

    context 'when authenticated' do
      let(:headers) { build_headers_for_auth_type(auth) }

      context 'with request_forward enabled' do
        let(:auth) { :oauth }

        before do
          set_npm_package_requests_forwarding(true, scope)
        end

        it_behaves_like 'redirect audit request', status: :temporary_redirect
      end

      context 'with request_forward disabled' do
        before do
          set_npm_package_requests_forwarding(false, scope)
        end

        context 'with project scope', if: scope == :project do
          before do
            project.update!(visibility: 'private')
          end

          context 'with guest user' do
            let(:auth) { :oauth }

            before do
              project.add_guest(user)
            end

            it_behaves_like 'accept audit request', status: :ok
          end

          it_behaves_like 'enforcing job token policies', :read_packages do
            before_all do
              project.add_reporter(user)
            end

            let(:headers) { build_token_auth_header(target_job.token) }
          end

          %i[oauth personal_access_token job_token deploy_token].each do |auth|
            context "with #{auth}" do
              let(:auth) { auth }

              before do
                project.add_reporter(user)
              end

              it_behaves_like 'accept audit request', status: :ok
            end
          end
        end

        context 'with group or instance scope', if: %i[group instance].include?(scope) do
          %i[oauth personal_access_token job_token deploy_token].each do |auth|
            context "with #{auth}" do
              let(:auth) { auth }

              before do
                project.add_reporter(user)
              end

              it_behaves_like 'reject audit request with error', status: :not_found
            end
          end
        end
      end
    end
  end

  context 'with a developer' do
    let(:headers) { build_token_auth_header(personal_access_token.token) }

    before do
      project.add_developer(user)
    end

    context 'with a job token for a completed job' do
      let(:headers) { build_token_auth_header(job.token) }

      before do
        job.update!(status: :success)
      end

      it_behaves_like 'reject audit request', status: :unauthorized
    end
  end
end

RSpec.shared_examples 'handling get dist tags requests' do |scope: :project|
  using RSpec::Parameterized::TableSyntax

  let_it_be(:package_tag1) { create(:packages_tag, package: package) }
  let_it_be(:package_tag2) { create(:packages_tag, package: package) }

  let(:headers) { {} }

  subject(:request) { get(url, headers: headers) }

  shared_examples 'reject package tags request' do |status:|
    before do
      package.update!(name: package_name)
    end

    it_behaves_like 'returning response status', status
  end

  shared_examples 'handles authentication' do
    context 'when unauthenticated' do
      let(:headers) { {} }

      where(:visibility, :expected_result, :expected_status) do
        'public'   | 'accept package tags request' | :ok
        'private'  | 'reject package tags request' | :unauthorized
        'internal' | 'reject package tags request' | :unauthorized
      end

      with_them do
        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:expected_result], status: params[:expected_status]
      end
    end

    context 'when authenticated' do
      let(:headers) { build_token_auth_header(token.plaintext_token) }

      context 'with guest user' do
        let(:user_role) { :guest }

        before do
          project.add_guest(user)
        end

        context 'when internal' do
          before do
            project.update!(visibility: 'internal')
          end

          it_behaves_like 'accept package tags request', status: :ok
        end

        context 'when private' do
          before do
            project.update!(visibility: 'private')
          end

          it_behaves_like 'accept package tags request', status: :ok
        end
      end

      context 'with reporter user' do
        let(:user_role) { :reporter }

        before do
          project.update!(visibility: 'private')
          project.add_reporter(user)
        end

        context 'with authentication methods' do
          %i[oauth personal_access_token job_token deploy_token].each do |auth|
            context "with #{auth}" do
              let(:auth) { auth }
              let(:headers) do
                build_headers_for_auth_type(auth)
              end

              it_behaves_like 'accept package tags request', status: :ok
            end
          end
        end
      end
    end
  end

  it_behaves_like 'enforcing job token policies', :read_packages do
    let(:headers) { build_token_auth_header(target_job.token) }
  end

  context 'with a group namespace' do
    it_behaves_like 'handles authentication'
  end

  context 'with a user namespace', if: scope != :project do
    let_it_be(:namespace) { user.namespace }

    it_behaves_like 'handles authentication'
  end

  context 'with naming conventions', if: scope == :instance do
    where(:package_name_type, :expected_result, :expected_status) do
      :scoped_naming_convention    | 'accept package tags request'          | :ok
      :scoped_no_naming_convention | 'returning response status with error' | :not_found
      :unscoped                    | 'returning response status with error' | :not_found
    end

    with_them do
      before do
        package.update!(name: set_package_name_from_group_and_package_type(package_name_type, group))
      end

      it_behaves_like params[:expected_result], status: params[:expected_status]
    end
  end

  context 'when the package does not exist' do
    include_context 'dependency proxy helpers context'

    let(:package_name) { 'non-existing-package' }
    let(:headers) do
      user_role ? build_token_auth_header(personal_access_token.token) : {}
    end

    before do
      project.add_role(user, user_role) if user_role
      project.update!(visibility: visibility.to_s) if visibility
    end

    context 'with project scope', if: scope == :project do
      where(:visibility, :user_role, :expected_result, :expected_status) do
        :public   | nil       | 'returning response status with error' | :not_found
        :internal | nil       | 'reject package tags request'          | :unauthorized
        :public   | :guest    | 'returning response status with error' | :not_found
        :internal | :guest    | 'returning response status with error' | :not_found
        :private  | :guest    | 'returning response status with error' | :not_found
        :public   | :reporter | 'returning response status with error' | :not_found
      end

      with_them do
        it_behaves_like params[:expected_result], status: params[:expected_status]
      end
    end

    context 'with group scope', if: scope == :group do
      where(:visibility, :user_role, :expected_result, :expected_status) do
        :public   | nil       | 'returning response status with error' | :not_found
        :internal | nil       | 'reject package tags request'          | :unauthorized
        :public   | :guest    | 'returning response status with error' | :not_found
      end

      with_them do
        it_behaves_like params[:expected_result], status: params[:expected_status]
      end
    end

    context 'with instance scope', if: scope == :instance do
      where(:visibility, :user_role, :expected_result, :expected_status) do
        :public   | nil       | 'returning response status with error' | :not_found
        :internal | nil       | 'returning response status with error' | :not_found
        :public   | :guest    | 'returning response status with error' | :not_found
      end

      with_them do
        it_behaves_like params[:expected_result], status: params[:expected_status]
      end
    end
  end
end

RSpec.shared_examples 'handling create dist tag requests' do |scope: :project|
  include_context 'set package name from package name type'

  let_it_be(:tag_name) { 'test' }

  let(:params) { {} }
  let(:version) { package.version }
  let(:env) { { 'api.request.body': version } }
  let(:headers) { {} }

  shared_examples 'reject create package tag request' do |status:|
    before do
      package.update!(name: package_name) unless package_name == 'non-existing-package'
    end

    it_behaves_like 'returning response status', status
  end

  shared_examples 'handling all conditions' do
    subject(:request) { put(url, env: env, headers: headers) }

    context 'with unauthenticated requests' do
      let(:package_name) { 'unscoped-package' }

      it_behaves_like "reject create package tag request", status: :unauthorized
    end

    it_behaves_like 'handles non-existent packages, for tags create or delete',
      non_guest_role: :developer, action: :create, scope: scope
    it_behaves_like 'handles authenticated requests, for tags create or delete',
      non_guest_role: :developer, action: :create, scope: scope
  end

  context 'with a group namespace' do
    it_behaves_like 'handling all conditions'
  end

  if scope != :project
    context 'with a user namespace' do
      let_it_be(:namespace) { user.namespace }

      it_behaves_like 'handling all conditions'
    end
  end
end

RSpec.shared_examples 'handling delete dist tag requests' do |scope: :project|
  include_context 'set package name from package name type'

  let_it_be(:package_tag) { create(:packages_tag, package: package) }

  let(:tag_name) { package_tag.name }
  let(:headers) { {} }

  shared_examples 'reject delete package tag request' do |status:|
    before do
      package.update!(name: package_name) unless package_name == 'non-existing-package'
    end

    it_behaves_like 'returning response status', status
  end

  shared_examples 'handling all conditions' do
    subject(:request) { delete(url, headers: headers) }

    context 'with unauthenticated requests' do
      let(:package_name) { 'unscoped-package' }

      it_behaves_like "reject delete package tag request", status: :unauthorized
    end

    it_behaves_like 'handles non-existent packages, for tags create or delete', non_guest_role: :maintainer, action: :delete, scope: scope
    it_behaves_like 'handles authenticated requests, for tags create or delete', non_guest_role: :maintainer, action: :delete, scope: scope
  end

  context 'with a group namespace' do
    it_behaves_like 'handling all conditions'
  end

  if scope != :project
    context 'with a user namespace' do
      let_it_be(:namespace) { user.namespace }

      it_behaves_like 'handling all conditions'
    end
  end
end

RSpec.shared_examples 'handles non-existent packages, for tags create or delete' do |non_guest_role:, action:, scope: :project|
  using RSpec::Parameterized::TableSyntax

  let(:package_name) { 'non-existing-package' }
  let(:headers) do
    user_role ? build_token_auth_header(personal_access_token.token) : {}
  end

  before do
    project.add_role(user, user_role)
  end

  context 'with project scope', if: scope == :project do
    where(:user_role, :expected_result, :expected_status) do
      :guest         | "reject #{action} package tag request" | :forbidden
      non_guest_role | "reject #{action} package tag request" | :not_found
    end

    with_them do
      it_behaves_like params[:expected_result], status: params[:expected_status]
    end
  end

  context 'with group scope', if: scope == :group do
    let(:user_role) { :guest }

    it_behaves_like 'returning response status with error', status: :not_found
  end

  context 'with instance scope', if: scope == :instance do
    let(:user_role) { :guest }

    it_behaves_like "reject #{action} package tag request", status: :not_found
  end
end

RSpec.shared_examples 'handles authenticated requests, for tags create or delete' do |non_guest_role:, action:, scope:|
  let(:package_name_type) { :scoped_naming_convention }

  before do
    package.update!(name: set_package_name_from_group_and_package_type(package_name_type, group))
  end

  context 'with guest user' do
    let(:headers) { build_token_auth_header(token.plaintext_token) }
    let(:user_role) { :guest }

    %i[public internal private].each do |visibility|
      context "with #{visibility} project" do
        before do
          project.add_guest(user)
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like "reject #{action} package tag request", status: :forbidden
      end
    end
  end

  context 'with user having required role' do
    let(:headers) { build_token_auth_header(token.plaintext_token) }
    let(:user_role) { non_guest_role }

    before do
      project.send(:"add_#{non_guest_role}", user)
      project.update!(visibility: 'private')
    end

    it_behaves_like 'enforcing job token policies', :admin_packages do
      let(:headers) { build_token_auth_header(target_job.token) }
    end

    context 'with authentication methods' do
      %i[oauth personal_access_token job_token deploy_token].each do |auth|
        context "with #{auth}" do
          let(:auth) { auth }
          let(:headers) do
            build_headers_for_auth_type(auth)
          end

          it_behaves_like "accept #{action} package tag request", status: :ok
        end
      end
    end
  end
end

RSpec.shared_examples 'rejects invalid package names' do
  let(:package_name) { "%0d%0ahttp:/%2fexample.com" }

  it do
    subject

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(Gitlab::Json.parse(response.body)).to eq({ 'error' => 'package_name should be a valid file path' })
  end
end

RSpec.shared_examples 'handling get metadata requests for packages in multiple projects' do
  let_it_be(:project2) { create(:project, :private, namespace: namespace) }
  let_it_be(:package2) do
    create(:npm_package,
      project: project2,
      name: "@#{group.path}/scoped_package",
      version: '1.2.0')
  end

  let(:headers) { build_token_auth_header(personal_access_token.token) }

  subject { get(url, headers: headers) }

  before_all do
    group.add_guest(user)
    project.add_reporter(user)
    project2.add_reporter(user)
  end

  it 'includes all matching package versions in the response' do
    subject

    expect(json_response['versions'].keys).to match_array([package.version, package2.version])
  end

  context 'with the feature flag disabled' do
    before do
      stub_feature_flags(npm_allow_packages_in_multiple_projects: false)
    end

    it 'returns matching package versions from only one project' do
      subject

      expect(json_response['versions'].keys).to match_array([package2.version])
    end
  end

  context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
    before do
      stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
    end

    context 'with limited access to the project with the last package version' do
      before_all do
        project2.add_guest(user)
      end

      it 'includes matching package versions from authorized projects in the response' do
        subject

        expect(json_response['versions'].keys).to contain_exactly(package.version)
      end
    end

    context 'with limited access to the project with the first package version' do
      before do
        project.update!(visibility: 'private')
        project.add_guest(user)
      end

      it 'includes matching package versions from authorized projects in the response' do
        subject

        expect(json_response['versions'].keys).to contain_exactly(package2.version)
      end
    end
  end
end
