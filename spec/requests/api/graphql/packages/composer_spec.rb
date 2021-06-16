# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'package details' do
  include GraphqlHelpers
  include_context 'package details setup'

  let_it_be(:package) { create(:composer_package, project: project) }
  let_it_be(:composer_json) { { name: 'name', type: 'type', license: 'license', version: 1 } }
  let_it_be(:composer_metadatum) do
    # we are forced to manually create the metadatum, without using the factory to force the sha to be a string
    # and avoid an error where gitaly can't find the repository
    create(:composer_metadatum, package: package, target_sha: 'foo_sha', composer_json: composer_json)
  end

  let(:metadata) { query_graphql_fragment('ComposerMetadata') }
  let(:package_files_response) { graphql_data_at(:package, :package_files, :nodes) }

  subject { post_graphql(query, current_user: user) }

  before do
    subject
  end

  it_behaves_like 'a package detail'

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
