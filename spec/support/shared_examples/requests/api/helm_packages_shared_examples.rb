# frozen_string_literal: true

RSpec.shared_examples 'rejects helm packages access' do |user_type, status|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if user_type != :anonymous && user_type != :not_a_member
    end

    it_behaves_like 'returning response status', status

    if status == :unauthorized
      it 'has the correct response header' do
        subject

        expect(response.headers['WWW-Authenticate']).to eq 'Basic realm="GitLab Packages Registry"'
      end
    end
  end
end

RSpec.shared_examples 'process helm service index request' do |user_type, status|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if user_type != :anonymous && user_type != :not_a_member
    end

    it 'returns a valid YAML response', :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(status)

      expect(response.media_type).to eq('text/yaml')
      expect(response.body).to start_with("---\napiVersion: v1\nentries:\n")

      yaml_response = YAML.safe_load(response.body)

      expect(yaml_response.keys).to contain_exactly('apiVersion', 'entries', 'generated', 'serverInfo')
      expect(yaml_response['entries']).to be_a(Hash)
      expect(yaml_response['entries'].keys).to contain_exactly(package.name)
      expect(yaml_response['serverInfo']).to eq({ 'contextPath' => "/api/v4/projects/#{project.id}/packages/helm" })

      package_entry = yaml_response['entries'][package.name]

      expect(package_entry.length).to eq(1)
      expect(package_entry.first.keys).to contain_exactly('name', 'version', 'apiVersion', 'created', 'digest', 'urls')
      expect(package_entry.first['digest']).to eq('fd2b2fa0329e80a2a602c2bb3b40608bcd6ee5cf96cf46fd0d2800a4c129c9db')
      expect(package_entry.first['urls']).to eq(["charts/#{package.name}-#{package.version}.tgz"])
    end
  end
end

RSpec.shared_examples 'process helm workhorse authorization' do |user_type, status, test_bypass: false|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if user_type != :anonymous && user_type != :not_a_member
    end

    it 'has the proper status and content type' do
      subject

      expect(response).to have_gitlab_http_status(status)
      expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
    end

    context 'with a request that bypassed gitlab-workhorse' do
      let(:headers) do
        basic_auth_header(user.username, personal_access_token.token)
          .merge(workhorse_headers)
          .tap { |h| h.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER) }
      end

      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'returning response status', :forbidden
    end
  end
end

RSpec.shared_examples 'process helm upload' do |user_type, status|
  shared_examples 'creates helm package files' do
    it 'creates package files' do
      expect(::Packages::Helm::ExtractionWorker).to receive(:perform_async).once
      expect { subject }
          .to change { project.packages.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)
      expect(response).to have_gitlab_http_status(status)

      package_file = project.packages.last.package_files.reload.last
      expect(package_file.file_name).to eq('package.tgz')
    end
  end

  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if user_type != :anonymous && user_type != :not_a_member
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
        it_behaves_like 'creates helm package files'
        it_behaves_like 'a package tracking event', 'API::HelmPackages', 'push_package'
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
      let(:params) { { chart: fog_file, 'chart.remote_id' => file_name } }

      context 'and direct upload enabled' do
        let(:fog_connection) do
          stub_package_file_object_storage(direct_upload: true)
        end

        it_behaves_like 'creates helm package files'

        ['123123', '../../123123'].each do |remote_id|
          context "with invalid remote_id: #{remote_id}" do
            let(:params) do
              {
                chart: fog_file,
                'chart.remote_id' => remote_id
              }
            end

            it_behaves_like 'returning response status', :forbidden
          end
        end
      end

      context 'and direct upload disabled' do
        context 'and background upload disabled' do
          let(:fog_connection) do
            stub_package_file_object_storage(direct_upload: false, background_upload: false)
          end

          it_behaves_like 'creates helm package files'
        end

        context 'and background upload enabled' do
          let(:fog_connection) do
            stub_package_file_object_storage(direct_upload: false, background_upload: true)
          end

          it_behaves_like 'creates helm package files'
        end
      end
    end

    it_behaves_like 'background upload schedules a file migration'
  end
end

RSpec.shared_examples 'process helm download content request' do |user_type, status|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if user_type != :anonymous && user_type != :not_a_member
    end

    it_behaves_like 'a package tracking event', 'API::HelmPackages', 'pull_package'

    it 'returns expected status and a valid package archive' do
      subject

      expect(response).to have_gitlab_http_status(status)
      expect(response.media_type).to eq('application/octet-stream')
    end
  end
end

RSpec.shared_examples 'rejects helm access with unknown project id' do
  context 'with an unknown project' do
    let(:project) { OpenStruct.new(id: 1234567890) }

    context 'as anonymous' do
      it_behaves_like 'rejects helm packages access', :anonymous, :unauthorized
    end

    context 'as authenticated user' do
      subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'rejects helm packages access', :anonymous, :not_found
    end
  end
end

RSpec.shared_examples 'handling helm chart index requests' do
  context 'with valid project' do
    subject { get api(url), headers: headers }

    using RSpec::Parameterized::TableSyntax

    context 'personal token' do
      where(:visibility, :user_role, :shared_examples_name, :expected_status) do
        :public  | :guest        | 'process helm service index request' | :success
        :public  | :not_a_member | 'process helm service index request' | :success
        :public  | :anonymous    | 'process helm service index request' | :success
        :private | :reporter     | 'process helm service index request' | :success
        :private | :guest        | 'rejects helm packages access'       | :forbidden
        :private | :not_a_member | 'rejects helm packages access'       | :not_found
        :private | :anonymous    | 'rejects helm packages access'       | :unauthorized
      end

      with_them do
        let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, personal_access_token.token) }

        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status]
      end
    end

    context 'when an invalid token is passed' do
      let(:headers) { basic_auth_header(user.username, 'wrong') }

      it_behaves_like 'returning response status', :unauthorized
    end

    context 'with job token' do
      where(:visibility, :user_role, :shared_examples_name, :expected_status) do
        :public  | :guest        | 'process helm service index request' | :success
        :public  | :not_a_member | 'process helm service index request' | :success
        :public  | :anonymous    | 'process helm service index request' | :success
        :private | :reporter     | 'process helm service index request' | :success
        :private | :guest        | 'rejects helm packages access'       | :forbidden
        :private | :not_a_member | 'rejects helm packages access'       | :not_found
        :private | :anonymous    | 'rejects helm packages access'       | :unauthorized
      end

      with_them do
        let_it_be(:ci_build) { create(:ci_build, project: project, user: user, status: :running) }

        let(:headers) { user_role == :anonymous ? {} : job_basic_auth_header(ci_build) }

        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status]
      end
    end
  end

  it_behaves_like 'deploy token for package GET requests'

  it_behaves_like 'rejects helm access with unknown project id' do
    subject { get api(url) }
  end
end
