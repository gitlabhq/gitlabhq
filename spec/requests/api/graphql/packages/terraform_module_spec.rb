# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'terraform module details', feature_category: :package_registry do
  include GraphqlHelpers
  include_context 'package details setup'

  let_it_be(:package) do
    create(:terraform_module_package, :last_downloaded_at, project: project).tap do |package|
      create(:terraform_module_metadatum, package: package)
    end
  end

  let(:metadata) { query_graphql_fragment('TerraformModuleMetadata') }

  subject(:graphql_query) { post_graphql(query, current_user: user) }

  before do
    graphql_query
  end

  it_behaves_like 'a package detail'

  it 'has the correct metadata' do
    expect(metadata_response).to include(
      'id' => package.terraform_module_metadatum.to_global_id.to_s,
      'fields' => include(
        'root' => include('readmeHtml' => "<p data-sourcepos=\"1:1-1:6\" dir=\"auto\">README</p>"),
        'submodules' => [include('readmeHtml' => "<p data-sourcepos=\"1:1-1:17\" dir=\"auto\">submodule1 README</p>")]
      )
    )
  end
end
