# frozen_string_literal: true

RSpec.shared_context 'Composer user type' do |member_role: nil|
  before do
    if member_role
      group.send("add_#{member_role}", user)
      project.send("add_#{member_role}", user)
    end
  end
end

RSpec.shared_examples 'Composer package index with version' do |schema_path, expected_status|
  it 'returns the package index' do
    subject

    expect(response).to have_gitlab_http_status(expected_status)

    if expected_status == :success
      expect(response).to match_response_schema(schema_path)
      expect(json_response).to eq presenter.root
    end
  end
end

RSpec.shared_examples 'Composer package index' do |member_role:, expected_status:, package_returned:|
  include_context 'Composer user type', member_role: member_role do
    let_it_be(:expected_packages) { package_returned ? [package] : [] }
    let_it_be(:presenter) { ::Packages::Composer::PackagesPresenter.new(group, expected_packages) }

    it_behaves_like 'Composer package index with version', 'public_api/v4/packages/composer/index', expected_status

    context 'with version 2' do
      let_it_be(:presenter) { ::Packages::Composer::PackagesPresenter.new(group, expected_packages, true) }
      let(:headers) { super().merge('User-Agent' => 'Composer/2.0.9 (Darwin; 19.6.0; PHP 7.4.8; cURL 7.71.1)') }

      it_behaves_like 'Composer package index with version', 'public_api/v4/packages/composer/index_v2', expected_status
    end
  end
end

RSpec.shared_examples 'Composer empty provider index' do |member_role:, expected_status:|
  include_context 'Composer user type', member_role: member_role do
    it 'returns the package index' do
      subject

      expect(response).to have_gitlab_http_status(status)
      expect(response).to match_response_schema('public_api/v4/packages/composer/provider')
      expect(json_response['providers']).to eq({})
    end
  end
end

RSpec.shared_examples 'Composer provider index' do |member_role:, expected_status:|
  include_context 'Composer user type', member_role: member_role do
    it 'returns the package index' do
      subject

      expect(response).to have_gitlab_http_status(expected_status)
      expect(response).to match_response_schema('public_api/v4/packages/composer/provider')
      expect(json_response['providers']).to include(package.name)
    end
  end
end

RSpec.shared_examples 'Composer package api request' do |member_role:, expected_status:|
  include_context 'Composer user type', member_role: member_role do
    it 'returns the package index' do
      subject

      expect(response).to have_gitlab_http_status(expected_status)
      expect(response).to match_response_schema('public_api/v4/packages/composer/package')
      expect(json_response['packages']).to include(package.name)
      expect(json_response['packages'][package.name]).to include(package.version)
    end
  end
end

RSpec.shared_examples 'Composer package creation' do |expected_status:, member_role: nil|
  include_context 'Composer user type', member_role: member_role do
    it 'creates package files' do
      expect { subject }
        .to change { ::Packages::Composer::Package.for_projects(project).count }.by(1)

      expect(response).to have_gitlab_http_status(expected_status)
    end

    it_behaves_like 'a package tracking event', described_class.name, 'push_package'

    context 'when package creation fails' do
      before do
        allow_next_instance_of(::Packages::Composer::CreatePackageService) do |create_package_service|
          allow(create_package_service).to receive(:execute).and_raise(StandardError)
        end
      end

      it_behaves_like 'not a package tracking event'
    end
  end
end

RSpec.shared_examples 'process Composer api request' do |expected_status:, member_role: nil, **extra|
  include_context 'Composer user type', member_role: member_role do
    it_behaves_like 'returning response status', expected_status
    it_behaves_like 'bumping the package last downloaded at field' if expected_status == :success
  end
end

RSpec.shared_context 'Composer auth headers' do |token_type:, valid_token:, auth_method: :token|
  let(:headers) do
    if token_type == :user
      token = valid_token ? personal_access_token.token : 'wrong'
      auth_method == :token ? { 'Private-Token' => token } : basic_auth_header(user.username, token)
    elsif token_type == :job && valid_token
      auth_method == :token ? { 'Job-Token' => job.token } : job_basic_auth_header(job)
    else
      {} # Anonymous user
    end
  end
end

RSpec.shared_context 'Composer api project access' do |auth_method:, project_visibility_level:, token_type:,
                                                       valid_token: true|
  include_context 'Composer auth headers', auth_method: auth_method, token_type: token_type, valid_token: valid_token do
    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
    end
  end
end

RSpec.shared_context 'Composer api group access' do |auth_method:, project_visibility_level:, token_type:,
                                                     valid_token: true|
  include_context 'Composer auth headers', auth_method: auth_method, token_type: token_type, valid_token: valid_token do
    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
      group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
    end
  end
end

RSpec.shared_examples 'rejects Composer access with unknown group id' do
  context 'with an unknown group' do
    let(:group) { double(id: non_existing_record_id) }

    context 'as anonymous' do
      it_behaves_like 'process Composer api request', expected_status: :unauthorized
    end

    context 'as authenticated user' do
      subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'process Composer api request', expected_status: :not_found
    end
  end
end

RSpec.shared_examples 'rejects Composer access with unknown project id' do
  context 'with an unknown project' do
    let(:project) { double(id: non_existing_record_id) }

    context 'as anonymous' do
      it_behaves_like 'process Composer api request', expected_status: :unauthorized
    end

    context 'as authenticated user' do
      subject { get api(url), params: params, headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'process Composer api request', expected_status: :not_found
    end
  end
end

RSpec.shared_examples 'Composer access with deploy tokens' do
  shared_examples 'a deploy token for Composer GET requests' do
    context 'with deploy token headers' do
      let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token) }

      before do
        group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      context 'valid token' do
        it_behaves_like 'returning response status', :success
      end

      context 'invalid token' do
        let(:headers) { basic_auth_header(deploy_token.username, 'bar') }

        it_behaves_like 'returning response status', :unauthorized
      end
    end
  end

  context 'group deploy token' do
    let(:deploy_token) { deploy_token_for_group }

    it_behaves_like 'a deploy token for Composer GET requests'
  end

  context 'project deploy token' do
    let(:deploy_token) { deploy_token_for_project }

    it_behaves_like 'a deploy token for Composer GET requests'
  end
end

RSpec.shared_examples 'Composer publish with deploy tokens' do
  shared_examples 'a deploy token for Composer publish requests' do
    let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token) }

    context 'valid token' do
      it_behaves_like 'returning response status', :success
    end

    context 'invalid token' do
      let(:headers) { basic_auth_header(deploy_token.username, 'bar') }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  context 'group deploy token' do
    let(:deploy_token) { deploy_token_for_group }

    it_behaves_like 'a deploy token for Composer publish requests'
  end

  context 'group deploy token' do
    let(:deploy_token) { deploy_token_for_project }

    it_behaves_like 'a deploy token for Composer publish requests'
  end
end
