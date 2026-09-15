# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeStrategies::FromSourceBranch, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:user2) { create(:user) }

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
      instance_double(ServiceResponse, error?: false, payload: { commit_sha: '11' })
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

        context 'and the create ref service returns a rebase conflict error' do
          let(:create_ref_service_response) do
            instance_double(
              ServiceResponse,
              error?: true,
              message: '9:failed to rebase deadbeef on cafe1234 while preparing ' \
                'refs/mr/1/rebase_on_merge due to conflict',
              reason: MergeRequests::CreateRefService::REBASE_CONFLICT,
              payload: { commit_sha: '11' }
            )
          end

          it 'raises an actionable strategy error and does not attempt the fast-forward merge' do
            expect_next_instance_of(MergeRequests::CreateRefService) do |instance|
              expect(instance).to receive(:execute).and_return(create_ref_service_response)
            end

            expect(merge_request.target_project.repository).not_to receive(:ff_merge)

            expect { strategy.execute_git_merge! }
              .to raise_error(
                MergeRequests::MergeStrategies::StrategyError,
                'Automatic rebase before merge failed because the source branch conflicts ' \
                  'with the target branch. Rebase the source branch manually and resolve the conflicts.'
              )
          end
        end

        context 'and the create ref service returns a non-conflict error' do
          let(:create_ref_service_response) do
            instance_double(
              ServiceResponse,
              error?: true,
              message: '9:some internal gitaly failure',
              reason: nil,
              payload: {}
            )
          end

          it 'raises a non-strategy error so the generic merge error is shown' do
            expect_next_instance_of(MergeRequests::CreateRefService) do |instance|
              expect(instance).to receive(:execute).and_return(create_ref_service_response)
            end

            expect(merge_request.target_project.repository).not_to receive(:ff_merge)

            expect { strategy.execute_git_merge! }
              .to raise_error(RuntimeError, '9:some internal gitaly failure')
          end
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

      context 'and deleting the generated ref commits fails' do
        let(:cleanup_error) { ActiveRecord::StatementInvalid.new('PG::UnableToSend') }

        before do
          allow(MergeRequests::GeneratedRefCommit).to receive(:delete_all_for).and_raise(cleanup_error)
        end

        it 'reports the cleanup failure and still raises the merge error' do
          expect_next_instance_of(MergeRequests::CreateRefService) do |instance|
            expect(instance).to receive(:execute).and_return(create_ref_service_response)
          end

          expect(merge_request.target_project.repository)
            .to receive(:ff_merge).and_return(target_branch_sha)

          expect(Gitlab::ErrorTracking)
            .to receive(:track_exception).with(cleanup_error, merge_request_id: merge_request.id)

          expect { strategy.execute_git_merge! }
            .to raise_exception(
              MergeRequests::MergeStrategies::StrategyError,
              'Fast-forward merge did not advance the target branch'
            )
        end
      end
    end
  end

  # The automatic-rebase path rewrites the source commits, so the merge request
  # diff no longer names any SHA that reaches the target branch. Without a
  # generated_ref_commits row per rewritten commit, nothing links them back.
  # See https://gitlab.com/gitlab-com/request-for-help/-/work_items/5340.
  describe 'commit to merge request association after an automatic rebase' do
    # Not let_it_be: every example merges, which advances the target branch, and
    # Gitaly repositories are not rolled back between examples. A shared
    # repository would leave the second example with nothing to rebase.
    let(:project) { create(:project, :empty_repo) }
    let(:target_branch) { project.default_branch_or_main }
    let(:source_branch) { 'feature' }

    let(:merge_request) do
      create(
        :merge_request,
        author: user,
        source_project: project,
        target_project: project,
        source_branch: source_branch,
        target_branch: target_branch
      )
    end

    before do
      commit_file('README.md', 'Base commit 1', target_branch)
      project.repository.create_branch(source_branch, target_branch)
      commit_file('a.txt', 'Feature commit 1', source_branch)
      commit_file('b.txt', 'Feature commit 2', source_branch)
      # Advance the target so the source branch is behind and a rebase is required.
      commit_file('EXTRA', 'Base commit 2', target_branch)

      project.project_setting.update!(automatic_rebase_enabled: true)
    end

    shared_examples 'links every merged commit to the merge request' do
      it 'leaves no commit on the target branch without its merge request', :aggregate_failures do
        target_sha_before = project.repository.commit(target_branch).sha

        strategy.execute_git_merge!

        merged_shas = project.repository
          .commits_between(target_sha_before, project.repository.commit(target_branch).sha)
          .map(&:sha)

        found = merged_shas.index_with do |sha|
          MergeRequest.by_related_commit_sha(project, sha).pluck(:iid)
        end

        expect(merged_shas).to be_present
        expect(found).to eq(merged_shas.index_with { [merge_request.iid] })
      end
    end

    context 'when the project uses semi-linear history' do
      before do
        project.merge_method = :rebase_merge
        project.save!
      end

      it_behaves_like 'links every merged commit to the merge request'
    end

    context 'when the project uses fast-forward merges' do
      before do
        project.merge_method = :ff
        project.save!
      end

      it_behaves_like 'links every merged commit to the merge request'
    end

    context 'when the fast-forward never lands' do
      before do
        project.merge_method = :ff
        project.save!

        # Gitaly can swallow a failed reference update and report no commit.
        allow(merge_request.project.repository).to receive(:ff_merge).and_return(nil)
      end

      it 'deletes the generated ref commits recorded for the attempt' do
        expect { strategy.execute_git_merge! }
          .to raise_error(MergeRequests::MergeStrategies::StrategyError)

        expect(MergeRequests::GeneratedRefCommit.where(project: project, merge_request: merge_request))
          .to be_empty
      end
    end

    def commit_file(path, message, branch)
      project.repository.create_file(project.creator, path, '', message: message, branch_name: branch)
    end
  end
end
