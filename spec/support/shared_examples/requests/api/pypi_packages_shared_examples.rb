# frozen_string_literal: true

RSpec.shared_examples 'PyPI package creation' do |user_type, status, add_member = true, md5_digest = true|
  RSpec.shared_examples 'creating pypi package files' do
    it 'creates package files' do
      expect { subject }
          .to change { Packages::Pypi::Package.for_projects(project).count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)
          .and change { Packages::Pypi::Metadatum.count }.by(1)
      expect(response).to have_gitlab_http_status(status)

      package = project.reload.packages.pypi.last

      expect(package.name).to eq params[:name]
      expect(package.version).to eq params[:version]
      expect(package.pypi_metadatum.required_python).to eq params[:requires_python]
      expect(package.package_files.first.file_sha256).to eq params[:sha256_digest]

      if md5_digest
        expect(package.package_files.first.file_md5).to be_present
      else
        expect(package.package_files.first.file_md5).to be_nil
      end
    end
  end

  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'creating pypi package files'

    context 'with a pre-existing file' do
      it 'rejects the duplicated file' do
        existing_package = create(:pypi_package, name: base_params[:name], version: base_params[:version], project: project)
        create(:package_file, :pypi, package: existing_package, file_name: params[:content].original_filename)

        expect { subject }
            .to change { Packages::Pypi::Package.for_projects(project).count }.by(0)
            .and change { Packages::PackageFile.count }.by(0)
            .and change { Packages::Pypi::Metadatum.count }.by(0)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with object storage disabled' do
      before do
        stub_package_file_object_storage(enabled: false)
      end

      context 'without a file from workhorse' do
        let(:send_rewritten_field) { false }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with correct params' do
        it_behaves_like 'package workhorse uploads'
        it_behaves_like 'creating pypi package files'
        it_behaves_like 'a package tracking event', described_class.name, 'push_package'
      end
    end

    context 'with object storage enabled' do
      let(:tmp_object) do
        fog_connection.directories.new(key: 'packages').files.create( # rubocop:disable Rails/SaveBang
          key: "tmp/uploads/#{file_name}",
          body: 'content'
        )
      end

      let(:fog_file) { fog_to_uploaded_file(tmp_object) }
      let(:params) { base_params.merge(content: fog_file, 'content.remote_id' => file_name) }

      context 'and direct upload enabled' do
        let(:fog_connection) do
          stub_package_file_object_storage(direct_upload: true)
        end

        it_behaves_like 'creating pypi package files'

        ['123123', '../../123123'].each do |remote_id|
          context "with invalid remote_id: #{remote_id}" do
            let(:params) { base_params.merge(content: fog_file, 'content.remote_id' => remote_id) }

            it_behaves_like 'returning response status', :forbidden
          end
        end
      end

      context 'and direct upload disabled' do
        let(:fog_connection) do
          stub_package_file_object_storage(direct_upload: false)
        end

        it_behaves_like 'creating pypi package files'
      end
    end
  end
end

RSpec.shared_examples 'PyPI package versions' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it 'returns the package listing' do
      subject

      expect(response.body).to match(package.package_files.first.file_name)
    end

    it_behaves_like 'returning response status', status
    it_behaves_like 'a package tracking event', described_class.name, 'list_package'
  end
end

RSpec.shared_examples 'PyPI package index' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it 'returns the package index' do
      subject

      expect(response.body).to match(package.name)
    end

    it_behaves_like 'returning response status', status
  end
end

RSpec.shared_examples 'PyPI package download' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it 'returns the package listing' do
      subject

      expect(response.body).to eq(File.open(package.package_files.first.file.path, "rb").read)
    end

    it_behaves_like 'returning response status', status
    it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
    it_behaves_like 'bumping the package last downloaded at field'
  end
end

RSpec.shared_examples 'rejected package download' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status
  end
end

RSpec.shared_examples 'process PyPI api request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status
  end
end

RSpec.shared_examples 'unknown PyPI scope id' do
  context 'as anonymous' do
    it_behaves_like 'process PyPI api request', :anonymous, :not_found
  end

  context 'as authenticated user' do
    subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

    it_behaves_like 'process PyPI api request', :anonymous, :not_found
  end
end

RSpec.shared_examples 'rejects PyPI access with unknown project id' do
  context 'with an unknown project' do
    let(:project) { double('access', id: 1234567890) }

    it_behaves_like 'unknown PyPI scope id'
  end
end

RSpec.shared_examples 'rejects PyPI access with unknown group id' do
  context 'with an unknown project' do
    let(:group) { double('access', id: 1234567890) }

    it_behaves_like 'unknown PyPI scope id'
  end
end

RSpec.shared_examples 'allow access for everyone with public package_registry_access_level' do
  context 'with private project but public access to package registry' do
    before do
      project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
    end

    context 'as non-member user' do
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'returning response status', :success
    end

    context 'as anonymous' do
      let(:headers) { {} }

      it_behaves_like 'returning response status', :success
    end
  end
end

RSpec.shared_examples 'pypi simple API endpoint' do
  using RSpec::Parameterized::TableSyntax

  context 'with valid project' do
    where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
      :public  | :developer  | true  | true  | 'PyPI package versions' | :success
      :public  | :guest      | true  | true  | 'PyPI package versions' | :success
      :public  | :developer  | true  | false | 'PyPI package versions' | :success
      :public  | :guest      | true  | false | 'PyPI package versions' | :success
      :public  | :developer  | false | true  | 'PyPI package versions' | :success
      :public  | :guest      | false | true  | 'PyPI package versions' | :success
      :public  | :developer  | false | false | 'PyPI package versions' | :success
      :public  | :guest      | false | false | 'PyPI package versions' | :success
      :public  | :anonymous  | false | true  | 'PyPI package versions' | :success
      :private | :developer  | true  | true  | 'PyPI package versions' | :success
      :private | :guest      | true  | true  | 'PyPI package versions' | :success
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
      let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }
      let(:snowplow_gitlab_standard_context) do
        if user_role == :anonymous || (visibility_level == :public && !user_token)
          snowplow_context
        else
          snowplow_context.merge(user: user)
        end
      end

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
      end

      it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
    end
  end

  context 'with a normalized package name' do
    let_it_be(:package) { create(:pypi_package, project: project, name: 'my.package') }

    let(:url) { "/projects/#{project.id}/packages/pypi/simple/my-package" }
    let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
    let(:snowplow_gitlab_standard_context) { snowplow_context.merge({ project: project, user: user }) }

    it_behaves_like 'PyPI package versions', :developer, :success
  end

  context 'package request forward' do
    include_context 'dependency proxy helpers context'

    where(:forward, :package_in_project, :shared_examples_name, :expected_status) do
      true  | true  | 'PyPI package versions'    | :success
      true  | false | 'process PyPI api request' | :redirect
      false | true  | 'PyPI package versions'    | :success
      false | false | 'process PyPI api request' | :not_found
    end

    with_them do
      let_it_be(:package) { create(:pypi_package, project: project, name: 'foobar') }

      let(:package_name) do
        if package_in_project
          'foobar'
        else
          'barfoo'
        end
      end

      before do
        allow_fetch_cascade_application_setting(attribute: "pypi_package_requests_forwarding", return_value: forward)
      end

      it_behaves_like params[:shared_examples_name], :reporter, params[:expected_status]
    end
  end
end

RSpec.shared_examples 'pypi simple index API endpoint' do
  using RSpec::Parameterized::TableSyntax

  context 'with valid project' do
    where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
      :public  | :developer  | true  | true  | 'PyPI package index' | :success
      :public  | :guest      | true  | true  | 'PyPI package index' | :success
      :public  | :developer  | true  | false | 'PyPI package index' | :success
      :public  | :guest      | true  | false | 'PyPI package index' | :success
      :public  | :developer  | false | true  | 'PyPI package index' | :success
      :public  | :guest      | false | true  | 'PyPI package index' | :success
      :public  | :developer  | false | false | 'PyPI package index' | :success
      :public  | :guest      | false | false | 'PyPI package index' | :success
      :public  | :anonymous  | false | true  | 'PyPI package index' | :success
      :private | :developer  | true  | true  | 'PyPI package index' | :success
      :private | :guest      | true  | true  | 'PyPI package index' | :success
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
      let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
      end

      it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
    end
  end
end

RSpec.shared_examples 'pypi file download endpoint' do
  using RSpec::Parameterized::TableSyntax

  context 'with valid project' do
    where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
      :public  | :developer  | true  | true  | 'PyPI package download'     | :success
      :public  | :guest      | true  | true  | 'PyPI package download'     | :success
      :public  | :developer  | true  | false | 'PyPI package download'     | :success
      :public  | :guest      | true  | false | 'PyPI package download'     | :success
      :public  | :developer  | false | true  | 'PyPI package download'     | :success
      :public  | :guest      | false | true  | 'PyPI package download'     | :success
      :public  | :developer  | false | false | 'PyPI package download'     | :success
      :public  | :guest      | false | false | 'PyPI package download'     | :success
      :public  | :anonymous  | false | true  | 'PyPI package download'     | :success
      :private | :developer  | true  | true  | 'PyPI package download'     | :success
      :private | :guest      | true  | true  | 'PyPI package download'     | :success
      :private | :developer  | true  | false | 'rejected package download' | :unauthorized
      :private | :guest      | true  | false | 'rejected package download' | :unauthorized
      :private | :developer  | false | true  | 'rejected package download' | :not_found
      :private | :guest      | false | true  | 'rejected package download' | :not_found
      :private | :developer  | false | false | 'rejected package download' | :unauthorized
      :private | :guest      | false | false | 'rejected package download' | :unauthorized
      :private | :anonymous  | false | true  | 'rejected package download' | :unauthorized
    end

    with_them do
      let(:token) { user_token ? personal_access_token.token : 'wrong' }
      let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
      end

      it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
    end
  end

  context 'with deploy token headers' do
    let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token) }

    context 'valid token' do
      it_behaves_like 'returning response status', :success
    end

    context 'invalid token' do
      let(:headers) { basic_auth_header('foo', 'bar') }

      it_behaves_like 'returning response status', :success
    end
  end

  context 'with job token headers' do
    let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, job.token) }

    context 'valid token' do
      it_behaves_like 'returning response status', :success
    end

    context 'invalid token' do
      let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, 'bar') }

      it_behaves_like 'returning response status', :unauthorized
    end

    context 'invalid user' do
      let(:headers) { basic_auth_header('foo', job.token) }

      it_behaves_like 'returning response status', :success
    end
  end
end

RSpec.shared_examples 'a pypi user namespace endpoint' do
  using RSpec::Parameterized::TableSyntax

  # only group namespaces are supported at this time
  where(:visibility_level, :user_role, :expected_status) do
    :public  | :owner     | :not_found
    :private | :owner     | :not_found
    :public  | :external  | :not_found
    :private | :external  | :not_found
    :public  | :anonymous | :not_found
    :private | :anonymous | :not_found
  end

  with_them do
    # only groups are supported, so this "group" is actually the wrong namespace type
    let_it_be_with_reload(:group) { create(:user_namespace) }
    let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, personal_access_token.token) }

    before do
      group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
      group.update_column(:owner_id, user.id) if user_role == :owner
    end

    it_behaves_like 'returning response status', params[:expected_status]
  end
end
