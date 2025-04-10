# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RunnerBulkPause', feature_category: :runner do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }

  let_it_be(:non_admin_user) { create(:user) }

  let!(:runners_active) { create_list(:ci_runner, 2) }
  let!(:runners_paused) { create_list(:ci_runner, 2, :paused) }
  let!(:all_runners) { runners_paused + runners_active }

  let(:mutation) do
    graphql_mutation(
      :runner_bulk_pause,
      mutation_params,
      <<-QL
        updatedCount
        updatedRunners {
          id
          paused
        }
        errors
      QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:runner_bulk_pause) }

  context 'when user is admin' do
    context 'when runners are active' do
      let(:mutation_params) do
        {
          ids: runners_active.map(&:to_global_id)
        }.deep_merge(mutation_scope_params)
      end

      context 'when asked to pause' do
        let(:mutation_scope_params) do
          {
            paused: true
          }
        end

        it 'pauses runners' do
          post_graphql_mutation(mutation, current_user: admin)
          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors']).to be_empty
          expect(mutation_response['updatedCount']).to eq(2)
          expect(mutation_response['updatedRunners']).to match_array(
            runners_active.map { |runner| a_graphql_entity_for(runner, paused: true) }
          )
        end
      end
    end

    context 'when runners are paused' do
      let(:mutation_params) do
        {
          ids: runners_paused.map(&:to_global_id)
        }.deep_merge(mutation_scope_params)
      end

      context 'when asked to unpause' do
        let(:mutation_scope_params) do
          {
            paused: false
          }
        end

        it 'unpauses runners' do
          post_graphql_mutation(mutation, current_user: admin)
          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors']).to be_empty
          expect(mutation_response['updatedCount']).to eq(2)
          expect(mutation_response['updatedRunners']).to match_array(
            runners_paused.map { |runner| a_graphql_entity_for(runner, paused: false) }
          )
        end
      end
    end

    context 'when runners have different active status' do
      let(:mutation_params) do
        {
          ids: all_runners.map(&:to_global_id)
        }.deep_merge(mutation_scope_params)
      end

      context 'when asked to unpause' do
        let(:mutation_scope_params) do
          {
            paused: false
          }
        end

        it 'unpauses every runner' do
          post_graphql_mutation(mutation, current_user: admin)
          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors']).to be_empty
          expect(mutation_response['updatedCount']).to eq(4)
          expect(mutation_response['updatedRunners']).to match_array(
            all_runners.map { |runner| a_graphql_entity_for(runner, paused: false) }
          )
        end
      end

      context 'when asked to pause' do
        let(:mutation_scope_params) do
          {
            paused: true
          }
        end

        it 'pauses every runner' do
          post_graphql_mutation(mutation, current_user: admin)
          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors']).to be_empty
          expect(mutation_response['updatedCount']).to eq(4)
          expect(mutation_response['updatedRunners']).to match_array(
            all_runners.map { |runner| a_graphql_entity_for(runner, paused: true) }
          )
        end
      end
    end

    context 'with empty id list provided' do
      let(:mutation_params) do
        {
          ids: [],
          paused: true
        }
      end

      it "doesn't fail" do
        post_graphql_mutation(mutation, current_user: admin)
        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to be_empty
        expect(mutation_response['updatedCount']).to eq(0)
      end
    end
  end

  context "when user doesn't have permission" do
    let(:mutation_params) do
      {
        ids: runners_active.map(&:to_global_id),
        paused: true
      }
    end

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: non_admin_user)
      expect(mutation_response['errors'][0]).to include "User does not have permission to update / pause"
    end
  end
end
