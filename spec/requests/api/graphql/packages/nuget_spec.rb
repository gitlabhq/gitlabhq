# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'nuget package details' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:nuget_package) { create(:nuget_package, :with_metadatum, project: project) }

  let(:package_global_id) { global_id_of(nuget_package) }
  let(:metadata) { query_graphql_fragment('NugetMetadata') }
  let(:first_file) { nuget_package.package_files.find { |f| global_id_of(f) == first_file_response['id'] } }

  let(:depth) { 3 }
  let(:excluded) { %w[metadata apiFuzzingCiConfiguration pipeline packageFiles] }
  let(:package_files) { all_graphql_fields_for('PackageFile') }

  let(:user) { project.owner }
  let(:package_details) { graphql_data_at(:package) }
  let(:metadata_response) { graphql_data_at(:package, :metadata) }
  let(:package_files_response) { graphql_data_at(:package, :package_files, :nodes) }
  let(:first_file_response) { graphql_data_at(:package, :package_files, :nodes, 0)}

  let(:query) do
    graphql_query_for(:package, { id: package_global_id }, <<~FIELDS)
    #{all_graphql_fields_for('PackageDetailsType', max_depth: depth, excluded: excluded)}
    metadata {
      #{metadata}
    }
    packageFiles {
      nodes {
        #{package_files}
      }
    }
    FIELDS
  end

  subject { post_graphql(query, current_user: user) }

  before do
    subject
  end

  it_behaves_like 'a working graphql query' do
    it 'matches the JSON schema' do
      expect(package_details).to match_schema('graphql/packages/package_details')
    end
  end

  it 'has the correct metadata' do
    expect(metadata_response).to include(
      'id' => global_id_of(nuget_package.nuget_metadatum),
      'licenseUrl' => nuget_package.nuget_metadatum.license_url,
      'projectUrl' => nuget_package.nuget_metadatum.project_url,
      'iconUrl' => nuget_package.nuget_metadatum.icon_url
    )
  end

  it 'has the right amount of files' do
    expect(package_files_response.length).to be(nuget_package.package_files.length)
  end

  it 'has the basic package files data' do
    expect(first_file_response).to include(
      'id' => global_id_of(first_file),
      'fileName' => first_file.file_name,
      'size' => first_file.size.to_s,
      'downloadPath' => first_file.download_path,
      'fileSha1' => first_file.file_sha1,
      'fileMd5' => first_file.file_md5,
      'fileSha256' => first_file.file_sha256
    )
  end
end
