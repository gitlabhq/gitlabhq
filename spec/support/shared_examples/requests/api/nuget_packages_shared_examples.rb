# frozen_string_literal: true

RSpec.shared_examples 'rejects nuget packages access' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
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

RSpec.shared_examples 'process nuget service index request' do |user_type, status, add_member = true, v2 = false|
  context "for user type #{user_type}" do
    before do
      target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'a package tracking event', 'API::NugetPackages', 'cli_metadata'

    it 'returns a valid json or xml response' do
      subject

      if v2
        expect(response.media_type).to eq('application/xml')
        expect(body).to have_xpath('//service')
          .and have_xpath('//service/workspace')
          .and have_xpath('//service/workspace/collection[@href]')
      else
        expect(response.media_type).to eq('application/json')
        expect(json_response).to match_schema('public_api/v4/packages/nuget/service_index')
        expect(json_response).to be_a(Hash)
      end
    end

    context 'with invalid format', unless: v2 do
      let(:url) { "/#{target_type}/#{target.id}/packages/nuget/index.xls" }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end
  end
end

RSpec.shared_examples 'process nuget v2 $metadata service request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'returns a valid xml response' do
      api_request

      doc = Nokogiri::XML(body)

      expect(response.media_type).to eq('application/xml')
      expect(doc.at_xpath('//edmx:Edmx')).to be_present
      expect(doc.at_xpath('//edmx:Edmx/edmx:DataServices')).to be_present
      expect(doc.css('*').map(&:name)).to include(
        'Schema', 'EntityType', 'Key', 'PropertyRef', 'EntityContainer', 'EntitySet', 'FunctionImport', 'Parameter'
      )
      expect(doc.css('*').select { |el| el.name == 'Property' }.map { |el| el.attribute_nodes.first.value })
        .to match_array(%w[Id Version Authors Dependencies Description DownloadCount IconUrl Published ProjectUrl
          Tags Title LicenseUrl]
                       )
      expect(doc.css('*').detect { |el| el.name == 'FunctionImport' }.attr('Name')).to eq('FindPackagesById')
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
      target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'returning nuget metadata json response with json schema',
      'public_api/v4/packages/nuget/packages_metadata'

    context 'with invalid format' do
      let(:url) { "/#{target_type}/#{target.id}/packages/nuget/metadata/#{package_name}/index.xls" }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end

    context 'with lower case package name' do
      let_it_be(:package_name) { 'dummy.package' }

      it_behaves_like 'returning response status', status

      it_behaves_like 'returning nuget metadata json response with json schema',
        'public_api/v4/packages/nuget/packages_metadata'
    end
  end
end

RSpec.shared_examples \
  'process nuget metadata request at package name and package version level' \
  do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'returning nuget metadata json response with json schema',
      'public_api/v4/packages/nuget/package_metadata'

    context 'with invalid format' do
      let(:url) { "/#{target_type}/#{target.id}/packages/nuget/metadata/#{package_name}/#{package.version}.xls" }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end

    context 'with lower case package name' do
      let_it_be(:package_name) { 'dummy.package' }

      it_behaves_like 'returning response status', status

      it_behaves_like 'returning nuget metadata json response with json schema',
        'public_api/v4/packages/nuget/package_metadata'
    end
  end
end

RSpec.shared_examples 'process nuget workhorse authorization' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
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
  shared_context 'with nuspec extraction service stub' do
    before do
      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:extracted_metadata).and_return(service_result)
      end
    end

    after do
      Grape::Endpoint.before_each nil
    end
  end

  shared_examples 'creates nuget package files' do
    context 'when nuspec extraction succeeds' do
      let(:params) { super().merge('package.remote_url' => 'http://example.com') }

      before do
        allow_next_instance_of(::Packages::Nuget::ExtractRemoteMetadataFileService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.success(payload: fixture_file('packages/nuget/with_metadata.nuspec'))
          )
        end
      end

      it 'creates package files on the fly', unless: symbol_package do
        expect(::Packages::Nuget::ExtractionWorker).not_to receive(:perform_async)
        expect { subject }
            .to change { target.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)
        expect(response).to have_gitlab_http_status(status)

        package_file = target.packages.last.package_files.reload.last
        expect(package_file.file_name).to eq('dummyproject.withmetadata.1.2.3.nupkg')
      end
    end

    context 'when nuspec extraction fails' do
      include_context 'with nuspec extraction service stub' do
        let(:service_result) { ServiceResponse.error(message: 'error', reason: :nuspec_extraction_failed) }
      end

      it 'calls the extraction worker' do
        expect(::Packages::Nuget::ExtractionWorker).to receive(:perform_async).once
        expect { subject }
            .to change { target.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)
        expect(response).to have_gitlab_http_status(status)

        package_file = target.packages.last.package_files.reload.last
        expect(package_file.file_name).to eq(file_name)
      end
    end

    context 'when nuspec extraction fails with a different error', unless: symbol_package do
      include_context 'with nuspec extraction service stub' do
        let(:service_result) { ServiceResponse.error(message: 'error', reason: :bad_request) }
      end

      it 'returns a bad request' do
        expect { subject }.not_to change { target.packages.count }
        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context "with ExtractMetadataFileService's ExtractionError", unless: symbol_package do
      before do
        allow(Zip::InputStream).to receive(:open).and_yield(StringIO.new('content'))
        allow_next_instance_of(::Packages::Nuget::ExtractMetadataFileService) do |service|
          allow(service).to receive(:execute).and_raise(service.class::ExtractionError, 'error')
        end
      end

      it 'returns a bad request' do
        expect { subject }.not_to change { target.packages.count }
        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  context "for user type #{user_type}" do
    before do
      target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
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
        fog_connection.directories.new(key: 'packages').files.create( # rubocop:disable Rails/SaveBang -- not the AR method
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
            include_context 'with nuspec extraction service stub' do
              let(:service_result) do
                ServiceResponse.success(payload: fixture_file('packages/nuget/with_metadata.nuspec'))
              end
            end

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
            expect { subject }.not_to change { ::Packages::PackageFile.count }
          end

          it_behaves_like 'returning response status', :bad_request
        end
      end

      context 'and direct upload disabled' do
        let(:fog_connection) do
          stub_package_file_object_storage(direct_upload: false)
        end

        it_behaves_like 'creates nuget package files'
      end
    end
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
      target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
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
      target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it_behaves_like 'a package tracking event', 'API::NugetPackages', 'pull_package'

    it_behaves_like 'bumping the package last downloaded at field'

    it 'returns a valid package archive' do
      subject

      expect(response.media_type).to eq('application/octet-stream')
    end

    context 'with invalid format' do
      let(:url) do
        "/#{target_type}/#{target.id}/packages/nuget/download/" \
          "#{package.name}/#{package.version}/#{package.name}.#{package.version}.xls"
      end

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end

    context 'with symbol package' do
      let(:format) { 'snupkg' }

      it 'returns a valid package archive' do
        subject

        expect(response.media_type).to eq('application/octet-stream')
      end

      it_behaves_like 'a package tracking event', 'API::NugetPackages', 'pull_symbol_package'

      it_behaves_like 'bumping the package last downloaded at field'
    end

    context 'with lower case package name' do
      let_it_be(:package_name) { 'dummy.package' }

      it_behaves_like 'returning response status', status

      it 'returns a valid package archive' do
        subject

        expect(response.media_type).to eq('application/octet-stream')
      end
    end

    context 'with normalized package version' do
      let(:package_version) { '0.1.0' }

      it_behaves_like 'returning response status', status

      it 'returns a valid package archive' do
        subject

        expect(response.media_type).to eq('application/octet-stream')
      end

      it_behaves_like 'bumping the package last downloaded at field'
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
      target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
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

RSpec.shared_examples 'process empty nuget search request' do |user_type, status, add_member = true|
  before do
    target.send(:"add_#{user_type}", user) if add_member && user_type != :anonymous
  end

  it_behaves_like 'returning response status', status

  it 'returns a valid json response' do
    subject

    expect(response.media_type).to eq('application/json')
    expect(json_response).to be_a(Hash)
    expect(json_response).to match_schema('public_api/v4/packages/nuget/search')
    expect(json_response['totalHits']).to eq(0)
    expect(json_response['data'].map { |e| e['versions'].size }).to be_empty
  end

  it_behaves_like 'a package tracking event', 'API::NugetPackages', 'search_package'
end

RSpec.shared_examples 'rejects nuget access with invalid target id' do |not_found_response: :unauthorized|
  context 'with a target id with invalid integers' do
    using RSpec::Parameterized::TableSyntax

    let(:target) { instance_double(Group, id:) }

    where(:id, :status) do
      '/../'       | :bad_request
      ''           | :not_found
      '%20'        | :bad_request
      '%2e%2e%2f'  | :bad_request
      'NaN'        | :bad_request
      0o0002345    | not_found_response
      'anything25' | :bad_request
    end

    with_them do
      it_behaves_like 'rejects nuget packages access', :anonymous, params[:status]
    end
  end
end

RSpec.shared_examples 'rejects nuget access with unknown target id' do |not_found_response: :unauthorized|
  context 'with an unknown target' do
    let(:target) { instance_double(Group, id: non_existing_record_id) }

    context 'as anonymous' do
      it_behaves_like 'rejects nuget packages access', :anonymous, not_found_response
    end

    context 'as authenticated user' do
      subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end
  end
end

RSpec.shared_examples 'allows anyone to pull public nuget packages on group level' do
  let_it_be(:package_name) { 'dummy.package' }
  let_it_be(:package) { create(:nuget_package, project: project, name: package_name) }

  let(:not_found_response) { :not_found }

  subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

  shared_examples 'successful response' do
    it 'returns a successful response' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match_schema(json_schema)
    end
  end

  before_all do
    [subgroup, group, project].each do |entity|
      entity.update_column(:visibility_level, Gitlab::VisibilityLevel.const_get(:PRIVATE, false))
    end
    project.project_feature.update!(package_registry_access_level: ::ProjectFeature::PUBLIC)
  end

  before do
    stub_application_setting(package_registry_allow_anyone_to_pull_option: true)
  end

  it_behaves_like 'successful response'

  context 'when target package is in a private registry and group has another public registry' do
    let(:other_project) { create(:project, group: target, visibility_level: target.visibility_level) }

    before do
      project.project_feature.update!(package_registry_access_level: ::ProjectFeature::PRIVATE)
      other_project.project_feature.update!(package_registry_access_level: ::ProjectFeature::PUBLIC)
    end

    it 'returns no packages' do
      subject

      expect(response).to have_gitlab_http_status(not_found_response)

      if not_found_response == :ok
        expect(json_response).to match_schema(json_schema)
        expect(json_response['totalHits']).to eq(0)
        expect(json_response['data']).to be_empty
      end
    end

    context 'when package is in the project with public registry' do
      before do
        package.update!(project: other_project)
      end

      it_behaves_like 'successful response'
    end
  end
end

RSpec.shared_examples 'nuget authorize upload endpoint' do
  using RSpec::Parameterized::TableSyntax
  include_context 'workhorse headers'

  let(:headers) { {} }

  subject { put api(url), headers: headers }

  it { is_expected.to have_request_urgency(:low) }

  context 'with valid project' do
    where(:visibility_level, :user_role, :member, :user_token, :sent_through, :shared_examples_name,
      :expected_status) do
      'PUBLIC'  | :developer  | true  | true  | :basic_auth | 'process nuget workhorse authorization' | :success
      'PUBLIC'  | :guest      | true  | true  | :basic_auth | 'rejects nuget packages access'         | :forbidden
      'PUBLIC'  | :developer  | true  | false | :basic_auth | 'rejects nuget packages access'         | :unauthorized
      'PUBLIC'  | :guest      | true  | false | :basic_auth | 'rejects nuget packages access'         | :unauthorized
      'PUBLIC'  | :developer  | false | true  | :basic_auth | 'rejects nuget packages access'         | :forbidden
      'PUBLIC'  | :guest      | false | true  | :basic_auth | 'rejects nuget packages access'         | :forbidden
      'PUBLIC'  | :developer  | false | false | :basic_auth | 'rejects nuget packages access'         | :unauthorized
      'PUBLIC'  | :guest      | false | false | :basic_auth | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :developer  | true  | true  | :basic_auth | 'process nuget workhorse authorization' | :success
      'PRIVATE' | :guest      | true  | true  | :basic_auth | 'rejects nuget packages access'         | :forbidden
      'PRIVATE' | :developer  | true  | false | :basic_auth | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :guest      | true  | false | :basic_auth | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :developer  | false | true  | :basic_auth | 'rejects nuget packages access'         | :not_found
      'PRIVATE' | :guest      | false | true  | :basic_auth | 'rejects nuget packages access'         | :not_found
      'PRIVATE' | :developer  | false | false | :basic_auth | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :guest      | false | false | :basic_auth | 'rejects nuget packages access'         | :unauthorized

      'PUBLIC'  | :developer  | true  | true  | :api_key    | 'process nuget workhorse authorization' | :success
      'PUBLIC'  | :guest      | true  | true  | :api_key    | 'rejects nuget packages access'         | :forbidden
      'PUBLIC'  | :developer  | true  | false | :api_key    | 'rejects nuget packages access'         | :unauthorized
      'PUBLIC'  | :guest      | true  | false | :api_key    | 'rejects nuget packages access'         | :unauthorized
      'PUBLIC'  | :developer  | false | true  | :api_key    | 'rejects nuget packages access'         | :forbidden
      'PUBLIC'  | :guest      | false | true  | :api_key    | 'rejects nuget packages access'         | :forbidden
      'PUBLIC'  | :developer  | false | false | :api_key    | 'rejects nuget packages access'         | :unauthorized
      'PUBLIC'  | :guest      | false | false | :api_key    | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :developer  | true  | true  | :api_key    | 'process nuget workhorse authorization' | :success
      'PRIVATE' | :guest      | true  | true  | :api_key    | 'rejects nuget packages access'         | :forbidden
      'PRIVATE' | :developer  | true  | false | :api_key    | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :guest      | true  | false | :api_key    | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :developer  | false | true  | :api_key    | 'rejects nuget packages access'         | :not_found
      'PRIVATE' | :guest      | false | true  | :api_key    | 'rejects nuget packages access'         | :not_found
      'PRIVATE' | :developer  | false | false | :api_key    | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :guest      | false | false | :api_key    | 'rejects nuget packages access'         | :unauthorized

      'PUBLIC'  | :anonymous  | false | true  | nil         | 'rejects nuget packages access'         | :unauthorized
      'PRIVATE' | :anonymous  | false | true  | nil         | 'rejects nuget packages access'         | :unauthorized
    end

    with_them do
      let(:token) { user_token ? personal_access_token.token : 'wrong' }

      let(:user_headers) do
        case sent_through
        when :basic_auth
          basic_auth_header(user.username, token)
        when :api_key
          { 'X-NuGet-ApiKey' => token }
        else
          {}
        end
      end

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
  include_context 'workhorse headers'

  let(:headers) { {} }
  let(:file_name) { symbol_package ? 'package.snupkg' : 'package.nupkg' }
  let(:params) { { package: fixture_file_upload("spec/fixtures/packages/nuget/#{file_name}") } }
  let(:file_key) { :package }
  let(:send_rewritten_field) { true }

  subject do
    workhorse_finalize(
      api(url),
      method: :put,
      file_key: file_key,
      params: params,
      headers: headers,
      send_rewritten_field: send_rewritten_field
    )
  end

  it { is_expected.to have_request_urgency(:low) }

  context 'with valid project' do
    where(:visibility_level, :user_role, :member, :user_token, :sent_through, :shared_examples_name,
      :expected_status) do
      'PUBLIC'  | :developer  | true  | true  | :basic_auth | 'process nuget upload'          | :created
      'PUBLIC'  | :guest      | true  | true  | :basic_auth | 'rejects nuget packages access' | :forbidden
      'PUBLIC'  | :developer  | true  | false | :basic_auth | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :guest      | true  | false | :basic_auth | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :developer  | false | true  | :basic_auth | 'rejects nuget packages access' | :forbidden
      'PUBLIC'  | :guest      | false | true  | :basic_auth | 'rejects nuget packages access' | :forbidden
      'PUBLIC'  | :developer  | false | false | :basic_auth | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :guest      | false | false | :basic_auth | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :developer  | true  | true  | :basic_auth | 'process nuget upload'          | :created
      'PRIVATE' | :guest      | true  | true  | :basic_auth | 'rejects nuget packages access' | :forbidden
      'PRIVATE' | :developer  | true  | false | :basic_auth | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :guest      | true  | false | :basic_auth | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :developer  | false | true  | :basic_auth | 'rejects nuget packages access' | :not_found
      'PRIVATE' | :guest      | false | true  | :basic_auth | 'rejects nuget packages access' | :not_found
      'PRIVATE' | :developer  | false | false | :basic_auth | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :guest      | false | false | :basic_auth | 'rejects nuget packages access' | :unauthorized

      'PUBLIC'  | :developer  | true  | true  | :api_key    | 'process nuget upload'          | :created
      'PUBLIC'  | :guest      | true  | true  | :api_key    | 'rejects nuget packages access' | :forbidden
      'PUBLIC'  | :developer  | true  | false | :api_key    | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :guest      | true  | false | :api_key    | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :developer  | false | true  | :api_key    | 'rejects nuget packages access' | :forbidden
      'PUBLIC'  | :guest      | false | true  | :api_key    | 'rejects nuget packages access' | :forbidden
      'PUBLIC'  | :developer  | false | false | :api_key    | 'rejects nuget packages access' | :unauthorized
      'PUBLIC'  | :guest      | false | false | :api_key    | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :developer  | true  | true  | :api_key    | 'process nuget upload'          | :created
      'PRIVATE' | :guest      | true  | true  | :api_key    | 'rejects nuget packages access' | :forbidden
      'PRIVATE' | :developer  | true  | false | :api_key    | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :guest      | true  | false | :api_key    | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :developer  | false | true  | :api_key    | 'rejects nuget packages access' | :not_found
      'PRIVATE' | :guest      | false | true  | :api_key    | 'rejects nuget packages access' | :not_found
      'PRIVATE' | :developer  | false | false | :api_key    | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :guest      | false | false | :api_key    | 'rejects nuget packages access' | :unauthorized

      'PUBLIC'  | :anonymous  | false | true  | nil         | 'rejects nuget packages access' | :unauthorized
      'PRIVATE' | :anonymous  | false | true  | nil         | 'rejects nuget packages access' | :unauthorized
    end

    with_them do
      let(:token) { user_token ? personal_access_token.token : 'wrong' }

      let(:user_headers) do
        case sent_through
        when :basic_auth
          basic_auth_header(user.username, token)
        when :api_key
          { 'X-NuGet-ApiKey' => token }
        else
          {}
        end
      end

      let(:headers) { user_headers.merge(workhorse_headers) }

      let(:snowplow_gitlab_standard_context) do
        { project: project, user: user, namespace: project.namespace, property: 'i_package_nuget_user' }.tap do |ctx|
          ctx[:feed] = 'v2' if url.include?('nuget/v2')
        end
      end

      before do
        update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
      end

      it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member],
        symbol_package
    end
  end

  it_behaves_like 'deploy token for package uploads'

  it_behaves_like 'job token for package uploads' do
    let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
  end

  it_behaves_like 'rejects nuget access with unknown target id'

  it_behaves_like 'rejects nuget access with invalid target id'

  context 'when file size above maximum limit' do
    let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_headers) }

    before do
      allow_next_instance_of(UploadedFile) do |uploaded_file|
        allow(uploaded_file).to receive(:size).and_return(project.actual_limits.nuget_max_file_size + 1)
      end
    end

    it_behaves_like 'returning response status', :bad_request
  end

  context 'when ObjectStorage::RemoteStoreError is raised' do
    let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_headers) }

    before do
      allow_next_instance_of(::Packages::CreatePackageFileService) do |instance|
        allow(instance).to receive(:execute).and_raise(ObjectStorage::RemoteStoreError)
      end
    end

    it_behaves_like 'returning response status', :forbidden
  end

  context 'when package duplicates are not allowed', unless: symbol_package do
    let(:params) { { package: fixture_file_upload('spec/fixtures/packages/nuget/package.nupkg') } }
    let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_headers) }
    let!(:existing_package) do
      create(:nuget_package, project: project, name: 'DummyProject.DummyPackage', version: '1.0.0')
    end

    let_it_be(:package_settings) do
      create(:namespace_package_setting, :group, namespace: project.namespace, nuget_duplicates_allowed: false)
    end

    it_behaves_like 'returning response status', :conflict

    context 'when exception_regex is set' do
      before do
        package_settings.update_column(:nuget_duplicate_exception_regex, ".*#{existing_package.name.last(3)}.*")
      end

      it_behaves_like 'returning response status', :created
    end
  end
end

RSpec.shared_examples 'process nuget delete request' do |user_type, status, auth|
  context "for user type #{user_type}" do
    before do
      target.send(:"add_#{user_type}", user) if user_type
    end

    it_behaves_like 'returning response status', status

    it 'triggers an internal event' do
      args = { project: project, label: 'nuget', category: 'InternalEventTracking' }

      if auth.nil?
        args[:property] = 'guest'
      elsif auth == :deploy_token
        args[:property] = 'deploy_token'
      else
        args[:user] = user
        args[:property] = 'user'
      end

      expect { subject }
        .to trigger_internal_events('delete_package_from_registry')
          .with(**args)
    end

    it 'marks package for deletion' do
      expect { subject }.to change { package.reset.status }.from('default').to('pending_destruction')
    end
  end
end

RSpec.shared_examples 'nuget symbol file endpoint' do
  let_it_be(:symbol) { create(:nuget_symbol) }
  let_it_be(:filename) { symbol.file.filename }
  let_it_be(:signature) { symbol.signature }
  let_it_be(:checksum) { symbol.file_sha256.delete("\n") }

  let(:headers) { { 'Symbolchecksum' => "SHA256:#{checksum}" } }

  subject { get api(url), headers: headers }

  it { is_expected.to have_request_urgency(:low) }

  context 'with nuget_symbol_server_enabled setting enabled' do
    before do
      allow_next_instance_of(::Namespace::PackageSetting) do |setting|
        allow(setting).to receive(:nuget_symbol_server_enabled).and_return(true)
      end
    end

    shared_examples 'successful response' do
      it 'returns the symbol file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
        expect(response.body).to eq(symbol.file.read)
      end
    end

    context 'with valid target' do
      it_behaves_like 'successful response'
    end

    context 'when target does not exist' do
      let(:target) { instance_double(Group, id: non_existing_record_id) }

      it_behaves_like 'returning response status', :not_found
    end

    context 'when target exists' do
      context 'when symbol file does not exist' do
        let(:filename) { 'non-existent-file.pdb' }
        let(:signature) { 'non-existent-signature' }

        it_behaves_like 'returning response status', :not_found
      end

      context 'when symbol file checksum does not match' do
        let(:checksum) { 'non-matching-checksum' }

        it_behaves_like 'returning response status', :not_found
      end

      context 'when symbol file checksum is missing' do
        let(:headers) { {} }

        it_behaves_like 'returning response status', :bad_request
      end
    end

    context 'when signature & filename are in uppercase' do
      let(:filename) { symbol.file.filename.upcase }
      let(:signature) { symbol.signature.upcase }

      it_behaves_like 'successful response'
    end
  end

  context 'with nuget_symbol_server_enabled setting disabled' do
    before do
      allow_next_instance_of(::Namespace::PackageSetting) do |setting|
        allow(setting).to receive(:nuget_symbol_server_enabled).and_return(false)
      end
    end

    it_behaves_like 'returning response status', :forbidden
  end
end
