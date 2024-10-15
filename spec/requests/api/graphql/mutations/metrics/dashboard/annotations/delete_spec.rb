# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Metrics::Dashboard::Annotations::Delete, feature_category: :observability do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :private, :repository) }

  let(:variables) { { id: 'ids-dont-matter' } }
  let(:mutation)  { graphql_mutation(:delete_annotation, variables) }

  def mutation_response
    graphql_mutation_response(:delete_annotation)
  end

  context 'when the user has permission to delete the annotation' do
    before do
      project.add_developer(current_user)
    end

    context 'with invalid params' do
      let(:variables) { { id: GitlabSchema.id_from_object(project).to_s } }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end

    context 'when metrics dashboard feature is unavailable' do
      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end
  end

  context 'when the user does not have permission to delete the annotation' do
    before do
      project.add_reporter(current_user)
    end

    it_behaves_like 'a mutation that returns top-level errors', errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
  end
end
