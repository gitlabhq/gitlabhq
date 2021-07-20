# frozen_string_literal: true

RSpec.shared_examples 'rejects nuget packages access' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      target.send("add_#{user_type}", user) if add_member && user_type != :anonymous
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

RSpec.shared_examples 'process nuget service index request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      target.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'a package tracking event', 'API::NugetPackages', 'cli_metadata'

    it 'returns a valid json response' do
      subject

      expect(response.media_type).to eq('application/json')
      expect(json_response).to match_schema('public_api/v4/packages/nuget/service_index')
      expect(json_response).to be_a(Hash)
    end

    context 'with invalid format' do
      let(:url) { "/#{target_type}/#{target.id}/packages/nuget/index.xls" }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end
  end
end

RSpec.shared_examples 'returning nuget metadata json response with json schema' do |json_schema|
  it 'returns a valid json response' do
    subject

    expect(response.media_type).to eq('application/json')
    expect(json_response).to match_schema(json_schema)
    expect(json_response).to be_a(Hash)
  end
end

RSpec.shared_examples 'process nuget metadata request at package name level' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      target.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'returning nuget metadata json response with json schema', 'public_api/v4/packages/nuget/packages_metadata'

    context 'with invalid format' do
      let(:url) { "/#{target_type}/#{target.id}/packages/nuget/metadata/#{package_name}/index.xls" }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end

    context 'with lower case package name' do
      let_it_be(:package_name) { 'dummy.package' }

      it_behaves_like 'returning response status', status

      it_behaves_like 'returning nuget metadata json response with json schema', 'public_api/v4/packages/nuget/packages_metadata'
    end
  end
end

RSpec.shared_examples 'process nuget metadata request at package name and package version level' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      target.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'returning nuget metadata json response with json schema', 'public_api/v4/packages/nuget/package_metadata'

    context 'with invalid format' do
      let(:url) { "/#{target_type}/#{target.id}/packages/nuget/metadata/#{package_name}/#{package.version}.xls" }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end

    context 'with lower case package name' do
      let_it_be(:package_name) { 'dummy.package' }

      it_behaves_like 'returning response status', status

      it_behaves_like 'returning nuget metadata json response with json schema', 'public_api/v4/packages/nuget/package_metadata'
    end
  end
end

RSpec.shared_examples 'process nuget workhorse authorization' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      target.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'has the proper content type' do
      subject

      expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
    end

    context 'with a request that bypassed gitlab-workhorse' do
      let(:headers) do
        basic_auth_header(user.username, personal_access_token.token)
          .merge(workhorse_headers)
          .tap { |h| h.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER) }
      end

      before do
        target.add_maintainer(user)
      end

      it_behaves_like 'returning response status', :forbidden
    end
  end
end

RSpec.shared_examples 'process nuget upload' do |user_type, status, add_member = true, symbol_package = false|
  shared_examples 'creates nuget package files' do
    it 'creates package files' do
      expect(::Packages::Nuget::ExtractionWorker).to receive(:perform_async).once
      expect { subject }
          .to change { target.packages.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)
      expect(response).to have_gitlab_http_status(status)

      package_file = target.packages.last.package_files.reload.last
      expect(package_file.file_name).to eq(file_name)
    end
  end

  context "for user type #{user_type}" do
    before do
      target.send("add_#{user_type}", user) if add_member && user_type != :anonymous
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
        it_behaves_like 'creates nuget package files'

        if symbol_package
          it_behaves_like 'a package tracking event', 'API::NugetPackages', 'push_symbol_package'
        else
          it_behaves_like 'a package tracking event', 'API::NugetPackages', 'push_package'
        end
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
      let(:params) { { package: fog_file, 'package.remote_id' => file_name } }

      context 'and direct upload enabled' do
        let(:fog_connection) do
          stub_package_file_object_storage(direct_upload: true)
        end

        it_behaves_like 'creates nuget package files'

        ['123123', '../../123123'].each do |remote_id|
          context "with invalid remote_id: #{remote_id}" do
            let(:params) do
              {
                package: fog_file,
                'package.remote_id' => remote_id
              }
            end

            it_behaves_like 'returning response status', :forbidden
          end
        end

        context 'with crafted package.path param' do
          let(:crafted_file) { Tempfile.new('nuget.crafted.package.path') }
          let(:url) { "/#{target_type}/#{target.id}/packages/nuget?package.path=#{crafted_file.path}" }
          let(:params) { { file: temp_file(file_name) } }
          let(:file_key) { :file }

          it 'does not create a package file' do
            expect { subject }.to change { ::Packages::PackageFile.count }.by(0)
          end

          it_behaves_like 'returning response status', :bad_request
        end
      end

      context 'and direct upload disabled' do
        context 'and background upload disabled' do
          let(:fog_connection) do
            stub_package_file_object_storage(direct_upload: false, background_upload: false)
          end

          it_behaves_like 'creates nuget package files'
        end

        context 'and background upload enabled' do
          let(:fog_connection) do
            stub_package_file_object_storage(direct_upload: false, background_upload: true)
          end

          it_behaves_like 'creates nuget package files'
        end
      end
    end

    it_behaves_like 'background upload schedules a file migration'
  end
end

RSpec.shared_examples 'process nuget download versions request' do |user_type, status, add_member = true|
  RSpec.shared_examples 'returns a valid nuget download versions json response' do
    it 'returns a valid json response' do
      subject

      expect(response.media_type).to eq('application/json')
      expect(json_response).to match_schema('public_api/v4/packages/nuget/download_versions')
      expect(json_response).to be_a(Hash)
      expect(json_response['versions']).to match_array(packages.map(&:version).sort)
    end
  end

  context "for user type #{user_type}" do
    before do
      target.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'returns a valid nuget download versions json response'

    context 'with invalid format' do
      let(:url) { "/#{target_type}/#{target.id}/packages/nuget/download/#{package_name}/index.xls" }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end

    context 'with lower case package name' do
      let_it_be(:package_name) { 'dummy.package' }

      it_behaves_like 'returning response status', status

      it_behaves_like 'returns a valid nuget download versions json response'
    end
  end
end

RSpec.shared_examples 'process nuget download content request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      target.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'a package tracking event', 'API::NugetPackages', 'pull_package'

    it 'returns a valid package archive' do
      subject

      expect(response.media_type).to eq('application/octet-stream')
    end

    context 'with invalid format' do
      let(:url) { "/#{target_type}/#{target.id}/packages/nuget/download/#{package.name}/#{package.version}/#{package.name}.#{package.version}.xls" }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end

    context 'with symbol package' do
      let(:format) { 'snupkg' }

      it 'returns a valid package archive' do
        subject

        expect(response.media_type).to eq('application/octet-stream')
      end

      it_behaves_like 'a package tracking event', 'API::NugetPackages', 'pull_symbol_package'
    end

    context 'with lower case package name' do
      let_it_be(:package_name) { 'dummy.package' }

      it_behaves_like 'returning response status', status

      it 'returns a valid package archive' do
        subject

        expect(response.media_type).to eq('application/octet-stream')
      end
    end
  end
end

RSpec.shared_examples 'process nuget search request' do |user_type, status, add_member = true|
  RSpec.shared_examples 'returns a valid json search response' do |status, total_hits, versions|
    it_behaves_like 'returning response status', status

    it 'returns a valid json response' do
      subject

      expect(response.media_type).to eq('application/json')
      expect(json_response).to be_a(Hash)
      expect(json_response).to match_schema('public_api/v4/packages/nuget/search')
      expect(json_response['totalHits']).to eq total_hits
      expect(json_response['data'].map { |e| e['versions'].size }).to match_array(versions)
    end
  end

  context "for user type #{user_type}" do
    before do
      target.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returns a valid json search response', status, 4, [1, 5, 5, 1]

    it_behaves_like 'a package tracking event', 'API::NugetPackages', 'search_package'

    context 'with skip set to 2' do
      let(:skip) { 2 }

      it_behaves_like 'returns a valid json search response', status, 4, [5, 1]
    end

    context 'with take set to 2' do
      let(:take) { 2 }

      it_behaves_like 'returns a valid json search response', status, 4, [1, 5]
    end

    context 'without prereleases' do
      let(:include_prereleases) { false }

      it_behaves_like 'returns a valid json search response', status, 3, [1, 5, 5]
    end

    context 'with empty search term' do
      let(:search_term) { '' }

      it_behaves_like 'returns a valid json search response', status, 5, [1, 5, 5, 1, 1]
    end

    context 'with nil search term' do
      let(:search_term) { nil }

      it_behaves_like 'returns a valid json search response', status, 5, [1, 5, 5, 1, 1]
    end
  end
end

RSpec.shared_examples 'rejects nuget access with invalid target id' do
  context 'with a target id with invalid integers' do
    using RSpec::Parameterized::TableSyntax

    let(:target) { OpenStruct.new(id: id) }

    where(:id, :status) do
      '/../'       | :bad_request
      ''           | :not_found
      '%20'        | :bad_request
      '%2e%2e%2f'  | :bad_request
      'NaN'        | :bad_request
      00002345     | :unauthorized
      'anything25' | :bad_request
    end

    with_them do
      it_behaves_like 'rejects nuget packages access', :anonymous, params[:status]
    end
  end
end

RSpec.shared_examples 'rejects nuget access with unknown target id' do
  context 'with an unknown target' do
    let(:target) { OpenStruct.new(id: 1234567890) }

    context 'as anonymous' do
      it_behaves_like 'rejects nuget packages access', :anonymous, :unauthorized
    end

    context 'as authenticated user' do
      subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end
  end
end

RSpec.shared_examples 'nuget authorize upload endpoint' do
  using RSpec::Parameterized::TableSyntax

  context 'with valid project' do
    where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
      'PUBLIC'  | :developer  | true  | true  | 'process nuget workhorse authorization' | :success
      'PUBLIC'  | :guest      | true  | true  | 'rejects nuget packages access'         | :forbidden
      'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access'         | :unauthorized
      'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access'         | :unauthorized
      'PUBLIC'  | :developer  | false | true  | 'rejects nuget packages access'         | :forbidden
      'PUBLIC'  | :guest      | false | true  | 'rejects nuget packages access'         | :forbidden
      'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access'         | :unauthorized
      'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access'         | :unauthorized
      'PUBLIC'  | :anonymous  | false | true  | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :developer  | true  | true  | 'process nuget workhorse authorization' | :success
      'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access'         | :forbidden
      'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access'         | :not_found
      'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access'         | :not_found
      'PRIVATE' | :developer  | false | false | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :guest      | false | false | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access'         | :unauthorized
    end

    with_them do
      let(:token) { user_token ? personal_access_token.token : 'wrong' }
      let(:user_headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }
      let(:headers) { user_headers.merge(workhorse_headers) }

      before do
        update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
      end

      it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
    end
  end

  it_behaves_like 'deploy token for package uploads'

  it_behaves_like 'job token for package uploads', authorize_endpoint: true do
    let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
  end

  it_behaves_like 'rejects nuget access with unknown target id'

  it_behaves_like 'rejects nuget access with invalid target id'
end

RSpec.shared_examples 'nuget upload endpoint' do |symbol_package: false|
  using RSpec::Parameterized::TableSyntax

  context 'with valid project' do
    where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
      'PUBLIC'  | :developer  | true  | true  | 'process nuget upload'          | :created
      'PUBLIC'  | :guest      | true  | true  | 'rejects nuget packages access' | :forbidden
      'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :developer  | false | true  | 'rejects nuget packages access' | :forbidden
      'PUBLIC'  | :guest      | false | true  | 'rejects nuget packages access' | :forbidden
      'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :anonymous  | false | true  | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :developer  | true  | true  | 'process nuget upload'          | :created
      'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access' | :forbidden
      'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access' | :not_found
      'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access' | :not_found
      'PRIVATE' | :developer  | false | false | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :guest      | false | false | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access' | :unauthorized
    end

    with_them do
      let(:token) { user_token ? personal_access_token.token : 'wrong' }
      let(:user_headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }
      let(:headers) { user_headers.merge(workhorse_headers) }
      let(:snowplow_gitlab_standard_context) { { project: project, user: user, namespace: project.namespace } }

      before do
        update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
      end

      it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member], symbol_package
    end
  end

  it_behaves_like 'deploy token for package uploads'

  it_behaves_like 'job token for package uploads' do
    let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
  end

  it_behaves_like 'rejects nuget access with unknown target id'

  it_behaves_like 'rejects nuget access with invalid target id'

  context 'file size above maximum limit' do
    let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_headers) }

    before do
      allow_next_instance_of(UploadedFile) do |uploaded_file|
        allow(uploaded_file).to receive(:size).and_return(project.actual_limits.nuget_max_file_size + 1)
      end
    end

    it_behaves_like 'returning response status', :bad_request
  end
end
