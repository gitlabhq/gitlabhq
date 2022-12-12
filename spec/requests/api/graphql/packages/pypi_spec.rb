# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'pypi package details', feature_category: :package_registry do
  include GraphqlHelpers
  include_context 'package details setup'

  let_it_be(:package) { create(:pypi_package, :last_downloaded_at, project: project) }

  let(:metadata) { query_graphql_fragment('PypiMetadata') }

  subject { post_graphql(query, current_user: user) }

  before do
    subject
  end

  it_behaves_like 'a package detail'
  it_behaves_like 'a package with files'

  it 'has the correct metadata' do
    expect(metadata_response).to match a_graphql_entity_for(
      package.pypi_metadatum, :required_python
    )
  end
end
