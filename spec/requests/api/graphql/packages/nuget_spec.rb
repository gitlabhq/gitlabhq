# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'nuget package details' do
  include GraphqlHelpers
  include_context 'package details setup'

  let_it_be(:package) { create(:nuget_package, :with_metadatum, project: project) }

  let(:metadata) { query_graphql_fragment('NugetMetadata') }

  subject { post_graphql(query, current_user: user) }

  before do
    subject
  end

  it_behaves_like 'a package detail'
  it_behaves_like 'a package with files'

  it 'has the correct metadata' do
    expect(metadata_response).to include(
      'id' => global_id_of(package.nuget_metadatum),
      'licenseUrl' => package.nuget_metadatum.license_url,
      'projectUrl' => package.nuget_metadatum.project_url,
      'iconUrl' => package.nuget_metadatum.icon_url
    )
  end
end
