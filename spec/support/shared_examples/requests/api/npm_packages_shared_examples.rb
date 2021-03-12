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

  shared_examples 'handling all conditions' do
    where(:auth, :package_name_type, :request_forward, :visibility, :user_role, :expected_result, :expected_status) do
      nil                    | :scoped_naming_convention    | true  | :public   | nil       | :accept   | :ok
      nil                    | :scoped_naming_convention    | false | :public   | nil       | :accept   | :ok
      nil                    | :scoped_no_naming_convention | true  | :public   | nil       | :accept   | :ok
      nil                    | :scoped_no_naming_convention | false | :public   | nil       | :accept   | :ok
      nil                    | :unscoped                    | true  | :public   | nil       | :accept   | :ok
      nil                    | :unscoped                    | false | :public   | nil       | :accept   | :ok
      nil                    | :non_existing                | true  | :public   | nil       | :redirect | :redirected
      nil                    | :non_existing                | false | :public   | nil       | :reject   | :not_found
      nil                    | :scoped_naming_convention    | true  | :private  | nil       | :reject   | :not_found
      nil                    | :scoped_naming_convention    | false | :private  | nil       | :reject   | :not_found
      nil                    | :scoped_no_naming_convention | true  | :private  | nil       | :reject   | :not_found
      nil                    | :scoped_no_naming_convention | false | :private  | nil       | :reject   | :not_found
      nil                    | :unscoped                    | true  | :private  | nil       | :reject   | :not_found
      nil                    | :unscoped                    | false | :private  | nil       | :reject   | :not_found
      nil                    | :non_existing                | true  | :private  | nil       | :redirect | :redirected
      nil                    | :non_existing                | false | :private  | nil       | :reject   | :not_found
      nil                    | :scoped_naming_convention    | true  | :internal | nil       | :reject   | :not_found
      nil                    | :scoped_naming_convention    | false | :internal | nil       | :reject   | :not_found
      nil                    | :scoped_no_naming_convention | true  | :internal | nil       | :reject   | :not_found
      nil                    | :scoped_no_naming_convention | false | :internal | nil       | :reject   | :not_found
      nil                    | :unscoped                    | true  | :internal | nil       | :reject   | :not_found
      nil                    | :unscoped                    | false | :internal | nil       | :reject   | :not_found
      nil                    | :non_existing                | true  | :internal | nil       | :redirect | :redirected
      nil                    | :non_existing                | false | :internal | nil       | :reject   | :not_found

      :oauth                 | :scoped_naming_convention    | true  | :public   | :guest    | :accept   | :ok
      :oauth                 | :scoped_naming_convention    | true  | :public   | :reporter | :accept   | :ok
      :oauth                 | :scoped_naming_convention    | false | :public   | :guest    | :accept   | :ok
      :oauth                 | :scoped_naming_convention    | false | :public   | :reporter | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | true  | :public   | :guest    | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | true  | :public   | :reporter | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | false | :public   | :guest    | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | false | :public   | :reporter | :accept   | :ok
      :oauth                 | :unscoped                    | true  | :public   | :guest    | :accept   | :ok
      :oauth                 | :unscoped                    | true  | :public   | :reporter | :accept   | :ok
      :oauth                 | :unscoped                    | false | :public   | :guest    | :accept   | :ok
      :oauth                 | :unscoped                    | false | :public   | :reporter | :accept   | :ok
      :oauth                 | :non_existing                | true  | :public   | :guest    | :redirect | :redirected
      :oauth                 | :non_existing                | true  | :public   | :reporter | :redirect | :redirected
      :oauth                 | :non_existing                | false | :public   | :guest    | :reject   | :not_found
      :oauth                 | :non_existing                | false | :public   | :reporter | :reject   | :not_found
      :oauth                 | :scoped_naming_convention    | true  | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :scoped_naming_convention    | true  | :private  | :reporter | :accept   | :ok
      :oauth                 | :scoped_naming_convention    | false | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :scoped_naming_convention    | false | :private  | :reporter | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | true  | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :scoped_no_naming_convention | true  | :private  | :reporter | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | false | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :scoped_no_naming_convention | false | :private  | :reporter | :accept   | :ok
      :oauth                 | :unscoped                    | true  | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :unscoped                    | true  | :private  | :reporter | :accept   | :ok
      :oauth                 | :unscoped                    | false | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :unscoped                    | false | :private  | :reporter | :accept   | :ok
      :oauth                 | :non_existing                | true  | :private  | :guest    | :redirect | :redirected
      :oauth                 | :non_existing                | true  | :private  | :reporter | :redirect | :redirected
      :oauth                 | :non_existing                | false | :private  | :guest    | :reject   | :forbidden
      :oauth                 | :non_existing                | false | :private  | :reporter | :reject   | :not_found
      :oauth                 | :scoped_naming_convention    | true  | :internal | :guest    | :accept   | :ok
      :oauth                 | :scoped_naming_convention    | true  | :internal | :reporter | :accept   | :ok
      :oauth                 | :scoped_naming_convention    | false | :internal | :guest    | :accept   | :ok
      :oauth                 | :scoped_naming_convention    | false | :internal | :reporter | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | true  | :internal | :guest    | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | true  | :internal | :reporter | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | false | :internal | :guest    | :accept   | :ok
      :oauth                 | :scoped_no_naming_convention | false | :internal | :reporter | :accept   | :ok
      :oauth                 | :unscoped                    | true  | :internal | :guest    | :accept   | :ok
      :oauth                 | :unscoped                    | true  | :internal | :reporter | :accept   | :ok
      :oauth                 | :unscoped                    | false | :internal | :guest    | :accept   | :ok
      :oauth                 | :unscoped                    | false | :internal | :reporter | :accept   | :ok
      :oauth                 | :non_existing                | true  | :internal | :guest    | :redirect | :redirected
      :oauth                 | :non_existing                | true  | :internal | :reporter | :redirect | :redirected
      :oauth                 | :non_existing                | false | :internal | :guest    | :reject   | :not_found
      :oauth                 | :non_existing                | false | :internal | :reporter | :reject   | :not_found

      :personal_access_token | :scoped_naming_convention    | true  | :public   | :guest    | :accept   | :ok
      :personal_access_token | :scoped_naming_convention    | true  | :public   | :reporter | :accept   | :ok
      :personal_access_token | :scoped_naming_convention    | false | :public   | :guest    | :accept   | :ok
      :personal_access_token | :scoped_naming_convention    | false | :public   | :reporter | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | true  | :public   | :guest    | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | true  | :public   | :reporter | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | false | :public   | :guest    | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | false | :public   | :reporter | :accept   | :ok
      :personal_access_token | :unscoped                    | true  | :public   | :guest    | :accept   | :ok
      :personal_access_token | :unscoped                    | true  | :public   | :reporter | :accept   | :ok
      :personal_access_token | :unscoped                    | false | :public   | :guest    | :accept   | :ok
      :personal_access_token | :unscoped                    | false | :public   | :reporter | :accept   | :ok
      :personal_access_token | :non_existing                | true  | :public   | :guest    | :redirect | :redirected
      :personal_access_token | :non_existing                | true  | :public   | :reporter | :redirect | :redirected
      :personal_access_token | :non_existing                | false | :public   | :guest    | :reject   | :not_found
      :personal_access_token | :non_existing                | false | :public   | :reporter | :reject   | :not_found
      :personal_access_token | :scoped_naming_convention    | true  | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :scoped_naming_convention    | true  | :private  | :reporter | :accept   | :ok
      :personal_access_token | :scoped_naming_convention    | false | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :scoped_naming_convention    | false | :private  | :reporter | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | true  | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :scoped_no_naming_convention | true  | :private  | :reporter | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | false | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :scoped_no_naming_convention | false | :private  | :reporter | :accept   | :ok
      :personal_access_token | :unscoped                    | true  | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :unscoped                    | true  | :private  | :reporter | :accept   | :ok
      :personal_access_token | :unscoped                    | false | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :unscoped                    | false | :private  | :reporter | :accept   | :ok
      :personal_access_token | :non_existing                | true  | :private  | :guest    | :redirect | :redirected
      :personal_access_token | :non_existing                | true  | :private  | :reporter | :redirect | :redirected
      :personal_access_token | :non_existing                | false | :private  | :guest    | :reject   | :forbidden
      :personal_access_token | :non_existing                | false | :private  | :reporter | :reject   | :not_found
      :personal_access_token | :scoped_naming_convention    | true  | :internal | :guest    | :accept   | :ok
      :personal_access_token | :scoped_naming_convention    | true  | :internal | :reporter | :accept   | :ok
      :personal_access_token | :scoped_naming_convention    | false | :internal | :guest    | :accept   | :ok
      :personal_access_token | :scoped_naming_convention    | false | :internal | :reporter | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | true  | :internal | :guest    | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | true  | :internal | :reporter | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | false | :internal | :guest    | :accept   | :ok
      :personal_access_token | :scoped_no_naming_convention | false | :internal | :reporter | :accept   | :ok
      :personal_access_token | :unscoped                    | true  | :internal | :guest    | :accept   | :ok
      :personal_access_token | :unscoped                    | true  | :internal | :reporter | :accept   | :ok
      :personal_access_token | :unscoped                    | false | :internal | :guest    | :accept   | :ok
      :personal_access_token | :unscoped                    | false | :internal | :reporter | :accept   | :ok
      :personal_access_token | :non_existing                | true  | :internal | :guest    | :redirect | :redirected
      :personal_access_token | :non_existing                | true  | :internal | :reporter | :redirect | :redirected
      :personal_access_token | :non_existing                | false | :internal | :guest    | :reject   | :not_found
      :personal_access_token | :non_existing                | false | :internal | :reporter | :reject   | :not_found

      :job_token             | :scoped_naming_convention    | true  | :public   | :developer | :accept   | :ok
      :job_token             | :scoped_naming_convention    | false | :public   | :developer | :accept   | :ok
      :job_token             | :scoped_no_naming_convention | true  | :public   | :developer | :accept   | :ok
      :job_token             | :scoped_no_naming_convention | false | :public   | :developer | :accept   | :ok
      :job_token             | :unscoped                    | true  | :public   | :developer | :accept   | :ok
      :job_token             | :unscoped                    | false | :public   | :developer | :accept   | :ok
      :job_token             | :non_existing                | true  | :public   | :developer | :redirect | :redirected
      :job_token             | :non_existing                | false | :public   | :developer | :reject   | :not_found
      :job_token             | :scoped_naming_convention    | true  | :private  | :developer | :accept   | :ok
      :job_token             | :scoped_naming_convention    | false | :private  | :developer | :accept   | :ok
      :job_token             | :scoped_no_naming_convention | true  | :private  | :developer | :accept   | :ok
      :job_token             | :scoped_no_naming_convention | false | :private  | :developer | :accept   | :ok
      :job_token             | :unscoped                    | true  | :private  | :developer | :accept   | :ok
      :job_token             | :unscoped                    | false | :private  | :developer | :accept   | :ok
      :job_token             | :non_existing                | true  | :private  | :developer | :redirect | :redirected
      :job_token             | :non_existing                | false | :private  | :developer | :reject   | :not_found
      :job_token             | :scoped_naming_convention    | true  | :internal | :developer | :accept   | :ok
      :job_token             | :scoped_naming_convention    | false | :internal | :developer | :accept   | :ok
      :job_token             | :scoped_no_naming_convention | true  | :internal | :developer | :accept   | :ok
      :job_token             | :scoped_no_naming_convention | false | :internal | :developer | :accept   | :ok
      :job_token             | :unscoped                    | true  | :internal | :developer | :accept   | :ok
      :job_token             | :unscoped                    | false | :internal | :developer | :accept   | :ok
      :job_token             | :non_existing                | true  | :internal | :developer | :redirect | :redirected
      :job_token             | :non_existing                | false | :internal | :developer | :reject   | :not_found

      :deploy_token          | :scoped_naming_convention    | true  | :public   | nil        | :accept   | :ok
      :deploy_token          | :scoped_naming_convention    | false | :public   | nil        | :accept   | :ok
      :deploy_token          | :scoped_no_naming_convention | true  | :public   | nil        | :accept   | :ok
      :deploy_token          | :scoped_no_naming_convention | false | :public   | nil        | :accept   | :ok
      :deploy_token          | :unscoped                    | true  | :public   | nil        | :accept   | :ok
      :deploy_token          | :unscoped                    | false | :public   | nil        | :accept   | :ok
      :deploy_token          | :non_existing                | true  | :public   | nil        | :redirect | :redirected
      :deploy_token          | :non_existing                | false | :public   | nil        | :reject   | :not_found
      :deploy_token          | :scoped_naming_convention    | true  | :private  | nil        | :accept   | :ok
      :deploy_token          | :scoped_naming_convention    | false | :private  | nil        | :accept   | :ok
      :deploy_token          | :scoped_no_naming_convention | true  | :private  | nil        | :accept   | :ok
      :deploy_token          | :scoped_no_naming_convention | false | :private  | nil        | :accept   | :ok
      :deploy_token          | :unscoped                    | true  | :private  | nil        | :accept   | :ok
      :deploy_token          | :unscoped                    | false | :private  | nil        | :accept   | :ok
      :deploy_token          | :non_existing                | true  | :private  | nil        | :redirect | :redirected
      :deploy_token          | :non_existing                | false | :private  | nil        | :reject   | :not_found
      :deploy_token          | :scoped_naming_convention    | true  | :internal | nil        | :accept   | :ok
      :deploy_token          | :scoped_naming_convention    | false | :internal | nil        | :accept   | :ok
      :deploy_token          | :scoped_no_naming_convention | true  | :internal | nil        | :accept   | :ok
      :deploy_token          | :scoped_no_naming_convention | false | :internal | nil        | :accept   | :ok
      :deploy_token          | :unscoped                    | true  | :internal | nil        | :accept   | :ok
      :deploy_token          | :unscoped                    | false | :internal | nil        | :accept   | :ok
      :deploy_token          | :non_existing                | true  | :internal | nil        | :redirect | :redirected
      :deploy_token          | :non_existing                | false | :internal | nil        | :reject   | :not_found
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
        project.update!(visibility: visibility.to_s)
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
      :scoped_naming_convention    | :public   | :anonymous | :accept | :ok
      :scoped_naming_convention    | :public   | :guest     | :accept | :ok
      :scoped_naming_convention    | :public   | :reporter  | :accept | :ok
      :scoped_no_naming_convention | :public   | :anonymous | :accept | :ok
      :scoped_no_naming_convention | :public   | :guest     | :accept | :ok
      :scoped_no_naming_convention | :public   | :reporter  | :accept | :ok
      :unscoped                    | :public   | :anonymous | :accept | :ok
      :unscoped                    | :public   | :guest     | :accept | :ok
      :unscoped                    | :public   | :reporter  | :accept | :ok
      :non_existing                | :public   | :anonymous | :reject | :not_found
      :non_existing                | :public   | :guest     | :reject | :not_found
      :non_existing                | :public   | :reporter  | :reject | :not_found

      :scoped_naming_convention    | :private  | :anonymous | :reject | :not_found
      :scoped_naming_convention    | :private  | :guest     | :reject | :forbidden
      :scoped_naming_convention    | :private  | :reporter  | :accept | :ok
      :scoped_no_naming_convention | :private  | :anonymous | :reject | :not_found
      :scoped_no_naming_convention | :private  | :guest     | :reject | :forbidden
      :scoped_no_naming_convention | :private  | :reporter  | :accept | :ok
      :unscoped                    | :private  | :anonymous | :reject | :not_found
      :unscoped                    | :private  | :guest     | :reject | :forbidden
      :unscoped                    | :private  | :reporter  | :accept | :ok
      :non_existing                | :private  | :anonymous | :reject | :not_found
      :non_existing                | :private  | :guest     | :reject | :forbidden
      :non_existing                | :private  | :reporter  | :reject | :not_found

      :scoped_naming_convention    | :internal | :anonymous | :reject | :not_found
      :scoped_naming_convention    | :internal | :guest     | :accept | :ok
      :scoped_naming_convention    | :internal | :reporter  | :accept | :ok
      :scoped_no_naming_convention | :internal | :anonymous | :reject | :not_found
      :scoped_no_naming_convention | :internal | :guest     | :accept | :ok
      :scoped_no_naming_convention | :internal | :reporter  | :accept | :ok
      :unscoped                    | :internal | :anonymous | :reject | :not_found
      :unscoped                    | :internal | :guest     | :accept | :ok
      :unscoped                    | :internal | :reporter  | :accept | :ok
      :non_existing                | :internal | :anonymous | :reject | :not_found
      :non_existing                | :internal | :guest     | :reject | :not_found
      :non_existing                | :internal | :reporter  | :reject | :not_found
    end

    with_them do
      let(:anonymous) { user_role == :anonymous }

      subject { get(url, headers: anonymous ? {} : headers) }

      before do
        project.send("add_#{user_role}", user) unless anonymous
        project.update!(visibility: visibility.to_s)
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

  shared_examples 'handling all conditions' do
    context 'with oauth token' do
      let(:headers) { build_token_auth_header(token.token) }

      it_behaves_like 'handling different package names, visibilities and user roles'
    end

    context 'with personal access token' do
      let(:headers) { build_token_auth_header(personal_access_token.token) }

      it_behaves_like 'handling different package names, visibilities and user roles'
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
      :scoped_naming_convention    | :public   | :anonymous | :reject | :forbidden
      :scoped_naming_convention    | :public   | :guest     | :reject | :forbidden
      :scoped_naming_convention    | :public   | :developer | :accept | :ok
      :scoped_no_naming_convention | :public   | :anonymous | :reject | :forbidden
      :scoped_no_naming_convention | :public   | :guest     | :reject | :forbidden
      :scoped_no_naming_convention | :public   | :developer | :accept | :ok
      :unscoped                    | :public   | :anonymous | :reject | :forbidden
      :unscoped                    | :public   | :guest     | :reject | :forbidden
      :unscoped                    | :public   | :developer | :accept | :ok
      :non_existing                | :public   | :anonymous | :reject | :forbidden
      :non_existing                | :public   | :guest     | :reject | :forbidden
      :non_existing                | :public   | :developer | :reject | :not_found

      :scoped_naming_convention    | :private  | :anonymous | :reject | :not_found
      :scoped_naming_convention    | :private  | :guest     | :reject | :forbidden
      :scoped_naming_convention    | :private  | :developer | :accept | :ok
      :scoped_no_naming_convention | :private  | :anonymous | :reject | :not_found
      :scoped_no_naming_convention | :private  | :guest     | :reject | :forbidden
      :scoped_no_naming_convention | :private  | :developer | :accept | :ok
      :unscoped                    | :private  | :anonymous | :reject | :not_found
      :unscoped                    | :private  | :guest     | :reject | :forbidden
      :unscoped                    | :private  | :developer | :accept | :ok
      :non_existing                | :private  | :anonymous | :reject | :not_found
      :non_existing                | :private  | :guest     | :reject | :forbidden
      :non_existing                | :private  | :developer | :reject | :not_found

      :scoped_naming_convention    | :internal | :anonymous | :reject | :forbidden
      :scoped_naming_convention    | :internal | :guest     | :reject | :forbidden
      :scoped_naming_convention    | :internal | :developer | :accept | :ok
      :scoped_no_naming_convention | :internal | :anonymous | :reject | :forbidden
      :scoped_no_naming_convention | :internal | :guest     | :reject | :forbidden
      :scoped_no_naming_convention | :internal | :developer | :accept | :ok
      :unscoped                    | :internal | :anonymous | :reject | :forbidden
      :unscoped                    | :internal | :guest     | :reject | :forbidden
      :unscoped                    | :internal | :developer | :accept | :ok
      :non_existing                | :internal | :anonymous | :reject | :forbidden
      :non_existing                | :internal | :guest     | :reject | :forbidden
      :non_existing                | :internal | :developer | :reject | :not_found
    end

    with_them do
      let(:anonymous) { user_role == :anonymous }

      subject { put(url, env: env, headers: headers) }

      before do
        project.send("add_#{user_role}", user) unless anonymous
        project.update!(visibility: visibility.to_s)
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

  shared_examples 'handling all conditions' do
    context 'with oauth token' do
      let(:headers) { build_token_auth_header(token.token) }

      it_behaves_like 'handling different package names, visibilities and user roles'
    end

    context 'with personal access token' do
      let(:headers) { build_token_auth_header(personal_access_token.token) }

      it_behaves_like 'handling different package names, visibilities and user roles'
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
      :scoped_naming_convention    | :public   | :anonymous  | :reject | :forbidden
      :scoped_naming_convention    | :public   | :guest      | :reject | :forbidden
      :scoped_naming_convention    | :public   | :maintainer | :accept | :ok
      :scoped_no_naming_convention | :public   | :anonymous  | :reject | :forbidden
      :scoped_no_naming_convention | :public   | :guest      | :reject | :forbidden
      :scoped_no_naming_convention | :public   | :maintainer | :accept | :ok
      :unscoped                    | :public   | :anonymous  | :reject | :forbidden
      :unscoped                    | :public   | :guest      | :reject | :forbidden
      :unscoped                    | :public   | :maintainer | :accept | :ok
      :non_existing                | :public   | :anonymous  | :reject | :forbidden
      :non_existing                | :public   | :guest      | :reject | :forbidden
      :non_existing                | :public   | :maintainer | :reject | :not_found

      :scoped_naming_convention    | :private  | :anonymous  | :reject | :not_found
      :scoped_naming_convention    | :private  | :guest      | :reject | :forbidden
      :scoped_naming_convention    | :private  | :maintainer | :accept | :ok
      :scoped_no_naming_convention | :private  | :anonymous  | :reject | :not_found
      :scoped_no_naming_convention | :private  | :guest      | :reject | :forbidden
      :scoped_no_naming_convention | :private  | :maintainer | :accept | :ok
      :unscoped                    | :private  | :anonymous  | :reject | :not_found
      :unscoped                    | :private  | :guest      | :reject | :forbidden
      :unscoped                    | :private  | :maintainer | :accept | :ok
      :non_existing                | :private  | :anonymous  | :reject | :not_found
      :non_existing                | :private  | :guest      | :reject | :forbidden
      :non_existing                | :private  | :maintainer | :reject | :not_found

      :scoped_naming_convention    | :internal | :anonymous  | :reject | :forbidden
      :scoped_naming_convention    | :internal | :guest      | :reject | :forbidden
      :scoped_naming_convention    | :internal | :maintainer | :accept | :ok
      :scoped_no_naming_convention | :internal | :anonymous  | :reject | :forbidden
      :scoped_no_naming_convention | :internal | :guest      | :reject | :forbidden
      :scoped_no_naming_convention | :internal | :maintainer | :accept | :ok
      :unscoped                    | :internal | :anonymous  | :reject | :forbidden
      :unscoped                    | :internal | :guest      | :reject | :forbidden
      :unscoped                    | :internal | :maintainer | :accept | :ok
      :non_existing                | :internal | :anonymous  | :reject | :forbidden
      :non_existing                | :internal | :guest      | :reject | :forbidden
      :non_existing                | :internal | :maintainer | :reject | :not_found
    end

    with_them do
      let(:anonymous) { user_role == :anonymous }

      subject { delete(url, headers: headers) }

      before do
        project.send("add_#{user_role}", user) unless anonymous
        project.update!(visibility: visibility.to_s)
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

  shared_examples 'handling all conditions' do
    context 'with oauth token' do
      let(:headers) { build_token_auth_header(token.token) }

      it_behaves_like 'handling different package names, visibilities and user roles'
    end

    context 'with personal access token' do
      let(:headers) { build_token_auth_header(personal_access_token.token) }

      it_behaves_like 'handling different package names, visibilities and user roles'
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
