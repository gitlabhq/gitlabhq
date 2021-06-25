# frozen_string_literal: true

RSpec.shared_examples 'rejects helm packages access' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
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

RSpec.shared_examples 'process helm service index request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'returns a valid YAML response', :aggregate_failures do
      subject

      expect(response.media_type).to eq('text/yaml')
      expect(response.body).to start_with("---\napiVersion: v1\nentries:\n")

      yaml_response = YAML.safe_load(response.body)

      expect(yaml_response.keys).to contain_exactly('apiVersion', 'entries', 'generated', 'serverInfo')
      expect(yaml_response['entries']).to be_a(Hash)
      expect(yaml_response['entries'].keys).to contain_exactly(package.name)
      expect(yaml_response['serverInfo']).to eq({ 'contextPath' => "http://localhost/api/v4/projects/#{project.id}/packages/helm" })

      package_entry = yaml_response['entries'][package.name]

      expect(package_entry.length).to eq(1)
      expect(package_entry.first.keys).to contain_exactly('name', 'version', 'apiVersion', 'created', 'digest', 'urls')
      expect(package_entry.first['digest']).to eq('fd2b2fa0329e80a2a602c2bb3b40608bcd6ee5cf96cf46fd0d2800a4c129c9db')
      expect(package_entry.first['urls']).to eq(["charts/#{package.name}-#{package.version}.tgz"])
    end
  end
end

RSpec.shared_examples 'process helm download content request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'a package tracking event', 'API::HelmPackages', 'pull_package'

    it 'returns a valid package archive' do
      subject

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

RSpec.shared_examples 'handling helm chart index requests' do |anonymous_requests_example_name: 'process helm service index request', anonymous_requests_status: :success|
  context 'with valid project' do
    using RSpec::Parameterized::TableSyntax

    context 'personal token' do
      where(:visibility, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | true  | 'process helm service index request' | :success
        :public  | :guest      | true  | true  | 'process helm service index request' | :success
        :public  | :developer  | true  | false | 'rejects helm packages access'       | :unauthorized
        :public  | :guest      | true  | false | 'rejects helm packages access'       | :unauthorized
        :public  | :developer  | false | true  | 'process helm service index request' | :success
        :public  | :guest      | false | true  | 'process helm service index request' | :success
        :public  | :developer  | false | false | 'rejects helm packages access'       | :unauthorized
        :public  | :guest      | false | false | 'rejects helm packages access'       | :unauthorized
        :public  | :anonymous  | false | true  | anonymous_requests_example_name      | anonymous_requests_status
        :private | :developer  | true  | true  | 'process helm service index request' | :success
        :private | :guest      | true  | true  | 'rejects helm packages access'       | :forbidden
        :private | :developer  | true  | false | 'rejects helm packages access'       | :unauthorized
        :private | :guest      | true  | false | 'rejects helm packages access'       | :unauthorized
        :private | :developer  | false | true  | 'rejects helm packages access'       | :not_found
        :private | :guest      | false | true  | 'rejects helm packages access'       | :not_found
        :private | :developer  | false | false | 'rejects helm packages access'       | :unauthorized
        :private | :guest      | false | false | 'rejects helm packages access'       | :unauthorized
        :private | :anonymous  | false | true  | 'rejects helm packages access'       | :unauthorized
      end

      with_them do
        let(:token) { user_token ? personal_access_token.token : 'wrong' }
        let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }

        subject { get api(url), headers: headers }

        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    context 'with job token' do
      where(:visibility, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | true  | 'process helm service index request' | :success
        :public  | :guest      | true  | true  | 'process helm service index request' | :success
        :public  | :developer  | true  | false | 'rejects helm packages access'       | :unauthorized
        :public  | :guest      | true  | false | 'rejects helm packages access'       | :unauthorized
        :public  | :developer  | false | true  | 'process helm service index request' | :success
        :public  | :guest      | false | true  | 'process helm service index request' | :success
        :public  | :developer  | false | false | 'rejects helm packages access'       | :unauthorized
        :public  | :guest      | false | false | 'rejects helm packages access'       | :unauthorized
        :public  | :anonymous  | false | true  | anonymous_requests_example_name      | anonymous_requests_status
        :private | :developer  | true  | true  | 'process helm service index request' | :success
        :private | :guest      | true  | true  | 'rejects helm packages access'       | :forbidden
        :private | :developer  | true  | false | 'rejects helm packages access'       | :unauthorized
        :private | :guest      | true  | false | 'rejects helm packages access'       | :unauthorized
        :private | :developer  | false | true  | 'rejects helm packages access'       | :not_found
        :private | :guest      | false | true  | 'rejects helm packages access'       | :not_found
        :private | :developer  | false | false | 'rejects helm packages access'       | :unauthorized
        :private | :guest      | false | false | 'rejects helm packages access'       | :unauthorized
        :private | :anonymous  | false | true  | 'rejects helm packages access'       | :unauthorized
      end

      with_them do
        let_it_be(:ci_build) { create(:ci_build, project: project, user: user, status: :running) }

        let(:job) { user_token ? ci_build : double(token: 'wrong') }
        let(:headers) { user_role == :anonymous ? {} : job_basic_auth_header(job) }

        subject { get api(url), headers: headers }

        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end
  end

  it_behaves_like 'deploy token for package GET requests'

  it_behaves_like 'rejects helm access with unknown project id' do
    subject { get api(url) }
  end
end
