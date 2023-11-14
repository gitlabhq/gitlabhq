# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CatalogResourceUnpublish', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:resource) { create(:ci_catalog_resource) }

  let(:mutation) do
    graphql_mutation(
      :catalog_resource_unpublish,
      id: resource.to_gid.to_s
    )
  end

  subject(:post_query) { post_graphql_mutation(mutation, current_user: current_user) }

  context 'when unauthorized' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when authorized' do
    before_all do
      resource.project.add_owner(current_user)
    end

    context 'when the catalog resource is in published state' do
      it 'updates the state to draft' do
        resource.update!(state: :published)
        expect(resource.state).to eq('published')

        post_query

        expect(resource.reload.state).to eq('draft')
        expect_graphql_errors_to_be_empty
      end
    end

    context 'when the catalog resource is already in draft state' do
      it 'leaves the state as draft' do
        expect(resource.state).to eq('draft')

        post_query

        expect(resource.reload.state).to eq('draft')
        expect_graphql_errors_to_be_empty
      end
    end
  end
end
