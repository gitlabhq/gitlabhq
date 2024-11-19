# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'conan package details', feature_category: :package_registry do
  include GraphqlHelpers
  include_context 'package details setup'

  let_it_be(:package) { create(:conan_package, :last_downloaded_at, project: project) }

  let(:metadata) { query_graphql_fragment('ConanMetadata') }
  let(:package_files_metadata) { query_graphql_fragment('ConanFileMetadata') }

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

  it_behaves_like 'a package detail'
  it_behaves_like 'a package with files'

  it 'has the correct metadata' do
    expect(metadata_response).to match(
      a_graphql_entity_for(package.conan_metadatum, :recipe, :package_channel, :package_username, :recipe_path)
    )
  end

  it 'has the correct file metadata' do
    expect(first_file_response_metadata).to match(
      a_graphql_entity_for(
        first_file.conan_file_metadatum,
        :conan_package_reference,
        package_revision: first_file.conan_file_metadatum.package_revision_value,
        recipe_revision: first_file.conan_file_metadatum.recipe_revision_value,
        conan_file_type: first_file.conan_file_metadatum.conan_file_type.upcase
      )
    )
  end
end
