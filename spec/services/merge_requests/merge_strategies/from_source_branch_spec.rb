# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeStrategies::FromSourceBranch, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }

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

    context 'when rebase_on_merge_automatic ff is off' do
      before do
        stub_feature_flags(rebase_on_merge_automatic: false)
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

    context 'when we are using ff only strategy' do
      before do
        project.merge_method = :ff
        project.save!
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
            .with(user, '11', merge_request.target_branch, { merge_request: merge_request })
            .and_return('1234')

          expect(merge_request).to receive(:schedule_cleanup_refs).with(only: [:rebase_on_merge_path])

          expect(strategy.execute_git_merge!).to eq({ commit_sha: '1234' })
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
      end

      it 'fast forward merges with the commit sha from the create ref service' do
        expect_next_instance_of(MergeRequests::CreateRefService) do |instance|
          expect(instance).to receive(:execute).and_return(create_ref_service_response)
        end

        expect(merge_request.target_project.repository)
          .to receive(:ff_merge)
          .with(user, '11', merge_request.target_branch, { merge_request: merge_request })
          .and_return('1234')

        expect(merge_request).to receive(:schedule_cleanup_refs).with(only: [:rebase_on_merge_path])

        expect(strategy.execute_git_merge!).to eq({ commit_sha: '1234' })
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

    context 'when rebase_on_merge_automatic ff is off' do
      before do
        stub_feature_flags(rebase_on_merge_automatic: false)
      end

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
  end
end
