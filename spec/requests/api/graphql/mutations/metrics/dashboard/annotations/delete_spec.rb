# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Metrics::Dashboard::Annotations::Delete do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:annotation) { create(:metrics_dashboard_annotation, environment: environment) }

  let(:variables) { { id: GitlabSchema.id_from_object(annotation).to_s } }
  let(:mutation)  { graphql_mutation(:delete_annotation, variables) }

  def mutation_response
    graphql_mutation_response(:delete_annotation)
  end

  specify { expect(described_class).to require_graphql_authorizations(:delete_metrics_dashboard_annotation) }

  context 'when the user has permission to delete the annotation' do
    before do
      project.add_developer(current_user)
    end

    context 'with valid params' do
      it 'deletes the annotation' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { Metrics::Dashboard::Annotation.count }.by(-1)
      end
    end

    context 'with invalid params' do
      let(:variables) { { id: GitlabSchema.id_from_object(project).to_s } }

      it_behaves_like 'a mutation that returns top-level errors' do
        let(:match_errors) { contain_exactly(include('invalid value for id')) }
      end
    end

    context 'when the delete fails' do
      let(:service_response) { { message: 'Annotation has not been deleted', status: :error, last_step: :delete } }

      before do
        allow_next_instance_of(Metrics::Dashboard::Annotations::DeleteService) do |delete_service|
          allow(delete_service).to receive(:execute).and_return(service_response)
        end
      end
      it 'returns the error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to eq([service_response[:message]])
      end
    end
  end

  context 'when the user does not have permission to delete the annotation' do
    before do
      project.add_reporter(current_user)
    end

    it_behaves_like 'a mutation that returns top-level errors', errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

    it 'does not delete the annotation' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { Metrics::Dashboard::Annotation.count }
    end
  end
end
