# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RunnerBulkPause', feature_category: :runner_core do
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

  context 'for N+1 Query', :request_store do
    let_it_be(:user) { non_admin_user }
    let_it_be(:pat) { create(:personal_access_token, user: user, organization: user.organization) }
    let_it_be(:admin_pat) { create(:personal_access_token, user: admin, organization: admin.organization) }

    # update with collection itself triggers N+1 queries, so we are patching this method to
    # ensure that the select calls (specifically authorization checks) that are being tested are not impacted by this
    before do
      allow(Ci::Runner).to receive(:id_in).and_wrap_original do |original_method, ids|
        relation = original_method.call(ids)
        allow(relation).to receive(:update).and_return(relation.to_a)
        relation
      end
    end

    def mutation_with_runners(runner_ids)
      graphql_mutation(
        :runner_bulk_pause,
        {
          ids: runner_ids.map(&:to_global_id),
          paused: true
        },
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

    def post_mutation(runners, current_user = user)
      token = current_user == admin ? { personal_access_token: admin_pat } : { personal_access_token: pat }
      post_graphql_mutation(mutation_with_runners(runners), current_user: current_user, token: token)
    end

    def expect_constant_queries(runners, current_user = user)
      single_runner = [runners.first]

      # Warm up: ensure last_used_at is set on the PAT so that
      # PersonalAccessTokens::LastUsedService skips its conditional writes
      # (last_used_at_needs_update? and last_used_ip_needs_update? both return
      # false for 10 minutes / 1 minute after the first use). Without this,
      # each QueryRecorder block would include extra INSERT/UPDATE queries from
      # the service, making the baseline non-deterministic.
      #
      # Also warm up every runner (not just single_runner) so both the control
      # and actual runs toggle already-paused/unpaused runners: this keeps the
      # comparison isolated to authorization/read queries instead of mixing in
      # the per-record UPDATE + callback cost of a genuine state change, which
      # scales with the number of runners regardless of any N+1 fix.
      post_mutation(runners, current_user)
      # Read the authorized count from the mutation's own response rather than
      # re-deriving it via Ability.allowed? in the spec: the mutation runs inside the
      # GraphQL request's admin-mode/sessionless-token bypass context, which a plain
      # Ability check here wouldn't replicate (e.g. it under-counts admin users).
      authorized_count = mutation_response['updatedCount']
      post_mutation(single_runner, current_user)

      control = ActiveRecord::QueryRecorder.new do
        post_mutation(single_runner, current_user)
      end

      # Each authorized runner beyond the control's single runner still needs its own
      # ActiveRecord#update call, which wraps a SAVEPOINT/RELEASE SAVEPOINT pair and runs the
      # tag_list audit-logging callback, regardless of whether the row's value actually changes.
      # That per-record cost is inherent to updating multiple records individually (the same is
      # true of the pre-existing Relation#update behavior) and isn't itself an N+1 to preload
      # away, so scale the allowed threshold with how many extra runners will be authorized.
      #
      # A small fixed allowance also covers the (non-scaling) root-ancestor and granular-token
      # enforcement-cache lookups, which run once more for a batch spanning more than one
      # project/namespace than for the control's single runner. This is a small margin above
      # the minimum observed in CI (rather than an exact count), since it varies slightly by a
      # query or two between otherwise-identical runs (e.g. across separate rspec jobs).
      extra_authorized_runners = authorized_count - 1
      per_record_update_overhead = 3 # SAVEPOINT + RELEASE SAVEPOINT + tag_list callback query
      fixed_overhead = 6 # root-ancestor preloader + granular-token enforcement-cache lookups

      expect do
        post_mutation(runners, current_user)
      end.not_to exceed_query_limit(control)
        .with_threshold(fixed_overhead + (extra_authorized_runners * per_record_update_overhead))
    end

    context 'with project runners' do
      let_it_be(:owner_project) { create(:project, owners: user) }
      let_it_be(:maintainer_project) { create(:project, maintainers: user) }
      let_it_be(:developer_project) { create(:project, developers: user) }

      context 'with single runner per project' do
        let_it_be(:owner_runner) { create(:ci_runner, :project, projects: [owner_project]) }
        let_it_be(:maintainer_runner) { create(:ci_runner, :project, projects: [maintainer_project]) }
        let_it_be(:developer_runner) { create(:ci_runner, :project, projects: [developer_project]) }

        it 'does not cause N+1 queries when checking authorization' do
          expect_constant_queries([owner_runner, maintainer_runner, developer_runner])
        end
      end

      context 'with multiple runners per project' do
        let_it_be(:owner_runners) { create_list(:ci_runner, 3, :project, projects: [owner_project]) }
        let_it_be(:maintainer_runners) { create_list(:ci_runner, 3, :project, projects: [maintainer_project]) }
        let_it_be(:developer_runners) { create_list(:ci_runner, 3, :project, projects: [developer_project]) }

        it 'does not cause N+1 queries with multiple runners per project' do
          expect_constant_queries(owner_runners + maintainer_runners + developer_runners)
        end
      end

      context 'with mixed project access levels' do
        let_it_be(:mixed_runners) do
          [
            create(:ci_runner, :project, projects: [owner_project]),
            create(:ci_runner, :project, projects: [maintainer_project]),
            create(:ci_runner, :project, projects: [developer_project])
          ]
        end

        it 'preloads runner policies efficiently across different access levels' do
          expect_constant_queries(mixed_runners)
        end
      end
    end

    context 'with group runners' do
      let_it_be(:owner_group) { create(:group, owners: user) }
      let_it_be(:maintainer_group) { create(:group, maintainers: user) }
      let_it_be(:developer_group) { create(:group, developers: user) }

      context 'with single runner per group' do
        let_it_be(:owner_group_runner) { create(:ci_runner, :group, groups: [owner_group]) }
        let_it_be(:maintainer_group_runner) { create(:ci_runner, :group, groups: [maintainer_group]) }
        let_it_be(:developer_group_runner) { create(:ci_runner, :group, groups: [developer_group]) }

        it 'does not cause N+1 queries for group runners' do
          expect_constant_queries([owner_group_runner, maintainer_group_runner, developer_group_runner])
        end
      end

      context 'with multiple runners per group' do
        let_it_be(:owner_group_runners) { create_list(:ci_runner, 3, :group, groups: [owner_group]) }
        let_it_be(:maintainer_group_runners) { create_list(:ci_runner, 3, :group, groups: [maintainer_group]) }

        it 'handles multiple group runners without N+1' do
          expect_constant_queries(owner_group_runners + maintainer_group_runners)
        end
      end
    end

    context 'with admin user and instance runners' do
      let_it_be(:instance_runners) { create_list(:ci_runner, 5, :instance) }

      it 'handles instance runners efficiently for admin users' do
        expect_constant_queries(instance_runners, admin)
      end
    end
  end
end
