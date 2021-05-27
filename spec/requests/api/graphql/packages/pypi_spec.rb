# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'pypi package details' do
  include GraphqlHelpers
  include_context 'package details setup'

  let_it_be(:package) { create(:pypi_package, project: project) }

  let(:metadata) { query_graphql_fragment('PypiMetadata') }

  subject { post_graphql(query, current_user: user) }

  before do
    subject
  end

  it_behaves_like 'a package detail'
  it_behaves_like 'a package with files'

  it 'has the correct metadata' do
    expect(metadata_response).to include(
      'id' => global_id_of(package.pypi_metadatum),
      'requiredPython' => package.pypi_metadatum.required_python
    )
  end
end
