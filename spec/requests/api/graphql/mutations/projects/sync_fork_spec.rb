# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Sync project fork", feature_category: :source_code_management do
  include GraphqlHelpers
  include ProjectForksHelper
  include ExclusiveLeaseHelpers

  let_it_be(:source_project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user, maintainer_of: source_project) }
  let_it_be(:project, refind: true) { fork_project(source_project, current_user, { repository: true }) }
  let_it_be(:target_branch) { project.default_branch }

  let(:mutation) do
    params = { project_path: project.full_path, target_branch: target_branch }

    graphql_mutation(:project_sync_fork, params) do
      <<-QL.strip_heredoc
        details {
          ahead
          behind
          isSyncing
          hasConflicts
        }
        errors
      QL
    end
  end

  before do
    source_project.change_head('feature')
  end

  context 'when the branch is protected', :use_clean_rails_redis_caching do
    let_it_be(:protected_branch) do
      create(:protected_branch, :no_one_can_push, project: project, name: target_branch)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not call the sync service' do
      expect(::Projects::Forks::SyncWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end

  context 'when the user does not have permission' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not call the sync service' do
      expect(::Projects::Forks::SyncWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end

  context 'when the user has permission' do
    context 'and the sync service executes successfully', :sidekiq_inline do
      it 'calls the sync service' do
        expect(::Projects::Forks::SyncWorker).to receive(:perform_async).and_call_original

        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_mutation_response(:project_sync_fork)).to eq(
          {
            'details' => { 'ahead' => 30, 'behind' => 0, "hasConflicts" => false, "isSyncing" => false },
            'errors' => []
          })
      end
    end

    context 'and the sync service fails to execute' do
      let(:target_branch) { 'markdown' }

      def expect_error_response(message)
        expect(::Projects::Forks::SyncWorker).not_to receive(:perform_async)

        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_mutation_response(:project_sync_fork)['errors']).to eq([message])
      end

      context 'when fork details cannot be resolved' do
        let_it_be(:project) { source_project }

        it 'returns an error' do
          expect_error_response('This branch of this project cannot be updated from the upstream')
        end
      end

      context 'when the specified branch does not exist' do
        let(:target_branch) { 'non-existent-branch' }

        it 'returns an error' do
          expect_error_response('Target branch does not exist')
        end
      end

      context 'when the previous execution resulted in a conflict' do
        it 'returns an error' do
          expect_next_instance_of(::Projects::Forks::Details) do |instance|
            expect(instance).to receive(:has_conflicts?).twice.and_return(true)
          end

          expect_error_response('The synchronization cannot happen due to the merge conflict')
          expect(graphql_mutation_response(:project_sync_fork)['details']['hasConflicts']).to eq(true)
        end
      end

      context 'when the request is rate limited' do
        it 'returns an error' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

          expect_error_response('This service has been called too many times.')
        end
      end

      context 'when another fork sync is in progress' do
        it 'returns an error' do
          expect_next_instance_of(Projects::Forks::Details) do |instance|
            lease = instance_double(Gitlab::ExclusiveLease, try_obtain: false, exists?: true)
            expect(instance).to receive(:exclusive_lease).twice.and_return(lease)
          end

          expect_error_response('Another fork sync is already in progress')
          expect(graphql_mutation_response(:project_sync_fork)['details']['isSyncing']).to eq(true)
        end
      end
    end
  end
end
