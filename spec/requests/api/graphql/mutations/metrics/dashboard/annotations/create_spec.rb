# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Metrics::Dashboard::Annotations::Create, feature_category: :observability do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:cluster) { create(:cluster, projects: [project]) }

  let(:dashboard_path) { 'config/prometheus/common_metrics.yml' }
  let(:starting_at) { Time.current.iso8601 }
  let(:ending_at) { 1.hour.from_now.iso8601 }
  let(:description) { 'test description' }

  def mutation_response
    graphql_mutation_response(:create_annotation)
  end

  context 'when annotation source is environment' do
    let(:mutation) do
      variables = {
        environment_id: GitlabSchema.id_from_object(environment).to_s,
        starting_at: starting_at,
        ending_at: ending_at,
        dashboard_path: dashboard_path,
        description: description
      }

      graphql_mutation(:create_annotation, variables)
    end

    context 'when the user has permission' do
      before do
        project.add_developer(current_user)
      end

      context 'when environment_id is missing' do
        let(:mutation) do
          variables = {
            starting_at: starting_at,
            ending_at: ending_at,
            dashboard_path: dashboard_path,
            description: description
          }

          graphql_mutation(:create_annotation, variables)
        end

        it_behaves_like 'a mutation that returns top-level errors',
          errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
      end

      context 'when environment_id is invalid' do
        let(:mutation) do
          variables = {
            environment_id: 'invalid_id',
            starting_at: starting_at,
            ending_at: ending_at,
            dashboard_path: dashboard_path,
            description: description
          }

          graphql_mutation(:create_annotation, variables)
        end

        it_behaves_like 'an invalid argument to the mutation', argument_name: :environment_id
      end

      context 'when metrics dashboard feature is unavailable' do
        it_behaves_like 'a mutation that returns top-level errors',
          errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
      end
    end
  end

  context 'when annotation source is cluster' do
    let(:mutation) do
      variables = {
        cluster_id: cluster.to_global_id.to_s,
        starting_at: starting_at,
        ending_at: ending_at,
        dashboard_path: dashboard_path,
        description: description
      }

      graphql_mutation(:create_annotation, variables)
    end

    context 'with permission' do
      before do
        project.add_developer(current_user)
      end

      context 'when cluster_id is missing' do
        let(:mutation) do
          variables = {
            starting_at: starting_at,
            ending_at: ending_at,
            dashboard_path: dashboard_path,
            description: description
          }

          graphql_mutation(:create_annotation, variables)
        end

        it_behaves_like 'a mutation that returns top-level errors',
          errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
      end
    end

    context 'when cluster_id is invalid' do
      let(:mutation) do
        variables = {
          cluster_id: 'invalid_id',
          starting_at: starting_at,
          ending_at: ending_at,
          dashboard_path: dashboard_path,
          description: description
        }

        graphql_mutation(:create_annotation, variables)
      end

      it_behaves_like 'an invalid argument to the mutation', argument_name: :cluster_id
    end
  end

  context 'when both environment_id and cluster_id are provided' do
    let(:mutation) do
      variables = {
        environment_id: environment.to_global_id.to_s,
        cluster_id: cluster.to_global_id.to_s,
        starting_at: starting_at,
        ending_at: ending_at,
        dashboard_path: dashboard_path,
        description: description
      }

      graphql_mutation(:create_annotation, variables)
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
  end

  [:environment_id, :cluster_id].each do |arg_name|
    context "when #{arg_name} is given an ID of the wrong type" do
      let(:gid) { global_id_of(project) }
      let(:mutation) do
        variables = {
          starting_at: starting_at,
          ending_at: ending_at,
          dashboard_path: dashboard_path,
          description: description,
          arg_name => gid
        }

        graphql_mutation(:create_annotation, variables)
      end

      before do
        project.add_developer(current_user)
      end

      it_behaves_like 'an invalid argument to the mutation', argument_name: arg_name
    end
  end
end
