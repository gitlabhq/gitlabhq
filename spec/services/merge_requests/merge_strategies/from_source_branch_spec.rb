# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeStrategies::FromSourceBranch, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2, freeze: false) { create(:user) }

  let(:merge_request) { create(:merge_request, :simple, author: user2, assignees: [user2]) }
  let(:project) { merge_request.project }

  subject(:strategy) { described_class.new(merge_request, user) }

  before do
    project.add_maintainer(user)
  end

  describe '#validate!' do
    context 'when the MR is not mergeable' do
      before do
        allow(merge_request).to receive(:mergeable?).and_return(false)
      end

      it 'raises not mergeable error' do
        error_message = 'Merge request is not mergeable'

        expect { strategy.validate! }
          .to raise_exception(MergeRequests::MergeStrategies::StrategyError, error_message)
      end
    end

    it 'calls mergeable? with use_cache: false' do
      expect(merge_request).to receive(:mergeable?).with(
        hash_including(use_cache: false)
      ).and_return(true)

      strategy.validate!
    end

    context 'when merge request should be squashed but is not' do
      before do
        merge_request.target_project.project_setting.squash_always!
        merge_request.update!(squash: false)
      end

      it 'raises squashing error' do
        error_message = 'This project requires squashing commits when merge requests are accepted.'

        expect { strategy.validate! }
          .to raise_exception(MergeRequests::MergeStrategies::StrategyError, error_message)
      end
    end

    context 'when we are using ff only strategy' do
      before do
        project.merge_method = :ff
        project.save!
      end

      context 'when it needs to be rebased' do
        before do
          allow(merge_request).to receive(:should_be_rebased?).and_return(true)
        end

        context 'when source is missing' do
          before do
            allow(merge_request).to receive(:diff_head_sha).and_return(nil)
          end

          it 'raises source error when source is missing' do
            error_message = 'No source for merge'

            expect { strategy.validate! }
              .to raise_exception(MergeRequests::MergeStrategies::StrategyError, error_message)
          end
        end
      end

      context 'when it does not need to be rebased' do
        context 'when source is missing' do
          before do
            allow(merge_request).to receive(:diff_head_sha).and_return(nil)
          end

          it 'raises source error when source is missing' do
            error_message = 'No source for merge'

            expect { strategy.validate! }
              .to raise_exception(MergeRequests::MergeStrategies::StrategyError, error_message)
          end
        end
      end

      context 'when we are using a merge commit strategy' do
        before do
          project.merge_method = :merge
          project.save!
        end

        context 'when source is missing' do
          before do
            allow(merge_request).to receive(:diff_head_sha).and_return(nil)
          end

          it 'raises source error when source is missing' do
            error_message = 'No source for merge'

            expect { strategy.validate! }
              .to raise_exception(MergeRequests::MergeStrategies::StrategyError, error_message)
          end
        end
      end
    end

    context 'when automatic rebase is off' do
      before do
        project.project_setting.update!(automatic_rebase_enabled: false)
      end

      context 'when merge request should be rebased' do
        before do
          allow(merge_request).to receive(:should_be_rebased?).and_return(true)
        end

        it 'raises needs rebase error' do
          error_message = 'Only fast-forward merge is allowed for your project. Please update your source branch'

          expect { strategy.validate! }
            .to raise_exception(MergeRequests::MergeStrategies::StrategyError, error_message)
        end
      end

      context 'when source is missing' do
        before do
          allow(merge_request).to receive(:diff_head_sha).and_return(nil)
        end

        it 'raises source error when source is missing' do
          error_message = 'No source for merge'

          expect { strategy.validate! }
            .to raise_exception(MergeRequests::MergeStrategies::StrategyError, error_message)
        end
      end

      context 'when the MR is not mergeable' do
        before do
          allow(merge_request).to receive(:mergeable?).and_return(false)
        end

        it 'raises not mergeable error' do
          error_message = 'Merge request is not mergeable'

          expect { strategy.validate! }
            .to raise_exception(MergeRequests::MergeStrategies::StrategyError, error_message)
        end
      end

      context 'when merge request should be squashed but is not' do
        before do
          merge_request.target_project.project_setting.squash_always!
          merge_request.update!(squash: false)
        end

        it 'raises squashing error' do
          error_message = 'This project requires squashing commits when merge requests are accepted.'

          expect { strategy.validate! }
            .to raise_exception(MergeRequests::MergeStrategies::StrategyError, error_message)
        end
      end
    end
  end

  describe '#execute_git_merge!' do
    let(:create_ref_service_response) do
      instance_double(ServiceResponse, payload: { commit_sha: '11' })
    end

    let(:target_branch_sha) { project.repository.commit(merge_request.target_branch).sha }

    context 'when we are using ff only strategy' do
      before do
        project.merge_method = :ff
        project.save!
        project.project_setting.update!(automatic_rebase_enabled: true)
      end

      context 'when it requires a rebase' do
        before do
          allow(merge_request).to receive(:should_be_rebased?).and_return(true)
        end

        it 'fast forward merges with the commit sha from the create ref service' do
          expect_next_instance_of(MergeRequests::CreateRefService) do |instance|
            expect(instance).to receive(:execute).and_return(create_ref_service_response)
          end

          expect(merge_request.target_project.repository)
            .to receive(:ff_merge)
            .with(
              user, '11', merge_request.target_branch,
              { target_sha: target_branch_sha, merge_request: merge_request }
            )
            .and_return('1234')

          expect(merge_request).to receive(:schedule_cleanup_refs).with(only: [:rebase_on_merge_path])

          expect(strategy.execute_git_merge!).to eq({ commit_sha: '1234' })
        end

        context 'when automatic_rebase_enabled is false' do
          before do
            project.project_setting.update!(automatic_rebase_enabled: false)
          end

          it 'performs a fast-forward merge without create ref service' do
            expect(MergeRequests::CreateRefService).not_to receive(:new)
            expect(merge_request.target_project.repository).to receive(:ff_merge).and_return('1234')

            expect(strategy.execute_git_merge!).to eq({ commit_sha: '1234' })
          end
        end
      end

      context 'when it does not require a rebase' do
        before do
          allow(merge_request).to receive(:should_be_rebased?).and_return(false)
        end

        it 'performs a fast-forward merge' do
          expect(MergeRequests::CreateRefService).not_to receive(:new)
          expect(merge_request.target_project.repository).to receive(:ff_merge).and_return('1234')

          expect(strategy.execute_git_merge!).to eq({ commit_sha: '1234' })
        end
      end
    end

    context 'when we are using the rebase merge method' do
      before do
        project.merge_method = :rebase_merge
        project.save!
        project.project_setting.update!(automatic_rebase_enabled: true)
      end

      it 'fast forward merges with the commit sha from the create ref service' do
        expect_next_instance_of(MergeRequests::CreateRefService) do |instance|
          expect(instance).to receive(:execute).and_return(create_ref_service_response)
        end

        expect(merge_request.target_project.repository)
          .to receive(:ff_merge)
          .with(
            user, '11', merge_request.target_branch,
            { target_sha: target_branch_sha, merge_request: merge_request }
          )
          .and_return('1234')

        expect(merge_request).to receive(:schedule_cleanup_refs).with(only: [:rebase_on_merge_path])

        expect(strategy.execute_git_merge!).to eq({ commit_sha: '1234' })
      end

      context 'when automatic_rebase_enabled is false' do
        before do
          project.project_setting.update!(automatic_rebase_enabled: false)
        end

        it 'performs standard merge without create ref service' do
          expect(MergeRequests::CreateRefService).not_to receive(:new)
          expect(merge_request.target_project.repository).to receive(:merge).and_return('1234')

          expect(strategy.execute_git_merge!).to eq({ commit_sha: '1234', merge_commit_sha: '1234' })
        end
      end
    end

    context 'when we are using the merge commit method' do
      before do
        project.merge_method = :merge
        project.save!
      end

      it 'performs standard merge' do
        expect(merge_request.target_project.repository).to receive(:merge).and_return('1234')

        expect(strategy.execute_git_merge!).to eq({ commit_sha: '1234', merge_commit_sha: '1234' })
      end
    end

    context 'when automatic rebase is off' do
      context 'when fast-forward is required' do
        before do
          project.merge_method = :ff
          project.save!
        end

        it 'performs a fast-forward merge' do
          expect(merge_request.target_project.repository).to receive(:ff_merge).and_return('1234')

          expect(strategy.execute_git_merge!).to eq({ commit_sha: '1234' })
        end
      end

      context 'when a merge commit is required' do
        before do
          project.merge_method = :merge
          project.save!
        end

        it 'performs standard merge' do
          expect(merge_request.target_project.repository).to receive(:merge).and_return('1234')

          expect(strategy.execute_git_merge!).to eq({ commit_sha: '1234', merge_commit_sha: '1234' })
        end
      end
    end

    context 'when the fast-forward does not advance the target branch' do
      before do
        project.merge_method = :ff
        project.save!
      end

      it 'raises rather than recording a no-op when ff_merge returns the unchanged target tip' do
        expect(merge_request.target_project.repository)
          .to receive(:ff_merge).and_return(target_branch_sha)

        expect { strategy.execute_git_merge! }
          .to raise_exception(
            MergeRequests::MergeStrategies::StrategyError,
            'Fast-forward merge did not advance the target branch'
          )
      end

      it 'raises when ff_merge returns a blank result' do
        expect(merge_request.target_project.repository)
          .to receive(:ff_merge).and_return(nil)

        expect { strategy.execute_git_merge! }
          .to raise_exception(
            MergeRequests::MergeStrategies::StrategyError,
            'Fast-forward merge did not advance the target branch'
          )
      end
    end

    context 'when the fast-forward does not advance the target branch via the auto-rebase path' do
      before do
        project.merge_method = :ff
        project.save!
        project.project_setting.update!(automatic_rebase_enabled: true)
        allow(merge_request).to receive(:should_be_rebased?).and_return(true)
      end

      it 'raises when the rebased sha collapses onto the unchanged target tip' do
        expect_next_instance_of(MergeRequests::CreateRefService) do |instance|
          expect(instance).to receive(:execute).and_return(create_ref_service_response)
        end

        expect(merge_request.target_project.repository)
          .to receive(:ff_merge).and_return(target_branch_sha)

        expect { strategy.execute_git_merge! }
          .to raise_exception(
            MergeRequests::MergeStrategies::StrategyError,
            'Fast-forward merge did not advance the target branch'
          )
      end
    end

    context 'when the verify_ff_merge_advancement feature flag is disabled' do
      before do
        stub_feature_flags(verify_ff_merge_advancement: false)
        project.merge_method = :ff
        project.save!
      end

      it 'records the merge without guarding advancement (legacy behavior)' do
        # The legacy call must be byte-for-byte identical to the pre-fix code:
        # no target_sha: keyword is forwarded to ff_merge when the flag is off.
        expect(merge_request.target_project.repository)
          .to receive(:ff_merge)
          .with(user, anything, merge_request.target_branch, { merge_request: merge_request })
          .and_return(target_branch_sha)

        expect(strategy.execute_git_merge!).to eq({ commit_sha: target_branch_sha })
      end
    end
  end
end
