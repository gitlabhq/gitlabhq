# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::PypiPackages, feature_category: :package_registry do
  include WorkhorseHelpers
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, :public, group: group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }

  let(:snowplow_gitlab_standard_context) { snowplow_context }
  let(:headers) { {} }

  def snowplow_context(user_role: :developer)
    if user_role == :anonymous
      { project: project, namespace: project.namespace, property: 'i_package_pypi_user' }
    else
      { project: project, namespace: project.namespace, property: 'i_package_pypi_user', user: user }
    end
  end

  shared_context 'setup auth headers' do
    let(:token) { personal_access_token.token }
    let(:user_headers) { basic_auth_header(user.username, token) }
    let(:headers) { user_headers.merge(workhorse_headers) }
  end

  shared_context 'add to project and group' do |user_type|
    before do
      project.send("add_#{user_type}", user)
      group.send("add_#{user_type}", user)
    end
  end

  context 'simple index API endpoint' do
    let_it_be(:package) { create(:pypi_package, project: project) }
    let_it_be(:package2) { create(:pypi_package, project: project) }

    subject(:request) { get api(url), headers: headers }

    describe 'GET /api/v4/groups/:id/-/packages/pypi/simple' do
      let(:url) { "/groups/#{group.id}/-/packages/pypi/simple" }

      it_behaves_like 'pypi simple index API endpoint'
      it_behaves_like 'rejects PyPI access with unknown group id'

      context 'deploy tokens' do
        let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: deploy_token, group: group) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          group.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        end

        it_behaves_like 'deploy token for package GET requests'

        context 'with group path as id' do
          let(:url) { "/groups/#{CGI.escape(group.full_path)}/-/packages/pypi/simple" }

          it_behaves_like 'deploy token for package GET requests'
        end
      end

      context 'job token' do
        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          group.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          group.add_developer(user)
        end

        it_behaves_like 'job token for package GET requests'
      end

      it_behaves_like 'a pypi user namespace endpoint'
    end

    describe 'GET /api/v4/projects/:id/packages/pypi/simple' do
      let(:package_name) { package.name }
      let(:url) { "/projects/#{project.id}/packages/pypi/simple" }
      let(:snowplow_gitlab_standard_context) { { project: nil, namespace: group, property: 'i_package_pypi_user' } }

      it_behaves_like 'enforcing read_packages job token policy'
      it_behaves_like 'pypi simple index API endpoint'
      it_behaves_like 'rejects PyPI access with unknown project id'
      it_behaves_like 'deploy token for package GET requests'
      it_behaves_like 'job token for package GET requests'
      it_behaves_like 'allow access for everyone with public package_registry_access_level'

      context 'with project path as id' do
        let(:url) { "/projects/#{CGI.escape(project.full_path)}/packages/pypi/simple" }

        it_behaves_like 'deploy token for package GET requests'
      end
    end
  end

  context 'simple package API endpoint' do
    let_it_be(:package) { create(:pypi_package, project: project) }

    subject(:request) { get api(url), headers: headers }

    describe 'GET /api/v4/groups/:id/-/packages/pypi/simple/:package_name' do
      let(:package_name) { package.name }
      let(:url) { "/groups/#{group.id}/-/packages/pypi/simple/#{package_name}" }
      let(:snowplow_context) { { project: nil, namespace: project.namespace, property: 'i_package_pypi_user' } }

      it_behaves_like 'pypi simple API endpoint'
      it_behaves_like 'rejects PyPI access with unknown group id'

      context 'deploy tokens' do
        let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: deploy_token, group: group) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          group.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        end

        it_behaves_like 'deploy token for package GET requests'

        context 'with group path as id' do
          let(:url) { "/groups/#{CGI.escape(group.full_path)}/-/packages/pypi/simple/#{package_name}" }

          it_behaves_like 'deploy token for package GET requests'
        end
      end

      context 'job token' do
        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          group.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          group.add_developer(user)
        end

        it_behaves_like 'job token for package GET requests'
      end

      it_behaves_like 'a pypi user namespace endpoint'
    end

    describe 'GET /api/v4/projects/:id/packages/pypi/simple/:package_name' do
      let(:package_name) { package.name }
      let(:url) { "/projects/#{project.id}/packages/pypi/simple/#{package_name}" }
      let(:snowplow_context) { { project: project, namespace: project.namespace, property: 'i_package_pypi_user' } }

      it_behaves_like 'enforcing read_packages job token policy'
      it_behaves_like 'pypi simple API endpoint'
      it_behaves_like 'rejects PyPI access with unknown project id'
      it_behaves_like 'deploy token for package GET requests'
      it_behaves_like 'job token for package GET requests'
      it_behaves_like 'allow access for everyone with public package_registry_access_level'

      context 'with project path as id' do
        let(:url) { "/projects/#{CGI.escape(project.full_path)}/packages/pypi/simple/#{package.name}" }

        it_behaves_like 'deploy token for package GET requests'
      end
    end
  end

  describe 'POST /api/v4/projects/:id/packages/pypi/authorize' do
    include_context 'workhorse headers'

    let(:url) { "/projects/#{project.id}/packages/pypi/authorize" }
    let(:headers) { {} }

    subject(:request) { post api(url), headers: headers }

    it_behaves_like 'enforcing job token policies', :admin_packages do
      before_all do
        project.add_developer(user)
      end

      let(:headers) { build_token_auth_header(target_job.token).merge(workhorse_headers) }
    end

    context 'with valid project' do
      where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | true  | 'process PyPI api request' | :success
        :public  | :guest      | true  | true  | 'process PyPI api request' | :forbidden
        :public  | :developer  | true  | false | 'process PyPI api request' | :unauthorized
        :public  | :guest      | true  | false | 'process PyPI api request' | :unauthorized
        :public  | :developer  | false | true  | 'process PyPI api request' | :forbidden
        :public  | :guest      | false | true  | 'process PyPI api request' | :forbidden
        :public  | :developer  | false | false | 'process PyPI api request' | :unauthorized
        :public  | :guest      | false | false | 'process PyPI api request' | :unauthorized
        :public  | :anonymous  | false | true  | 'process PyPI api request' | :unauthorized
        :private | :developer  | true  | true  | 'process PyPI api request' | :success
        :private | :guest      | true  | true  | 'process PyPI api request' | :forbidden
        :private | :developer  | true  | false | 'process PyPI api request' | :unauthorized
        :private | :guest      | true  | false | 'process PyPI api request' | :unauthorized
        :private | :developer  | false | true  | 'process PyPI api request' | :not_found
        :private | :guest      | false | true  | 'process PyPI api request' | :not_found
        :private | :developer  | false | false | 'process PyPI api request' | :unauthorized
        :private | :guest      | false | false | 'process PyPI api request' | :unauthorized
        :private | :anonymous  | false | true  | 'process PyPI api request' | :unauthorized
      end

      with_them do
        let(:token) { user_token ? personal_access_token.token : 'wrong' }
        let(:user_headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }
        let(:headers) { user_headers.merge(workhorse_headers) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    it_behaves_like 'deploy token for package uploads'

    it_behaves_like 'job token for package uploads', authorize_endpoint: true

    it_behaves_like 'rejects PyPI access with unknown project id'
  end

  describe 'POST /api/v4/projects/:id/packages/pypi' do
    include_context 'workhorse headers'

    let_it_be(:file_name) { 'package.whl' }

    let(:url) { "/projects/#{project.id}/packages/pypi" }
    let(:headers) { {} }
    let(:requires_python) { '>=3.7' }
    let(:keywords) { 'dog,puppy,voting,election' }
    let(:description) { 'Example description' }
    let(:metadata_version) { '2.3' }
    let(:author_email) { 'cschultz@example.com, snoopy@peanuts.com' }
    let(:description_content_type) { 'text/plain' }
    let(:summary) { 'A module for collecting votes from beagles.' }
    let(:base_params) do
      {
        requires_python: requires_python,
        version: '1.0.0',
        name: 'sample-project',
        sha256_digest: '1' * 64,
        md5_digest: '1' * 32,
        metadata_version: metadata_version,
        author_email: author_email,
        description: description,
        description_content_type: description_content_type,
        summary: summary,
        keywords: keywords
      }
    end

    let(:params) { base_params.merge(content: temp_file(file_name)) }
    let(:send_rewritten_field) { true }
    let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user, property: 'i_package_pypi_user' } }

    subject(:request) do
      workhorse_finalize(
        api(url),
        method: :post,
        file_key: :content,
        params: params,
        headers: headers,
        send_rewritten_field: send_rewritten_field
      )
    end

    it_behaves_like 'enforcing job token policies', :admin_packages do
      before_all do
        project.add_developer(user)
      end

      let(:headers) { build_token_auth_header(target_job.token).merge(workhorse_headers) }
    end

    context 'with valid project' do
      where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | true  | 'PyPI package creation'    | :created
        :public  | :guest      | true  | true  | 'process PyPI api request' | :forbidden
        :public  | :developer  | true  | false | 'process PyPI api request' | :unauthorized
        :public  | :guest      | true  | false | 'process PyPI api request' | :unauthorized
        :public  | :developer  | false | true  | 'process PyPI api request' | :forbidden
        :public  | :guest      | false | true  | 'process PyPI api request' | :forbidden
        :public  | :developer  | false | false | 'process PyPI api request' | :unauthorized
        :public  | :guest      | false | false | 'process PyPI api request' | :unauthorized
        :public  | :anonymous  | false | true  | 'process PyPI api request' | :unauthorized
        :private | :developer  | true  | true  | 'process PyPI api request' | :created
        :private | :guest      | true  | true  | 'process PyPI api request' | :forbidden
        :private | :developer  | true  | false | 'process PyPI api request' | :unauthorized
        :private | :guest      | true  | false | 'process PyPI api request' | :unauthorized
        :private | :developer  | false | true  | 'process PyPI api request' | :not_found
        :private | :guest      | false | true  | 'process PyPI api request' | :not_found
        :private | :developer  | false | false | 'process PyPI api request' | :unauthorized
        :private | :guest      | false | false | 'process PyPI api request' | :unauthorized
        :private | :anonymous  | false | true  | 'process PyPI api request' | :unauthorized
      end

      with_them do
        let(:token) { user_token ? personal_access_token.token : 'wrong' }
        let(:user_headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }
        let(:headers) { user_headers.merge(workhorse_headers) }
        let(:snowplow_gitlab_standard_context) do
          if user_role == :anonymous || (visibility_level == :public && !user_token)
            { project: project, namespace: project.namespace, property: 'i_package_pypi_user' }
          else
            { project: project, namespace: project.namespace, property: 'i_package_pypi_user', user: user }
          end
        end

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end

      context 'without requires_python' do
        let(:token) { personal_access_token.token }
        let(:user_headers) { basic_auth_header(user.username, token) }
        let(:headers) { user_headers.merge(workhorse_headers) }

        it_behaves_like 'PyPI package creation', :developer, :created, true

        context 'with FIPS mode', :fips_mode do
          it_behaves_like 'PyPI package creation', :developer, :created, true, false
        end
      end

      context 'without sha256_digest' do
        let(:token) { personal_access_token.token }
        let(:user_headers) { basic_auth_header(user.username, token) }
        let(:headers) { user_headers.merge(workhorse_headers) }
        let(:params) { base_params.merge(content: temp_file(file_name)) }

        before do
          params.delete(:sha256_digest)
        end

        it_behaves_like 'PyPI package creation', :developer, :created, true, true

        context 'with FIPS mode', :fips_mode do
          before do
            project.add_developer(user)
          end

          it 'returns 422 and does not create a package' do
            expect { subject }.not_to change { Packages::Pypi::Package.for_projects(project).count }

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
          end
        end
      end
    end

    context 'with a very long metadata field' do
      where(:field_name, :param_name, :max_length) do
        :required_python          | :requires_python | ::Packages::Pypi::Metadatum::MAX_REQUIRED_PYTHON_LENGTH
        :keywords                 | nil              | ::Packages::Pypi::Metadatum::MAX_KEYWORDS_LENGTH
        :metadata_version         | nil              | ::Packages::Pypi::Metadatum::MAX_METADATA_VERSION_LENGTH
        :description              | nil              | ::Packages::Pypi::Metadatum::MAX_DESCRIPTION_LENGTH
        :summary                  | nil              | ::Packages::Pypi::Metadatum::MAX_SUMMARY_LENGTH
        :description_content_type | nil              | ::Packages::Pypi::Metadatum::MAX_DESCRIPTION_CONTENT_TYPE_LENGTH
        :author_email             | nil              | ::Packages::Pypi::Metadatum::MAX_AUTHOR_EMAIL_LENGTH
      end

      with_them do
        include_context 'setup auth headers'
        include_context 'add to project and group', 'developer'

        let(:truncated_field) { ('x' * (max_length + 1)).truncate(max_length) }

        before do
          key = param_name || field_name

          params.merge!(
            { key.to_sym => 'x' * (max_length + 1) }
          )
        end

        it_behaves_like 'returning response status', :created

        it 'truncates the field' do
          subject

          created_package = ::Packages::Package.pypi.last

          expect(created_package.pypi_metadatum.public_send(field_name)).to eq(truncated_field)
        end
      end
    end

    context 'with an invalid package' do
      include_context 'setup auth headers'

      before do
        params[:name] = '.$/@!^*'
        project.add_developer(user)
      end

      it_behaves_like 'returning response status', :bad_request
    end

    context 'with an invalid sha256' do
      include_context 'setup auth headers'

      before do
        params[:sha256_digest] = ('a' * 63) + '%'
        project.add_developer(user)
      end

      it_behaves_like 'returning response status', :bad_request
    end

    it_behaves_like 'deploy token for package uploads'

    it_behaves_like 'job token for package uploads'

    it_behaves_like 'rejects PyPI access with unknown project id'

    context 'file size above maximum limit' do
      let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_headers) }

      before do
        allow_next_instance_of(UploadedFile) do |uploaded_file|
          allow(uploaded_file).to receive(:size).and_return(project.actual_limits.pypi_max_file_size + 1)
        end
      end

      it_behaves_like 'returning response status', :bad_request
    end

    context 'with existing package' do
      let_it_be_with_reload(:existing_package) { create(:pypi_package, name: 'sample-project', version: '1.0.0', project: project) }

      let(:headers) { basic_auth_header(user.username, personal_access_token.token).merge(workhorse_headers) }

      before do
        project.add_maintainer(user)
      end

      it 'does not create a new package', :aggregate_failures do
        expect { subject }
          .to change { Packages::Pypi::Package.for_projects(project).count }.by(0)
          .and change { Packages::PackageFile.count }.by(1)
          .and change { Packages::Pypi::Metadatum.count }.by(0)
        expect(response).to have_gitlab_http_status(:created)
      end

      context 'marked as pending_destruction' do
        it 'does create a new package', :aggregate_failures do
          existing_package.pending_destruction!
          expect { subject }
            .to change { Packages::Pypi::Package.for_projects(project).count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)
            .and change { Packages::Pypi::Metadatum.count }.by(1)
          expect(response).to have_gitlab_http_status(:created)
        end
      end
    end

    context 'with package protection rule for different roles and package_name_patterns' do
      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule, package_type: :pypi, project: project)
      end

      let(:pypi_package_name) { base_params[:name] }
      let(:pypi_package_name_no_match) { "#{pypi_package_name}_no_match" }

      let(:headers) { basic_auth_header(user.username, personal_access_token.token).merge(workhorse_headers) }

      before do
        package_protection_rule.update!(
          package_name_pattern: package_name_pattern,
          minimum_access_level_for_push: minimum_access_level_for_push
        )
      end

      shared_examples 'protected package' do |user_role, expected_status|
        before do
          project.send("add_#{user_role}", user)
        end

        it_behaves_like 'returning response status', expected_status

        it 'does not create any pypi-related package records' do
          expect { subject }
            .to not_change { Packages::Package.count }
            .and not_change { Packages::Package.pypi.count }
            .and not_change { Packages::PackageFile.count }
        end
      end

      where(:package_name_pattern, :minimum_access_level_for_push, :shared_examples_name, :user_role, :expected_status) do
        ref(:pypi_package_name)          | :maintainer | 'protected package'     | :developer  | :forbidden
        ref(:pypi_package_name)          | :maintainer | 'PyPI package creation' | :owner      | :created
        ref(:pypi_package_name)          | :maintainer | 'PyPI package creation' | :maintainer | :created
        ref(:pypi_package_name)          | :maintainer | 'PyPI package creation' | :admin      | :created
        ref(:pypi_package_name)          | :owner      | 'protected package'     | :maintainer | :forbidden
        ref(:pypi_package_name)          | :owner      | 'PyPI package creation' | :owner      | :created
        ref(:pypi_package_name)          | :owner      | 'PyPI package creation' | :admin      | :created
        ref(:pypi_package_name)          | :admin      | 'protected package'     | :owner      | :forbidden
        ref(:pypi_package_name)          | :admin      | 'PyPI package creation' | :admin      | :created

        ref(:pypi_package_name_no_match) | :maintainer | 'PyPI package creation' | :owner      | :created
        ref(:pypi_package_name_no_match) | :admin      | 'PyPI package creation' | :owner      | :created
      end

      with_them do
        if params[:user_role] == :admin
          let_it_be(:user) { create(:admin) }
          let_it_be(:personal_access_token) { create(:personal_access_token, user: user, scopes: [:api, :admin_mode]) }

          it_behaves_like params[:shared_examples_name], :anonymous, params[:expected_status], false
        else
          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status]
        end
      end
    end
  end

  context 'file download endpoint' do
    let_it_be(:package_name) { 'Dummy-Package' }
    let_it_be(:package) { create(:pypi_package, project: project, name: package_name, version: '1.0.0') }

    let(:snowplow_gitlab_standard_context) do
      if user_role == :anonymous || (visibility_level == :public && !user_token)
        { project: project, namespace: project.namespace, property: 'i_package_pypi_user' }
      else
        { project: project, namespace: project.namespace, property: 'i_package_pypi_user', user: user }
      end
    end

    subject(:request) { get api(url), headers: headers }

    describe 'GET /api/v4/groups/:id/-/packages/pypi/files/:sha256/*file_identifier' do
      let(:url) { "/groups/#{group.id}/-/packages/pypi/files/#{package.package_files.first.file_sha256}/#{package_name}-1.0.0.tar.gz" }

      it_behaves_like 'enforcing read_packages job token policy'
      it_behaves_like 'pypi file download endpoint'
      it_behaves_like 'rejects PyPI access with unknown group id'
      it_behaves_like 'a pypi user namespace endpoint'
    end

    describe 'GET /api/v4/projects/:id/packages/pypi/files/:sha256/*file_identifier' do
      let(:url) { "/projects/#{project.id}/packages/pypi/files/#{package.package_files.first.file_sha256}/#{package_name}-1.0.0.tar.gz" }

      it_behaves_like 'enforcing read_packages job token policy'
      it_behaves_like 'pypi file download endpoint'
      it_behaves_like 'rejects PyPI access with unknown project id'
      it_behaves_like 'allow access for everyone with public package_registry_access_level'
    end
  end
end
