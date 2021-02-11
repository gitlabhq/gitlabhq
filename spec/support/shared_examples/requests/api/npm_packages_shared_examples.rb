# frozen_string_literal: true

RSpec.shared_examples 'handling get metadata requests' do |scope: :project|
  using RSpec::Parameterized::TableSyntax

  let_it_be(:package_dependency_link1) { create(:packages_dependency_link, package: package, dependency_type: :dependencies) }
  let_it_be(:package_dependency_link2) { create(:packages_dependency_link, package: package, dependency_type: :devDependencies) }
  let_it_be(:package_dependency_link3) { create(:packages_dependency_link, package: package, dependency_type: :bundleDependencies) }
  let_it_be(:package_dependency_link4) { create(:packages_dependency_link, package: package, dependency_type: :peerDependencies) }

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
      ::Packages::Npm::PackagePresenter::NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
        expect(json_response.dig('versions', package.version, dependency_type.to_s)).to be_any
      end
      expect(json_response['dist-tags']).to match_schema('public_api/v4/packages/npm_package_tags')
    end
  end

  shared_examples 'reject metadata request' do |status:|
    it 'rejects the metadata request' do
      subject

      expect(response).to have_gitlab_http_status(status)
    end
  end

  shared_examples 'redirect metadata request' do |status:|
    it 'redirects metadata request' do
      subject

      expect(response).to have_gitlab_http_status(:found)
      expect(response.headers['Location']).to eq("https://registry.npmjs.org/#{package_name}")
    end
  end

  where(:auth, :package_name_type, :request_forward, :visibility, :user_role, :expected_result, :expected_status) do
    nil                    | :scoped_naming_convention    | true  | 'PUBLIC'   | nil        | :accept   | :ok
    nil                    | :scoped_naming_convention    | false | 'PUBLIC'   | nil        | :accept   | :ok
    nil                    | :non_existing                | true  | 'PUBLIC'   | nil        | :redirect | :redirected
    nil                    | :non_existing                | false | 'PUBLIC'   | nil        | :reject   | :not_found
    nil                    | :scoped_naming_convention    | true  | 'PRIVATE'  | nil        | :reject   | :not_found
    nil                    | :scoped_naming_convention    | false | 'PRIVATE'  | nil        | :reject   | :not_found
    nil                    | :non_existing                | true  | 'PRIVATE'  | nil        | :redirect | :redirected
    nil                    | :non_existing                | false | 'PRIVATE'  | nil        | :reject   | :not_found
    nil                    | :scoped_naming_convention    | true  | 'INTERNAL' | nil        | :reject   | :not_found
    nil                    | :scoped_naming_convention    | false | 'INTERNAL' | nil        | :reject   | :not_found
    nil                    | :non_existing                | true  | 'INTERNAL' | nil        | :redirect | :redirected
    nil                    | :non_existing                | false | 'INTERNAL' | nil        | :reject   | :not_found

    :oauth                 | :scoped_naming_convention    | true  | 'PUBLIC'   | :guest     | :accept   | :ok
    :oauth                 | :scoped_naming_convention    | true  | 'PUBLIC'   | :reporter  | :accept   | :ok
    :oauth                 | :scoped_naming_convention    | false | 'PUBLIC'   | :guest     | :accept   | :ok
    :oauth                 | :scoped_naming_convention    | false | 'PUBLIC'   | :reporter  | :accept   | :ok
    :oauth                 | :non_existing                | true  | 'PUBLIC'   | :guest     | :redirect | :redirected
    :oauth                 | :non_existing                | true  | 'PUBLIC'   | :reporter  | :redirect | :redirected
    :oauth                 | :non_existing                | false | 'PUBLIC'   | :guest     | :reject   | :not_found
    :oauth                 | :non_existing                | false | 'PUBLIC'   | :reporter  | :reject   | :not_found
    :oauth                 | :scoped_naming_convention    | true  | 'PRIVATE'  | :guest     | :reject   | :forbidden
    :oauth                 | :scoped_naming_convention    | true  | 'PRIVATE'  | :reporter  | :accept   | :ok
    :oauth                 | :scoped_naming_convention    | false | 'PRIVATE'  | :guest     | :reject   | :forbidden
    :oauth                 | :scoped_naming_convention    | false | 'PRIVATE'  | :reporter  | :accept   | :ok
    :oauth                 | :non_existing                | true  | 'PRIVATE'  | :guest     | :redirect | :redirected
    :oauth                 | :non_existing                | true  | 'PRIVATE'  | :reporter  | :redirect | :redirected
    :oauth                 | :non_existing                | false | 'PRIVATE'  | :guest     | :reject   | :forbidden
    :oauth                 | :non_existing                | false | 'PRIVATE'  | :reporter  | :reject   | :not_found
    :oauth                 | :scoped_naming_convention    | true  | 'INTERNAL' | :guest     | :accept   | :ok
    :oauth                 | :scoped_naming_convention    | true  | 'INTERNAL' | :reporter  | :accept   | :ok
    :oauth                 | :scoped_naming_convention    | false | 'INTERNAL' | :guest     | :accept   | :ok
    :oauth                 | :scoped_naming_convention    | false | 'INTERNAL' | :reporter  | :accept   | :ok
    :oauth                 | :non_existing                | true  | 'INTERNAL' | :guest     | :redirect | :redirected
    :oauth                 | :non_existing                | true  | 'INTERNAL' | :reporter  | :redirect | :redirected
    :oauth                 | :non_existing                | false | 'INTERNAL' | :guest     | :reject   | :not_found
    :oauth                 | :non_existing                | false | 'INTERNAL' | :reporter  | :reject   | :not_found

    :personal_access_token | :scoped_naming_convention    | true  | 'PUBLIC'   | :guest     | :accept   | :ok
    :personal_access_token | :scoped_naming_convention    | true  | 'PUBLIC'   | :reporter  | :accept   | :ok
    :personal_access_token | :scoped_naming_convention    | false | 'PUBLIC'   | :guest     | :accept   | :ok
    :personal_access_token | :scoped_naming_convention    | false | 'PUBLIC'   | :reporter  | :accept   | :ok
    :personal_access_token | :non_existing                | true  | 'PUBLIC'   | :guest     | :redirect | :redirected
    :personal_access_token | :non_existing                | true  | 'PUBLIC'   | :reporter  | :redirect | :redirected
    :personal_access_token | :non_existing                | false | 'PUBLIC'   | :guest     | :reject   | :not_found
    :personal_access_token | :non_existing                | false | 'PUBLIC'   | :reporter  | :reject   | :not_found
    :personal_access_token | :scoped_naming_convention    | true  | 'PRIVATE'  | :guest     | :reject   | :forbidden
    :personal_access_token | :scoped_naming_convention    | true  | 'PRIVATE'  | :reporter  | :accept   | :ok
    :personal_access_token | :scoped_naming_convention    | false | 'PRIVATE'  | :guest     | :reject   | :forbidden
    :personal_access_token | :scoped_naming_convention    | false | 'PRIVATE'  | :reporter  | :accept   | :ok
    :personal_access_token | :non_existing                | true  | 'PRIVATE'  | :guest     | :redirect | :redirected
    :personal_access_token | :non_existing                | true  | 'PRIVATE'  | :reporter  | :redirect | :redirected
    :personal_access_token | :non_existing                | false | 'PRIVATE'  | :guest     | :reject   | :forbidden
    :personal_access_token | :non_existing                | false | 'PRIVATE'  | :reporter  | :reject   | :not_found
    :personal_access_token | :scoped_naming_convention    | true  | 'INTERNAL' | :guest     | :accept   | :ok
    :personal_access_token | :scoped_naming_convention    | true  | 'INTERNAL' | :reporter  | :accept   | :ok
    :personal_access_token | :scoped_naming_convention    | false | 'INTERNAL' | :guest     | :accept   | :ok
    :personal_access_token | :scoped_naming_convention    | false | 'INTERNAL' | :reporter  | :accept   | :ok
    :personal_access_token | :non_existing                | true  | 'INTERNAL' | :guest     | :redirect | :redirected
    :personal_access_token | :non_existing                | true  | 'INTERNAL' | :reporter  | :redirect | :redirected
    :personal_access_token | :non_existing                | false | 'INTERNAL' | :guest     | :reject   | :not_found
    :personal_access_token | :non_existing                | false | 'INTERNAL' | :reporter  | :reject   | :not_found

    :job_token             | :scoped_naming_convention    | true  | 'PUBLIC'   | :developer | :accept   | :ok
    :job_token             | :scoped_naming_convention    | false | 'PUBLIC'   | :developer | :accept   | :ok
    :job_token             | :non_existing                | true  | 'PUBLIC'   | :developer | :redirect | :redirected
    :job_token             | :non_existing                | false | 'PUBLIC'   | :developer | :reject   | :not_found
    :job_token             | :scoped_naming_convention    | true  | 'PRIVATE'  | :developer | :accept   | :ok
    :job_token             | :scoped_naming_convention    | false | 'PRIVATE'  | :developer | :accept   | :ok
    :job_token             | :non_existing                | true  | 'PRIVATE'  | :developer | :redirect | :redirected
    :job_token             | :non_existing                | false | 'PRIVATE'  | :developer | :reject   | :not_found
    :job_token             | :scoped_naming_convention    | true  | 'INTERNAL' | :developer | :accept   | :ok
    :job_token             | :scoped_naming_convention    | false | 'INTERNAL' | :developer | :accept   | :ok
    :job_token             | :non_existing                | true  | 'INTERNAL' | :developer | :redirect | :redirected
    :job_token             | :non_existing                | false | 'INTERNAL' | :developer | :reject   | :not_found

    :deploy_token          | :scoped_naming_convention    | true  | 'PUBLIC'   | nil        | :accept   | :ok
    :deploy_token          | :scoped_naming_convention    | false | 'PUBLIC'   | nil        | :accept   | :ok
    :deploy_token          | :non_existing                | true  | 'PUBLIC'   | nil        | :redirect | :redirected
    :deploy_token          | :non_existing                | false | 'PUBLIC'   | nil        | :reject   | :not_found
    :deploy_token          | :scoped_naming_convention    | true  | 'PRIVATE'  | nil        | :accept   | :ok
    :deploy_token          | :scoped_naming_convention    | false | 'PRIVATE'  | nil        | :accept   | :ok
    :deploy_token          | :non_existing                | true  | 'PRIVATE'  | nil        | :redirect | :redirected
    :deploy_token          | :non_existing                | false | 'PRIVATE'  | nil        | :reject   | :not_found
    :deploy_token          | :scoped_naming_convention    | true  | 'INTERNAL' | nil        | :accept   | :ok
    :deploy_token          | :scoped_naming_convention    | false | 'INTERNAL' | nil        | :accept   | :ok
    :deploy_token          | :non_existing                | true  | 'INTERNAL' | nil        | :redirect | :redirected
    :deploy_token          | :non_existing                | false | 'INTERNAL' | nil        | :reject   | :not_found
  end

  with_them do
    include_context 'set package name from package name type'

    let(:headers) do
      case auth
      when :oauth
        build_token_auth_header(token.token)
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
      project.update!(visibility: Gitlab::VisibilityLevel.const_get(visibility, false))
      package.update!(name: package_name) unless package_name == 'non-existing-package'
      stub_application_setting(npm_package_requests_forwarding: request_forward)
    end

    example_name = "#{params[:expected_result]} metadata request"
    status = params[:expected_status]

    if scope == :instance && params[:package_name_type] != :scoped_naming_convention
      if params[:request_forward]
        example_name = 'redirect metadata request'
        status = :redirected
      else
        example_name = 'reject metadata request'
        status = :not_found
      end
    end

    it_behaves_like example_name, status: status
  end

  context 'with a developer' do
    let(:headers) { build_token_auth_header(personal_access_token.token) }

    before do
      project.add_developer(user)
    end

    context 'project path with a dot' do
      before do
        project.update!(path: 'foo.bar')
      end

      it_behaves_like 'accept metadata request', status: :ok
    end

    context 'with a job token' do
      let(:headers) { build_token_auth_header(job.token) }

      before do
        job.update!(status: :success)
      end

      it_behaves_like 'reject metadata request', status: :unauthorized
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

  shared_examples 'handling different package names, visibilities and user roles' do
    where(:package_name_type, :visibility, :user_role, :expected_result, :expected_status) do
      :scoped_naming_convention    | 'PUBLIC'   | :anonymous | :accept | :ok
      :scoped_naming_convention    | 'PUBLIC'   | :guest     | :accept | :ok
      :scoped_naming_convention    | 'PUBLIC'   | :reporter  | :accept | :ok
      :non_existing                | 'PUBLIC'   | :anonymous | :reject | :not_found
      :non_existing                | 'PUBLIC'   | :guest     | :reject | :not_found
      :non_existing                | 'PUBLIC'   | :reporter  | :reject | :not_found

      :scoped_naming_convention    | 'PRIVATE'  | :anonymous | :reject | :not_found
      :scoped_naming_convention    | 'PRIVATE'  | :guest     | :reject | :forbidden
      :scoped_naming_convention    | 'PRIVATE'  | :reporter  | :accept | :ok
      :non_existing                | 'PRIVATE'  | :anonymous | :reject | :not_found
      :non_existing                | 'PRIVATE'  | :guest     | :reject | :forbidden
      :non_existing                | 'PRIVATE'  | :reporter  | :reject | :not_found

      :scoped_naming_convention    | 'INTERNAL' | :anonymous | :reject | :not_found
      :scoped_naming_convention    | 'INTERNAL' | :guest     | :accept | :ok
      :scoped_naming_convention    | 'INTERNAL' | :reporter  | :accept | :ok
      :non_existing                | 'INTERNAL' | :anonymous | :reject | :not_found
      :non_existing                | 'INTERNAL' | :guest     | :reject | :not_found
      :non_existing                | 'INTERNAL' | :reporter  | :reject | :not_found
    end

    with_them do
      let(:anonymous) { user_role == :anonymous }

      subject { get(url, headers: anonymous ? {} : headers) }

      before do
        project.send("add_#{user_role}", user) unless anonymous
        project.update!(visibility: Gitlab::VisibilityLevel.const_get(visibility, false))
      end

      example_name = "#{params[:expected_result]} package tags request"
      status = params[:expected_status]

      if scope == :instance && params[:package_name_type] != :scoped_naming_convention
        example_name = 'reject package tags request'
        status = :not_found
      end

      it_behaves_like example_name, status: status
    end
  end

  context 'with oauth token' do
    let(:headers) { build_token_auth_header(token.token) }

    it_behaves_like 'handling different package names, visibilities and user roles'
  end

  context 'with personal access token' do
    let(:headers) { build_token_auth_header(personal_access_token.token) }

    it_behaves_like 'handling different package names, visibilities and user roles'
  end
end

RSpec.shared_examples 'handling create dist tag requests' do |scope: :project|
  using RSpec::Parameterized::TableSyntax
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

  shared_examples 'handling different package names, visibilities and user roles' do
    where(:package_name_type, :visibility, :user_role, :expected_result, :expected_status) do
      :scoped_naming_convention    | 'PUBLIC'   | :anonymous | :reject | :forbidden
      :scoped_naming_convention    | 'PUBLIC'   | :guest     | :reject | :forbidden
      :scoped_naming_convention    | 'PUBLIC'   | :developer | :accept | :ok
      :non_existing                | 'PUBLIC'   | :anonymous | :reject | :forbidden
      :non_existing                | 'PUBLIC'   | :guest     | :reject | :forbidden
      :non_existing                | 'PUBLIC'   | :developer | :reject | :not_found

      :scoped_naming_convention    | 'PRIVATE'  | :anonymous | :reject | :not_found
      :scoped_naming_convention    | 'PRIVATE'  | :guest     | :reject | :forbidden
      :scoped_naming_convention    | 'PRIVATE'  | :developer | :accept | :ok
      :non_existing                | 'PRIVATE'  | :anonymous | :reject | :not_found
      :non_existing                | 'PRIVATE'  | :guest     | :reject | :forbidden
      :non_existing                | 'PRIVATE'  | :developer | :reject | :not_found

      :scoped_naming_convention    | 'INTERNAL' | :anonymous | :reject | :forbidden
      :scoped_naming_convention    | 'INTERNAL' | :guest     | :reject | :forbidden
      :scoped_naming_convention    | 'INTERNAL' | :developer | :accept | :ok
      :non_existing                | 'INTERNAL' | :anonymous | :reject | :forbidden
      :non_existing                | 'INTERNAL' | :guest     | :reject | :forbidden
      :non_existing                | 'INTERNAL' | :developer | :reject | :not_found
    end

    with_them do
      let(:anonymous) { user_role == :anonymous }

      subject { put(url, env: env, headers: headers) }

      before do
        project.send("add_#{user_role}", user) unless anonymous
        project.update!(visibility: Gitlab::VisibilityLevel.const_get(visibility, false))
      end

      example_name = "#{params[:expected_result]} create package tag request"
      status = params[:expected_status]

      if scope == :instance && params[:package_name_type] != :scoped_naming_convention
        example_name = 'reject create package tag request'
        status = :not_found
      end

      it_behaves_like example_name, status: status
    end
  end

  context 'with oauth token' do
    let(:headers) { build_token_auth_header(token.token) }

    it_behaves_like 'handling different package names, visibilities and user roles'
  end

  context 'with personal access token' do
    let(:headers) { build_token_auth_header(personal_access_token.token) }

    it_behaves_like 'handling different package names, visibilities and user roles'
  end
end

RSpec.shared_examples 'handling delete dist tag requests' do |scope: :project|
  using RSpec::Parameterized::TableSyntax
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

  shared_examples 'handling different package names, visibilities and user roles' do
    where(:package_name_type, :visibility, :user_role, :expected_result, :expected_status) do
      :scoped_naming_convention    | 'PUBLIC'   | :anonymous  | :reject | :forbidden
      :scoped_naming_convention    | 'PUBLIC'   | :guest      | :reject | :forbidden
      :scoped_naming_convention    | 'PUBLIC'   | :maintainer | :accept | :ok
      :non_existing                | 'PUBLIC'   | :anonymous  | :reject | :forbidden
      :non_existing                | 'PUBLIC'   | :guest      | :reject | :forbidden
      :non_existing                | 'PUBLIC'   | :maintainer | :reject | :not_found

      :scoped_naming_convention    | 'PRIVATE'  | :anonymous  | :reject | :not_found
      :scoped_naming_convention    | 'PRIVATE'  | :guest      | :reject | :forbidden
      :scoped_naming_convention    | 'PRIVATE'  | :maintainer | :accept | :ok
      :non_existing                | 'INTERNAL' | :anonymous  | :reject | :forbidden
      :non_existing                | 'INTERNAL' | :guest      | :reject | :forbidden
      :non_existing                | 'INTERNAL' | :maintainer | :reject | :not_found
    end

    with_them do
      let(:anonymous) { user_role == :anonymous }

      subject { delete(url, headers: headers) }

      before do
        project.send("add_#{user_role}", user) unless anonymous
        project.update!(visibility: Gitlab::VisibilityLevel.const_get(visibility, false))
      end

      example_name = "#{params[:expected_result]} delete package tag request"
      status = params[:expected_status]

      if scope == :instance && params[:package_name_type] != :scoped_naming_convention
        example_name = 'reject delete package tag request'
        status = :not_found
      end

      it_behaves_like example_name, status: status
    end
  end

  context 'with oauth token' do
    let(:headers) { build_token_auth_header(token.token) }

    it_behaves_like 'handling different package names, visibilities and user roles'
  end

  context 'with personal access token' do
    let(:headers) { build_token_auth_header(personal_access_token.token) }

    it_behaves_like 'handling different package names, visibilities and user roles'
  end
end
