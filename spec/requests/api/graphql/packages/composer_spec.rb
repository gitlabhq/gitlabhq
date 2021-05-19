# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'package details' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:composer_package) { create(:composer_package, project: project) }
  let_it_be(:composer_json) { { name: 'name', type: 'type', license: 'license', version: 1 } }
  let_it_be(:composer_metadatum) do
    # we are forced to manually create the metadatum, without using the factory to force the sha to be a string
    # and avoid an error where gitaly can't find the repository
    create(:composer_metadatum, package: composer_package, target_sha: 'foo_sha', composer_json: composer_json)
  end

  let(:depth) { 3 }
  let(:excluded) { %w[metadata apiFuzzingCiConfiguration pipeline packageFiles] }
  let(:metadata) { query_graphql_fragment('ComposerMetadata') }
  let(:package_files) { all_graphql_fields_for('PackageFile') }
  let(:user) { project.owner }
  let(:package_global_id) { global_id_of(composer_package) }
  let(:package_details) { graphql_data_at(:package) }
  let(:metadata_response) { graphql_data_at(:package, :metadata) }
  let(:package_files_response) { graphql_data_at(:package, :package_files, :nodes) }

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

  describe 'Composer' do
    it 'has the correct metadata' do
      expect(metadata_response).to include(
        'targetSha' => 'foo_sha',
        'composerJson' => composer_json.transform_keys(&:to_s).transform_values(&:to_s)
      )
    end

    it 'does not have files' do
      expect(package_files_response).to be_empty
    end
  end
end
