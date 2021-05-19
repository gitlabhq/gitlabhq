# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'conan package details' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:conan_package) { create(:conan_package, project: project) }

  let(:package_global_id) { global_id_of(conan_package) }
  let(:metadata) { query_graphql_fragment('ConanMetadata') }
  let(:first_file) { conan_package.package_files.find { |f| global_id_of(f) == first_file_response['id'] } }

  let(:depth) { 3 }
  let(:excluded) { %w[metadata apiFuzzingCiConfiguration pipeline packageFiles] }
  let(:package_files) { all_graphql_fields_for('PackageFile') }
  let(:package_files_metadata) {query_graphql_fragment('ConanFileMetadata')}

  let(:user) { project.owner }
  let(:package_details) { graphql_data_at(:package) }
  let(:metadata_response) { graphql_data_at(:package, :metadata) }
  let(:package_files_response) { graphql_data_at(:package, :package_files, :nodes) }
  let(:first_file_response) { graphql_data_at(:package, :package_files, :nodes, 0)}
  let(:first_file_response_metadata) { graphql_data_at(:package, :package_files, :nodes, 0, :file_metadata)}

  let(:query) do
    graphql_query_for(:package, { id: package_global_id }, <<~FIELDS)
    #{all_graphql_fields_for('PackageDetailsType', max_depth: depth, excluded: excluded)}
    metadata {
      #{metadata}
    }
    packageFiles {
      nodes {
        #{package_files}
        fileMetadata {
          #{package_files_metadata}
        }
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
      'id' => global_id_of(conan_package.conan_metadatum),
      'recipe' => conan_package.conan_metadatum.recipe,
      'packageChannel' => conan_package.conan_metadatum.package_channel,
      'packageUsername' => conan_package.conan_metadatum.package_username,
      'recipePath' => conan_package.conan_metadatum.recipe_path
    )
  end

  it 'has the right amount of files' do
    expect(package_files_response.length).to be(conan_package.package_files.length)
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

  it 'has the correct file metadata' do
    expect(first_file_response_metadata).to include(
      'id' =>  global_id_of(first_file.conan_file_metadatum),
      'packageRevision' => first_file.conan_file_metadatum.package_revision,
      'conanPackageReference' => first_file.conan_file_metadatum.conan_package_reference,
      'recipeRevision' => first_file.conan_file_metadatum.recipe_revision,
      'conanFileType' => first_file.conan_file_metadatum.conan_file_type.upcase
    )
  end
end
