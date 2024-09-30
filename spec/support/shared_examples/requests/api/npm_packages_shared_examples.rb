# frozen_string_literal: true

RSpec.shared_examples 'handling get metadata requests' do |scope: :project|
  using RSpec::Parameterized::TableSyntax

  let_it_be(:package_dependency_link1) { create(:packages_dependency_link, package: package, dependency_type: :dependencies) }
  let_it_be(:package_dependency_link2) { create(:packages_dependency_link, package: package, dependency_type: :devDependencies) }
  let_it_be(:package_dependency_link3) { create(:packages_dependency_link, package: package, dependency_type: :bundleDependencies) }
  let_it_be(:package_dependency_link4) { create(:packages_dependency_link, package: package, dependency_type: :peerDependencies) }

  let_it_be(:package_metadatum) { create(:npm_metadatum, package: package) }

  let(:headers) { {} }

  subject { get(url, headers: headers) }

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

            it_behaves_like 'reject metadata request', status: :forbidden
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
                case auth
                when :oauth
                  build_token_auth_header(token.plaintext_token)
                when :personal_access_token
                  build_token_auth_header(personal_access_token.token)
                when :job_token
                  build_token_auth_header(job.token)
                when :deploy_token
                  build_token_auth_header(deploy_token.token)
                else
                  {}
                end
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
        false | :private | :guest    | 'reject metadata request'              | :forbidden
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

  def set_npm_package_requests_forwarding(request_forward, scope)
    if %i[instance group].include?(scope)
      allow_fetch_application_setting(attribute: 'npm_package_requests_forwarding', return_value: request_forward)
    else
      allow_fetch_cascade_application_setting(attribute: 'npm_package_requests_forwarding', return_value: request_forward)
    end
  end

  def set_visibility(visibility, scope)
    project.update!(visibility: visibility)
    group.update!(visibility: visibility) if scope == :group
  end

  def set_user_role(user_role, scope)
    project.send("add_#{user_role}", user)
    group.send("add_#{user_role}", user) if scope == :group
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

  subject { post(url, headers: headers.merge(default_headers), params: params) }

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

  shared_examples 'handling all conditions' do
    include_context 'dependency proxy helpers context'

    where(:auth, :request_forward, :visibility, :user_role, :expected_result, :expected_status) do
      nil                    | true  | :public   | nil        | :reject     | :unauthorized
      nil                    | false | :public   | nil        | :reject     | :unauthorized
      nil                    | true  | :private  | nil        | :reject     | :unauthorized
      nil                    | false | :private  | nil        | :reject     | :unauthorized
      nil                    | true  | :internal | nil        | :reject     | :unauthorized
      nil                    | false | :internal | nil        | :reject     | :unauthorized

      :oauth                 | true  | :public   | :guest     | :redirect   | :temporary_redirect
      :oauth                 | true  | :public   | :reporter  | :redirect   | :temporary_redirect
      :oauth                 | false | :public   | :guest     | :accept     | :ok
      :oauth                 | false | :public   | :reporter  | :accept     | :ok
      :oauth                 | true  | :private  | :reporter  | :redirect   | :temporary_redirect
      :oauth                 | false | :private  | :guest     | :reject     | :forbidden
      :oauth                 | false | :private  | :reporter  | :accept     | :ok
      :oauth                 | true  | :private  | :guest     | :redirect   | :temporary_redirect
      :oauth                 | true  | :internal | :guest     | :redirect   | :temporary_redirect
      :oauth                 | true  | :internal | :reporter  | :redirect   | :temporary_redirect
      :oauth                 | false | :internal | :guest     | :accept     | :ok
      :oauth                 | false | :internal | :reporter  | :accept     | :ok

      :personal_access_token | true  | :public   | :guest     | :redirect   | :temporary_redirect
      :personal_access_token | true  | :public   | :reporter  | :redirect   | :temporary_redirect
      :personal_access_token | false | :public   | :guest     | :accept     | :ok
      :personal_access_token | false | :public   | :reporter  | :accept     | :ok
      :personal_access_token | true  | :private  | :guest     | :redirect   | :temporary_redirect
      :personal_access_token | true  | :private  | :reporter  | :redirect   | :temporary_redirect
      :personal_access_token | false | :private  | :guest     | :reject     | :forbidden # instance might fail
      :personal_access_token | false | :private  | :reporter  | :accept     | :ok
      :personal_access_token | true  | :internal | :guest     | :redirect   | :temporary_redirect
      :personal_access_token | true  | :internal | :reporter  | :redirect   | :temporary_redirect
      :personal_access_token | false | :internal | :guest     | :accept     | :ok
      :personal_access_token | false | :internal | :reporter  | :accept     | :ok

      :job_token             | true  | :public   | :developer | :redirect   | :temporary_redirect
      :job_token             | false | :public   | :developer | :accept     | :ok
      :job_token             | true  | :private  | :developer | :redirect   | :temporary_redirect
      :job_token             | false | :private  | :developer | :accept     | :ok
      :job_token             | true  | :internal | :developer | :redirect   | :temporary_redirect
      :job_token             | false | :internal | :developer | :accept     | :ok

      :deploy_token          | true  | :public   | nil        | :redirect   | :temporary_redirect
      :deploy_token          | false | :public   | nil        | :accept     | :ok
      :deploy_token          | true  | :private  | nil        | :redirect   | :temporary_redirect
      :deploy_token          | false | :private  | nil        | :accept     | :ok
      :deploy_token          | true  | :internal | nil        | :redirect   | :temporary_redirect
      :deploy_token          | false | :internal | nil        | :accept     | :ok
    end

    with_them do
      let(:headers) do
        case auth
        when :oauth
          build_token_auth_header(token.plaintext_token)
        when :personal_access_token
          build_token_auth_header(personal_access_token.token)
        when :job_token
          build_token_auth_header(job.token)
        when :deploy_token
          build_token_auth_header(deploy_token.token)
        else
          {}
        end
      end

      before do
        project.send("add_#{user_role}", user) if user_role
        project.update!(visibility: visibility.to_s)

        if %i[instance group].include?(scope)
          allow_fetch_application_setting(attribute: "npm_package_requests_forwarding", return_value: request_forward)
        else
          allow_fetch_cascade_application_setting(attribute: "npm_package_requests_forwarding", return_value: request_forward)
        end
      end

      example_name = "#{params[:expected_result]} audit request"
      status = params[:expected_status]

      if %i[instance group].include?(scope) && params[:expected_status] != :unauthorized
        if params[:request_forward]
          example_name = 'redirect audit request'
          status = :temporary_redirect
        else
          example_name = 'reject audit request with error'
          status = :not_found
        end
      end

      it_behaves_like example_name, status: status
    end
  end

  context 'with a group namespace' do
    it_behaves_like 'handling all conditions'
  end

  context 'with a developer' do
    let(:headers) { build_token_auth_header(personal_access_token.token) }

    before do
      project.add_developer(user)
    end

    context 'with a job token' do
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
  include_context 'set package name from package name type'

  let_it_be(:package_tag1) { create(:packages_tag, package: package) }
  let_it_be(:package_tag2) { create(:packages_tag, package: package) }

  let(:headers) { {} }

  subject { get(url, headers: headers) }

  shared_examples 'reject package tags request' do |status:|
    before do
      package.update!(name: package_name) unless package_name == 'non-existing-package'
    end

    it_behaves_like 'returning response status', status
  end

  shared_examples 'handling all conditions' do
    where(:auth, :package_name_type, :visibility, :user_role, :expected_result, :expected_status) do
      nil                    | :scoped_naming_convention    | :public   | nil       | :accept   | :ok
      nil                    | :scoped_no_naming_convention | :public   | nil       | :accept   | :ok
      nil                    | :unscoped                    | :public   | nil       | :accept   | :ok
      nil                    | :non_existing                | :public   | nil       | :reject   | :not_found
      nil                    | :scoped_naming_convention    | :private  | nil       | :reject   | :unauthorized
      nil                    | :scoped_no_naming_convention | :private  | nil       | :reject   | :unauthorized
      nil                    | :unscoped                    | :private  | nil       | :reject   | :unauthorized
      nil                    | :non_existing                | :private  | nil       | :reject   | :unauthorized
      nil                    | :scoped_naming_convention    | :internal | nil       | :reject   | :unauthorized
      nil                    | :scoped_no_naming_convention | :internal | nil       | :reject   | :unauthorized
      nil                    | :unscoped                    | :internal | nil       | :reject   | :unauthorized
      nil                    | :non_existing                | :internal | nil       | :reject   | :unauthorized

      :oauth                 | :scoped_naming_convention    | :public   | :guest    | :accept   | :ok
      :oauth                 | :scoped_naming_convention    | :public   | :reporter | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | :public   | :guest    | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | :public   | :reporter | :accept   | :ok
      :oauth                 | :unscoped                    | :public   | :guest    | :accept   | :ok
      :oauth                 | :unscoped                    | :public   | :reporter | :accept   | :ok
      :oauth                 | :non_existing                | :public   | :guest    | :reject   | :not_found
      :oauth                 | :non_existing                | :public   | :reporter | :reject   | :not_found
      :oauth                 | :scoped_naming_convention    | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :scoped_naming_convention    | :private  | :reporter | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :scoped_no_naming_convention | :private  | :reporter | :accept   | :ok
      :oauth                 | :unscoped                    | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :unscoped                    | :private  | :reporter | :accept   | :ok
      :oauth                 | :non_existing                | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :non_existing                | :private  | :reporter | :reject   | :not_found
      :oauth                 | :scoped_naming_convention    | :internal | :guest    | :accept   | :ok
      :oauth                 | :scoped_naming_convention    | :internal | :reporter | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | :internal | :guest    | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | :internal | :reporter | :accept   | :ok
      :oauth                 | :unscoped                    | :internal | :guest    | :accept   | :ok
      :oauth                 | :unscoped                    | :internal | :reporter | :accept   | :ok
      :oauth                 | :non_existing                | :internal | :guest    | :reject   | :not_found
      :oauth                 | :non_existing                | :internal | :reporter | :reject   | :not_found

      :personal_access_token | :scoped_naming_convention    | :public   | :guest    | :accept   | :ok
      :personal_access_token | :scoped_naming_convention    | :public   | :reporter | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | :public   | :guest    | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | :public   | :reporter | :accept   | :ok
      :personal_access_token | :unscoped                    | :public   | :guest    | :accept   | :ok
      :personal_access_token | :unscoped                    | :public   | :reporter | :accept   | :ok
      :personal_access_token | :non_existing                | :public   | :guest    | :reject   | :not_found
      :personal_access_token | :non_existing                | :public   | :reporter | :reject   | :not_found
      :personal_access_token | :scoped_naming_convention    | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :scoped_naming_convention    | :private  | :reporter | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :scoped_no_naming_convention | :private  | :reporter | :accept   | :ok
      :personal_access_token | :unscoped                    | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :unscoped                    | :private  | :reporter | :accept   | :ok
      :personal_access_token | :non_existing                | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :non_existing                | :private  | :reporter | :reject   | :not_found
      :personal_access_token | :scoped_naming_convention    | :internal | :guest    | :accept   | :ok
      :personal_access_token | :scoped_naming_convention    | :internal | :reporter | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | :internal | :guest    | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | :internal | :reporter | :accept   | :ok
      :personal_access_token | :unscoped                    | :internal | :guest    | :accept   | :ok
      :personal_access_token | :unscoped                    | :internal | :reporter | :accept   | :ok
      :personal_access_token | :non_existing                | :internal | :guest    | :reject   | :not_found
      :personal_access_token | :non_existing                | :internal | :reporter | :reject   | :not_found

      :job_token             | :scoped_naming_convention    | :public   | :developer | :accept   | :ok
      :job_token             | :scoped_no_naming_convention | :public   | :developer | :accept   | :ok
      :job_token             | :unscoped                    | :public   | :developer | :accept   | :ok
      :job_token             | :non_existing                | :public   | :developer | :reject   | :not_found
      :job_token             | :scoped_naming_convention    | :private  | :developer | :accept   | :ok
      :job_token             | :scoped_no_naming_convention | :private  | :developer | :accept   | :ok
      :job_token             | :unscoped                    | :private  | :developer | :accept   | :ok
      :job_token             | :non_existing                | :private  | :developer | :reject   | :not_found
      :job_token             | :scoped_naming_convention    | :internal | :developer | :accept   | :ok
      :job_token             | :scoped_no_naming_convention | :internal | :developer | :accept   | :ok
      :job_token             | :unscoped                    | :internal | :developer | :accept   | :ok
      :job_token             | :non_existing                | :internal | :developer | :reject   | :not_found

      :deploy_token          | :scoped_naming_convention    | :public   | nil        | :accept   | :ok
      :deploy_token          | :scoped_no_naming_convention | :public   | nil        | :accept   | :ok
      :deploy_token          | :unscoped                    | :public   | nil        | :accept   | :ok
      :deploy_token          | :non_existing                | :public   | nil        | :reject   | :not_found
      :deploy_token          | :scoped_naming_convention    | :private  | nil        | :accept   | :ok
      :deploy_token          | :scoped_no_naming_convention | :private  | nil        | :accept   | :ok
      :deploy_token          | :unscoped                    | :private  | nil        | :accept   | :ok
      :deploy_token          | :non_existing                | :private  | nil        | :reject   | :not_found
      :deploy_token          | :scoped_naming_convention    | :internal | nil        | :accept   | :ok
      :deploy_token          | :scoped_no_naming_convention | :internal | nil        | :accept   | :ok
      :deploy_token          | :unscoped                    | :internal | nil        | :accept   | :ok
      :deploy_token          | :non_existing                | :internal | nil        | :reject   | :not_found
    end

    with_them do
      let(:headers) do
        case auth
        when :oauth
          build_token_auth_header(token.plaintext_token)
        when :personal_access_token
          build_token_auth_header(personal_access_token.token)
        when :job_token
          build_token_auth_header(job.token)
        when :deploy_token
          build_token_auth_header(deploy_token.token)
        else
          {}
        end
      end

      subject { get(url, headers: headers) }

      before do
        project.send("add_#{user_role}", user) if user_role
        project.update!(visibility: visibility.to_s)
      end

      example_name = "#{params[:expected_result]} package tags request"
      status = params[:expected_status]

      if (scope == :instance && params[:package_name_type] != :scoped_naming_convention) || (scope == :group && params[:package_name_type] == :non_existing)
        status = :not_found
      end

      # Check the error message for :not_found
      example_name = 'returning response status with error' if status == :not_found

      it_behaves_like example_name, status: status
    end
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
    subject { put(url, env: env, headers: headers) }

    it_behaves_like 'handling different package names, visibilities and user roles for tags create or delete', action: :create, scope: scope
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
    subject { delete(url, headers: headers) }

    it_behaves_like 'handling different package names, visibilities and user roles for tags create or delete', action: :delete, scope: scope
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

RSpec.shared_examples 'handling different package names, visibilities and user roles for tags create or delete' do |action:, scope: :project|
  using RSpec::Parameterized::TableSyntax

  role = action == :create ? :developer : :maintainer

  where(:auth, :package_name_type, :visibility, :user_role, :expected_result, :expected_status) do
    nil                    | :scoped_naming_convention    | :public   | nil    | :reject   | :unauthorized
    nil                    | :scoped_no_naming_convention | :public   | nil    | :reject   | :unauthorized
    nil                    | :unscoped                    | :public   | nil    | :reject   | :unauthorized
    nil                    | :non_existing                | :public   | nil    | :reject   | :unauthorized
    nil                    | :scoped_naming_convention    | :private  | nil    | :reject   | :unauthorized
    nil                    | :scoped_no_naming_convention | :private  | nil    | :reject   | :unauthorized
    nil                    | :unscoped                    | :private  | nil    | :reject   | :unauthorized
    nil                    | :non_existing                | :private  | nil    | :reject   | :unauthorized
    nil                    | :scoped_naming_convention    | :internal | nil    | :reject   | :unauthorized
    nil                    | :scoped_no_naming_convention | :internal | nil    | :reject   | :unauthorized
    nil                    | :unscoped                    | :internal | nil    | :reject   | :unauthorized
    nil                    | :non_existing                | :internal | nil    | :reject   | :unauthorized

    :oauth                 | :scoped_naming_convention    | :public   | :guest | :reject   | :forbidden
    :oauth                 | :scoped_naming_convention    | :public   | role   | :accept   | :ok
    :oauth                 | :scoped_no_naming_convention | :public   | :guest | :reject   | :forbidden
    :oauth                 | :scoped_no_naming_convention | :public   | role   | :accept   | :ok
    :oauth                 | :unscoped                    | :public   | :guest | :reject   | :forbidden
    :oauth                 | :unscoped                    | :public   | role   | :accept   | :ok
    :oauth                 | :non_existing                | :public   | :guest | :reject   | :forbidden
    :oauth                 | :non_existing                | :public   | role   | :reject   | :not_found
    :oauth                 | :scoped_naming_convention    | :private  | :guest | :reject   | :forbidden
    :oauth                 | :scoped_naming_convention    | :private  | role   | :accept   | :ok
    :oauth                 | :scoped_no_naming_convention | :private  | :guest | :reject   | :forbidden
    :oauth                 | :scoped_no_naming_convention | :private  | role   | :accept   | :ok
    :oauth                 | :unscoped                    | :private  | :guest | :reject   | :forbidden
    :oauth                 | :unscoped                    | :private  | role   | :accept   | :ok
    :oauth                 | :non_existing                | :private  | :guest | :reject   | :forbidden
    :oauth                 | :non_existing                | :private  | role   | :reject   | :not_found
    :oauth                 | :scoped_naming_convention    | :internal | :guest | :reject   | :forbidden
    :oauth                 | :scoped_naming_convention    | :internal | role   | :accept   | :ok
    :oauth                 | :scoped_no_naming_convention | :internal | :guest | :reject   | :forbidden
    :oauth                 | :scoped_no_naming_convention | :internal | role   | :accept   | :ok
    :oauth                 | :unscoped                    | :internal | :guest | :reject   | :forbidden
    :oauth                 | :unscoped                    | :internal | role   | :accept   | :ok
    :oauth                 | :non_existing                | :internal | :guest | :reject   | :forbidden
    :oauth                 | :non_existing                | :internal | role   | :reject   | :not_found

    :personal_access_token | :scoped_naming_convention    | :public   | :guest | :reject   | :forbidden
    :personal_access_token | :scoped_naming_convention    | :public   | role   | :accept   | :ok
    :personal_access_token | :scoped_no_naming_convention | :public   | :guest | :reject   | :forbidden
    :personal_access_token | :scoped_no_naming_convention | :public   | role   | :accept   | :ok
    :personal_access_token | :unscoped                    | :public   | :guest | :reject   | :forbidden
    :personal_access_token | :unscoped                    | :public   | role   | :accept   | :ok
    :personal_access_token | :non_existing                | :public   | :guest | :reject   | :forbidden
    :personal_access_token | :non_existing                | :public   | role   | :reject   | :not_found
    :personal_access_token | :scoped_naming_convention    | :private  | :guest | :reject   | :forbidden
    :personal_access_token | :scoped_naming_convention    | :private  | role   | :accept   | :ok
    :personal_access_token | :scoped_no_naming_convention | :private  | :guest | :reject   | :forbidden
    :personal_access_token | :scoped_no_naming_convention | :private  | role   | :accept   | :ok
    :personal_access_token | :unscoped                    | :private  | :guest | :reject   | :forbidden
    :personal_access_token | :unscoped                    | :private  | role   | :accept   | :ok
    :personal_access_token | :non_existing                | :private  | :guest | :reject   | :forbidden
    :personal_access_token | :non_existing                | :private  | role   | :reject   | :not_found
    :personal_access_token | :scoped_naming_convention    | :internal | :guest | :reject   | :forbidden
    :personal_access_token | :scoped_naming_convention    | :internal | role   | :accept   | :ok
    :personal_access_token | :scoped_no_naming_convention | :internal | :guest | :reject   | :forbidden
    :personal_access_token | :scoped_no_naming_convention | :internal | role   | :accept   | :ok
    :personal_access_token | :unscoped                    | :internal | :guest | :reject   | :forbidden
    :personal_access_token | :unscoped                    | :internal | role   | :accept   | :ok
    :personal_access_token | :non_existing                | :internal | :guest | :reject   | :forbidden
    :personal_access_token | :non_existing                | :internal | role   | :reject   | :not_found

    :job_token             | :scoped_naming_convention    | :public   | role   | :accept   | :ok
    :job_token             | :scoped_no_naming_convention | :public   | role   | :accept   | :ok
    :job_token             | :unscoped                    | :public   | role   | :accept   | :ok
    :job_token             | :non_existing                | :public   | role   | :reject   | :not_found
    :job_token             | :scoped_naming_convention    | :private  | role   | :accept   | :ok
    :job_token             | :scoped_no_naming_convention | :private  | role   | :accept   | :ok
    :job_token             | :unscoped                    | :private  | role   | :accept   | :ok
    :job_token             | :non_existing                | :private  | role   | :reject   | :not_found
    :job_token             | :scoped_naming_convention    | :internal | role   | :accept   | :ok
    :job_token             | :scoped_no_naming_convention | :internal | role   | :accept   | :ok
    :job_token             | :unscoped                    | :internal | role   | :accept   | :ok
    :job_token             | :non_existing                | :internal | role   | :reject   | :not_found

    :deploy_token          | :scoped_naming_convention    | :public   | nil    | :accept   | :ok
    :deploy_token          | :scoped_no_naming_convention | :public   | nil    | :accept   | :ok
    :deploy_token          | :unscoped                    | :public   | nil    | :accept   | :ok
    :deploy_token          | :non_existing                | :public   | nil    | :reject   | :not_found
    :deploy_token          | :scoped_naming_convention    | :private  | nil    | :accept   | :ok
    :deploy_token          | :scoped_no_naming_convention | :private  | nil    | :accept   | :ok
    :deploy_token          | :unscoped                    | :private  | nil    | :accept   | :ok
    :deploy_token          | :non_existing                | :private  | nil    | :reject   | :not_found
    :deploy_token          | :scoped_naming_convention    | :internal | nil    | :accept   | :ok
    :deploy_token          | :scoped_no_naming_convention | :internal | nil    | :accept   | :ok
    :deploy_token          | :unscoped                    | :internal | nil    | :accept   | :ok
    :deploy_token          | :non_existing                | :internal | nil    | :reject   | :not_found
  end

  with_them do
    let(:headers) do
      case auth
      when :oauth
        build_token_auth_header(token.plaintext_token)
      when :personal_access_token
        build_token_auth_header(personal_access_token.token)
      when :job_token
        build_token_auth_header(job.token)
      when :deploy_token
        build_token_auth_header(deploy_token.token)
      else
        {}
      end
    end

    before do
      project.send("add_#{user_role}", user) if user_role
      project.update!(visibility: visibility.to_s)
    end

    example_name = "#{params[:expected_result]} #{action} package tag request"
    status = params[:expected_status]

    if scope == :instance && params[:package_name_type] != :scoped_naming_convention
      example_name = "reject #{action} package tag request"
      # Due to #authenticate_non_get, anonymous requests on private resources
      # are rejected with unauthorized status
      status = params[:auth].nil? ? :unauthorized : :not_found
    end

    status = :not_found if scope == :group && params[:package_name_type] == :non_existing && params[:auth].present?

    # Check the error message for :not_found
    example_name = 'returning response status with error' if status == :not_found

    it_behaves_like example_name, status: status
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
  let_it_be(:project2) { create(:project, namespace: namespace) }
  let_it_be(:package2) do
    create(:npm_package,
      project: project2,
      name: "@#{group.path}/scoped_package",
      version: '1.2.0')
  end

  let(:headers) { build_token_auth_header(personal_access_token.token) }

  subject { get(url, headers: headers) }

  before_all do
    project.update!(visibility: 'private')

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
      project.add_guest(user)
    end

    it 'includes matching package versions from authorized projects in the response' do
      subject

      expect(json_response['versions'].keys).to contain_exactly(package2.version)
    end
  end
end
