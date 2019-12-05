# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestPollCachedWidgetEntity do
  include ProjectForksHelper

  let(:project)  { create :project, :repository }
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user, project: project) }

  subject do
    described_class.new(resource, request: request).as_json
  end

  it 'has the latest sha of the target branch' do
    is_expected.to include(:target_branch_sha)
  end

  describe 'diverged_commits_count' do
    context 'when MR open and its diverging' do
      it 'returns diverged commits count' do
        allow(resource).to receive_messages(open?: true, diverged_from_target_branch?: true,
                                            diverged_commits_count: 10)

        expect(subject[:diverged_commits_count]).to eq(10)
      end
    end

    context 'when MR is not open' do
      it 'returns 0' do
        allow(resource).to receive_messages(open?: false)

        expect(subject[:diverged_commits_count]).to be_zero
      end
    end

    context 'when MR is not diverging' do
      it 'returns 0' do
        allow(resource).to receive_messages(open?: true, diverged_from_target_branch?: false)

        expect(subject[:diverged_commits_count]).to be_zero
      end
    end
  end

  describe 'diff_head_sha' do
    before do
      allow(resource).to receive(:diff_head_sha) { 'sha' }
    end

    context 'when diff head commit is empty' do
      it 'returns nil' do
        allow(resource).to receive(:diff_head_sha) { '' }

        expect(subject[:diff_head_sha]).to be_nil
      end
    end

    context 'when diff head commit present' do
      it 'returns diff head commit short id' do
        expect(subject[:diff_head_sha]).to eq('sha')
      end
    end
  end

  describe 'metrics' do
    context 'when metrics record exists with merged data' do
      before do
        resource.mark_as_merged!
        resource.metrics.update!(merged_by: user)
      end

      it 'matches merge request metrics schema' do
        expect(subject[:metrics].with_indifferent_access)
          .to match_schema('entities/merge_request_metrics')
      end

      it 'returns values from metrics record' do
        expect(subject.dig(:metrics, :merged_by, :id))
          .to eq(resource.metrics.merged_by_id)
      end
    end

    context 'when metrics record exists with closed data' do
      before do
        resource.close!
        resource.metrics.update!(latest_closed_by: user)
      end

      it 'matches merge request metrics schema' do
        expect(subject[:metrics].with_indifferent_access)
          .to match_schema('entities/merge_request_metrics')
      end

      it 'returns values from metrics record' do
        expect(subject.dig(:metrics, :closed_by, :id))
          .to eq(resource.metrics.latest_closed_by_id)
      end
    end

    context 'when metrics does not exists' do
      before do
        resource.mark_as_merged!
        resource.metrics.destroy!
        resource.reload
      end

      context 'when events exists' do
        let!(:closed_event) { create(:event, :closed, project: project, target: resource) }
        let!(:merge_event) { create(:event, :merged, project: project, target: resource) }

        it 'matches merge request metrics schema' do
          expect(subject[:metrics].with_indifferent_access)
            .to match_schema('entities/merge_request_metrics')
        end

        it 'returns values from events record' do
          expect(subject.dig(:metrics, :merged_by, :id))
            .to eq(merge_event.author_id)

          expect(subject.dig(:metrics, :closed_by, :id))
            .to eq(closed_event.author_id)

          expect(subject.dig(:metrics, :merged_at).to_s)
            .to eq(merge_event.updated_at.to_s)

          expect(subject.dig(:metrics, :closed_at).to_s)
            .to eq(closed_event.updated_at.to_s)
        end
      end

      context 'when events does not exists' do
        it 'matches merge request metrics schema' do
          expect(subject[:metrics].with_indifferent_access)
            .to match_schema('entities/merge_request_metrics')
        end
      end
    end
  end

  describe 'commits_without_merge_commits' do
    def find_matching_commit(short_id)
      resource.commits.find { |c| c.short_id == short_id }
    end

    it 'does not include merge commits' do
      commits_in_widget = subject[:commits_without_merge_commits]

      expect(commits_in_widget.length).to be < resource.commits.length
      expect(commits_in_widget.length).to eq(resource.commits.without_merge_commits.length)
      commits_in_widget.each do |c|
        expect(find_matching_commit(c[:short_id]).merge_commit?).to eq(false)
      end
    end
  end

  describe 'auto merge' do
    context 'when auto merge is enabled' do
      let(:resource) { create(:merge_request, :merge_when_pipeline_succeeds) }

      it 'returns auto merge related information' do
        expect(subject[:auto_merge_enabled]).to be_truthy
      end
    end

    context 'when auto merge is not enabled' do
      let(:resource) { create(:merge_request) }

      it 'returns auto merge related information' do
        expect(subject[:auto_merge_enabled]).to be_falsy
      end
    end
  end

  describe 'attributes for squash commit message' do
    context 'when merge request is mergeable' do
      before do
        stub_const('MergeRequestDiff::COMMITS_SAFE_SIZE', 20)
      end

      it 'has default_squash_commit_message and commits_without_merge_commits' do
        expect(subject[:default_squash_commit_message])
          .to eq(resource.default_squash_commit_message)
        expect(subject[:commits_without_merge_commits].size).to eq(12)
      end
    end

    context 'when merge request is not mergeable' do
      before do
        allow(resource).to receive(:mergeable?).and_return(false)
      end

      it 'does not have default_squash_commit_message and commits_without_merge_commits' do
        expect(subject[:default_squash_commit_message]).to eq(nil)
        expect(subject[:commits_without_merge_commits]).to eq(nil)
      end
    end
  end
end
