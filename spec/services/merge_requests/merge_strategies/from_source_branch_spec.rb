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

  describe '#execute_git_merge!' do
    context 'when fast-forward is required' do
      before do
        project.merge_method = :ff
        project.save!
      end

      it 'performs a fast-forward merge' do
        expect(merge_request.target_project.repository).to receive(:ff_merge).and_return('1234')

        strategy.execute_git_merge!
      end
    end

    context 'when a merge commit is required' do
      before do
        project.merge_method = :merge
        project.save!
      end

      it 'performs standard merge' do
        expect(merge_request.target_project.repository).to receive(:merge).and_return('1234')

        strategy.execute_git_merge!
      end
    end
  end
end
