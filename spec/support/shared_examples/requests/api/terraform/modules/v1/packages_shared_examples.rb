# frozen_string_literal: true

RSpec.shared_examples 'when package feature is disabled' do
  before do
    stub_config(packages: { enabled: false })
  end

  it_behaves_like 'returning response status', :not_found
end

RSpec.shared_examples 'without authentication' do
  it_behaves_like 'returning response status', :unauthorized
end

RSpec.shared_examples 'with authentication' do
  where(:user_role, :token_header, :token_type, :valid_token, :status) do
    :guest     | 'PRIVATE-TOKEN' | :personal_access_token   | true  | :not_found
    :guest     | 'PRIVATE-TOKEN' | :personal_access_token   | false | :unauthorized
    :guest     | 'DEPLOY-TOKEN'  | :deploy_token            | true  | :not_found
    :guest     | 'DEPLOY-TOKEN'  | :deploy_token            | false | :unauthorized
    :guest     | 'JOB-TOKEN'     | :job_token               | true  | :not_found
    :guest     | 'JOB-TOKEN'     | :job_token               | false | :unauthorized
    :reporter  | 'PRIVATE-TOKEN' | :personal_access_token   | true  | :not_found
    :reporter  | 'PRIVATE-TOKEN' | :personal_access_token   | false | :unauthorized
    :reporter  | 'DEPLOY-TOKEN'  | :deploy_token            | true  | :not_found
    :reporter  | 'DEPLOY-TOKEN'  | :deploy_token            | false | :unauthorized
    :reporter  | 'JOB-TOKEN'     | :job_token               | true  | :not_found
    :reporter  | 'JOB-TOKEN'     | :job_token               | false | :unauthorized
    :developer | 'PRIVATE-TOKEN' | :personal_access_token   | true  | :not_found
    :developer | 'PRIVATE-TOKEN' | :personal_access_token   | false | :unauthorized
    :developer | 'DEPLOY-TOKEN'  | :deploy_token            | true  | :not_found
    :developer | 'DEPLOY-TOKEN'  | :deploy_token            | false | :unauthorized
    :developer | 'JOB-TOKEN'     | :job_token               | true  | :not_found
    :developer | 'JOB-TOKEN'     | :job_token               | false | :unauthorized
  end

  with_them do
    before do
      project.send("add_#{user_role}", user) unless user_role == :anonymous
    end

    let(:token) { valid_token ? tokens[token_type] : 'invalid-token123' }
    let(:headers) { { token_header => token } }

    it_behaves_like 'returning response status', params[:status]
  end
end

RSpec.shared_examples 'an unimplemented route' do
  it_behaves_like 'without authentication'
  it_behaves_like 'with authentication'
  it_behaves_like 'when package feature is disabled'
end

RSpec.shared_examples 'redirects to version download' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'returns a valid response' do
      subject

      expect(request.url).to include "#{package.name}/download"
      expect(response.headers).to include 'Location'
      expect(response.headers['Location']).to include "#{package.name}/1.0.1/download"
    end
  end
end

RSpec.shared_examples 'grants terraform module download' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'returns a valid response' do
      subject

      expect(response.headers).to include 'X-Terraform-Get'
    end
  end
end

RSpec.shared_examples 'returns terraform module packages' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'returning a valid response' do
      subject

      expect(json_response).to match_schema('public_api/v4/packages/terraform/modules/v1/versions')
    end
  end
end

RSpec.shared_examples 'returns terraform module version' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'returning a valid response' do
      subject

      expect(json_response).to match_schema('public_api/v4/packages/terraform/modules/v1/single_version')
    end
  end
end

RSpec.shared_examples 'returns no terraform module packages' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'returns a response with no versions' do
      subject

      expect(json_response['modules'][0]['versions'].size).to eq(0)
    end
  end
end

RSpec.shared_examples 'grants terraform module packages access' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status
  end
end

RSpec.shared_examples 'grants terraform module package file access' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'a package tracking event', described_class.name, 'pull_package'

    it 'returns a valid response' do
      subject

      expect(response).to have_gitlab_http_status(status)
      expect(response.media_type).to eq('application/octet-stream')
      expect(response.body).to eq(package.package_files.last.file.read)
    end
  end
end

RSpec.shared_examples 'rejects terraform module packages access' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status
  end
end

RSpec.shared_examples 'process terraform module workhorse authorization' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'has the proper content type' do
      subject

      expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
    end

    context 'with a request that bypassed gitlab-workhorse' do
      let(:headers) do
        { 'HTTP_PRIVATE_TOKEN' => personal_access_token.token }
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

RSpec.shared_examples 'process terraform module upload' do |user_type, status, add_member = true|
  RSpec.shared_examples 'creates terraform module package files' do
    it 'creates package files', :aggregate_failures do
      expect { subject }
          .to change { project.packages.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)
      expect(response).to have_gitlab_http_status(status)

      package_file = project.packages.last.package_files.reload.last
      expect(package_file.file_name).to eq('mymodule-mysystem-1.0.0.tgz')
    end
  end

  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
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
        it_behaves_like 'creates terraform module package files'
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
      let(:params) { { file: fog_file, 'file.remote_id' => file_name } }

      context 'and direct upload enabled' do
        let(:fog_connection) do
          stub_package_file_object_storage(direct_upload: true)
        end

        it_behaves_like 'creates terraform module package files'

        ['123123', '../../123123'].each do |remote_id|
          context "with invalid remote_id: #{remote_id}" do
            let(:params) do
              {
                file: fog_file,
                'file.remote_id' => remote_id
              }
            end

            it_behaves_like 'returning response status', :forbidden
          end
        end
      end

      context 'and direct upload disabled' do
        let(:fog_connection) do
          stub_package_file_object_storage(direct_upload: false)
        end

        it_behaves_like 'creates terraform module package files'
      end
    end
  end
end

RSpec.shared_examples 'handling project level terraform module download requests' do
  using RSpec::Parameterized::TableSyntax
  let(:project_id) { project.id }
  let(:package_name) { package.name }
  let(:url) { "/projects/#{project_id}/packages/terraform/modules/#{package_name}/#{module_version}?archive=tgz" }

  subject { get api(url), headers: headers }

  it { is_expected.to have_request_urgency(:low) }

  context 'with valid project' do
    where(:visibility, :user_role, :member, :token_type, :shared_examples_name, :expected_status) do
      :public  | :anonymous  | false | nil | 'grants terraform module package file access' | :success
      :private | :anonymous  | false | nil | 'rejects terraform module packages access'    | :unauthorized

      :public   | :developer  | true  | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :public   | :guest      | true  | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :public   | :developer  | false | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :public   | :guest      | false | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :private  | :developer  | true  | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :private  | :guest      | true  | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :private  | :developer  | false | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :private  | :guest      | false | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :internal | :developer  | true  | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :internal | :guest      | true  | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :internal | :developer  | false | :invalid  | 'rejects terraform module packages access'    | :unauthorized
      :internal | :guest      | false | :invalid  | 'rejects terraform module packages access'    | :unauthorized

      :public   | :developer | true  | :personal_access_token | 'grants terraform module package file access' | :success
      :public   | :guest     | true  | :personal_access_token | 'grants terraform module package file access' | :success
      :public   | :developer | false | :personal_access_token | 'grants terraform module package file access' | :success
      :public   | :guest     | false | :personal_access_token | 'grants terraform module package file access' | :success
      :private  | :developer | true  | :personal_access_token | 'grants terraform module package file access' | :success
      :private  | :guest     | true  | :personal_access_token | 'grants terraform module package file access' | :success
      :private  | :developer | false | :personal_access_token | 'rejects terraform module packages access'  | :not_found
      :private  | :guest     | false | :personal_access_token | 'rejects terraform module packages access'  | :not_found
      :internal | :developer | true  | :personal_access_token | 'grants terraform module package file access' | :success
      :internal | :guest     | true  | :personal_access_token | 'grants terraform module package file access' | :success
      :internal | :developer | false | :personal_access_token | 'grants terraform module package file access' | :success
      :internal | :guest     | false | :personal_access_token | 'grants terraform module package file access' | :success

      :public   | :developer  | true  | :job_token  | 'grants terraform module package file access' | :success
      :public   | :guest      | true  | :job_token  | 'grants terraform module package file access' | :success
      :public   | :developer  | false | :job_token  | 'grants terraform module package file access' | :success
      :public   | :guest      | false | :job_token  | 'grants terraform module package file access' | :success
      :private  | :developer  | true  | :job_token  | 'grants terraform module package file access' | :success
      :private  | :guest      | true  | :job_token  | 'grants terraform module package file access' | :success
      :private  | :developer  | false | :job_token  | 'rejects terraform module packages access'    | :not_found
      :private  | :guest      | false | :job_token  | 'rejects terraform module packages access'    | :not_found
      :internal | :developer  | true  | :job_token  | 'grants terraform module package file access' | :success
      :internal | :guest      | true  | :job_token  | 'grants terraform module package file access' | :success
      :internal | :developer  | false | :job_token  | 'grants terraform module package file access' | :success
      :internal | :guest      | false | :job_token  | 'grants terraform module package file access' | :success

      :public   | :anonymous  | false | :deploy_token | 'grants terraform module package file access' | :success
      :private  | :anonymous  | false | :deploy_token | 'grants terraform module package file access' | :success
      :internal | :anonymous  | false | :deploy_token | 'grants terraform module package file access' | :success
    end

    with_them do
      let(:headers) do
        case token_type
        when :personal_access_token, :invalid
          basic_auth_headers(user.username, token)
        when :deploy_token
          basic_auth_headers(deploy_token.username, token)
        when :job_token
          basic_auth_headers(::Gitlab::Auth::CI_JOB_USER, token)
        else
          {}
        end
      end

      let(:snowplow_gitlab_standard_context) do
        {
          project: project,
          namespace: project.namespace,
          property: 'i_package_terraform_module_user'
        }.tap do |context|
          context[:user] = user if token_type && token_type != :deploy_token
          context[:user] = deploy_token if token_type == :deploy_token
        end
      end

      before do
        project.update!(visibility: visibility.to_s)
      end

      it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
    end
  end

  context 'with/without module version' do
    let(:headers) { basic_auth_headers }
    let(:finder_params) do
      { package_name: package_name }.tap do |p|
        p[:package_version] = module_version if module_version
      end
    end

    before do
      project.add_developer(user)
    end

    it 'calls the finder with the correct params' do
      expect_next_instance_of(::Packages::TerraformModule::PackagesFinder, project, finder_params) do |finder|
        expect(finder).to receive(:execute).and_call_original
      end

      subject
    end
  end

  context 'with non-existent module version' do
    let(:headers) { basic_auth_headers }
    let(:module_version) { '1.99.322' }

    before do
      project.add_developer(user)
    end

    it_behaves_like 'returning response status', :not_found
  end

  context 'with invalid project' do
    let(:project_id) { '123456' }

    let(:headers) { basic_auth_headers }

    it_behaves_like 'rejects terraform module packages access', :anonymous, :not_found
  end

  context 'with invalid package name' do
    let(:headers) { basic_auth_headers }

    [nil, '', '%20', 'unknown', '..%2F..', '../..'].each do |pkg_name|
      context "with package name #{pkg_name}" do
        let(:package_name) { pkg_name }

        before do
          # TODO: remove spec once the feature flag is removed
          # https://gitlab.com/gitlab-org/gitlab/-/issues/415460
          stub_feature_flags(check_path_traversal_middleware_reject_requests: false)
        end

        it_behaves_like 'rejects terraform module packages access', :anonymous, :not_found
      end
    end
  end

  context 'when terraform-get param is received' do
    let(:headers) { basic_auth_headers }
    let(:url) { "#{super().split('?').first}?terraform-get=1" }

    before do
      project.add_developer(user)
    end

    it 'returns a valid response' do
      subject

      expect(response.headers).to include 'X-Terraform-Get'
      expect(response.headers['X-Terraform-Get']).to include '?archive=tgz'
      expect(response.headers['X-Terraform-Get']).not_to include 'terraform-get=1'
    end
  end

  it_behaves_like 'accessing a public/internal project with another project\'s job token' do
    let(:headers) { basic_auth_headers(::Gitlab::Auth::CI_JOB_USER, token) }
  end

  def basic_auth_headers(username = user.username, password = personal_access_token.token)
    { Authorization: "Basic #{Base64.strict_encode64("#{username}:#{password}")}" }
  end
end

RSpec.shared_examples 'accessing a public/internal project with another project\'s job token' do |status = :success|
  let_it_be(:other_project) { create(:project, namespace: group) }
  let(:token) { job.token }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  %w[internal public].each do |visibility|
    context "when the project is #{visibility}" do
      before do
        job.update!(project: other_project)
        group.update!(visibility: visibility)
        project.update!(visibility: visibility)
      end

      it_behaves_like 'returning response status', status
    end
  end
end

RSpec.shared_examples 'allowing anyone to pull public terraform modules' do |status = :success|
  let(:headers) { {} }

  before do
    [group, project].each { |e| e.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE) }
    project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
  end

  it_behaves_like 'returning response status', status
end
