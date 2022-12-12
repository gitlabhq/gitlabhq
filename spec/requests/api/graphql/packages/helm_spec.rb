# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'helm package details', feature_category: :package_registry do
  include GraphqlHelpers
  include_context 'package details setup'

  let_it_be(:package) { create(:helm_package, :last_downloaded_at, project: project) }

  let(:package_files_metadata) { query_graphql_fragment('HelmFileMetadata') }

  let(:query) do
    graphql_query_for(:package, { id: package_global_id }, <<~FIELDS)
    #{all_graphql_fields_for('PackageDetailsType', max_depth: depth, excluded: excluded)}
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

  it 'has the correct file metadata' do
    expect(first_file_response_metadata).to include(
      'channel' => first_file.helm_file_metadatum.channel
    )
    expect(first_file_response_metadata['metadata']).to include(
      'name' => first_file.helm_file_metadatum.metadata['name'],
      'home' => first_file.helm_file_metadatum.metadata['home'],
      'sources' => first_file.helm_file_metadatum.metadata['sources'],
      'version' => first_file.helm_file_metadatum.metadata['version'],
      'description' => first_file.helm_file_metadatum.metadata['description'],
      'keywords' => first_file.helm_file_metadatum.metadata['keywords'],
      'maintainers' => first_file.helm_file_metadatum.metadata['maintainers'],
      'icon' => first_file.helm_file_metadatum.metadata['icon'],
      'apiVersion' => first_file.helm_file_metadatum.metadata['apiVersion'],
      'condition' => first_file.helm_file_metadatum.metadata['condition'],
      'tags' => first_file.helm_file_metadatum.metadata['tags'],
      'appVersion' => first_file.helm_file_metadatum.metadata['appVersion'],
      'deprecated' => first_file.helm_file_metadatum.metadata['deprecated'],
      'annotations' => first_file.helm_file_metadatum.metadata['annotations'],
      'kubeVersion' => first_file.helm_file_metadatum.metadata['kubeVersion'],
      'dependencies' => first_file.helm_file_metadatum.metadata['dependencies'],
      'type' => first_file.helm_file_metadatum.metadata['type']
    )
  end
end
