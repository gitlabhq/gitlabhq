# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestWidgetEntity do
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

  describe 'source_project_full_path' do
    it 'includes the full path of the source project' do
      expect(subject[:source_project_full_path]).to be_present
    end

    context 'when the source project is missing' do
      it 'returns `nil` for the source project' do
        resource.allow_broken = true
        resource.update!(source_project: nil)

        expect(subject[:source_project_full_path]).to be_nil
      end
    end
  end

  describe 'issues links' do
    it 'includes issues links when requested' do
      data = described_class.new(resource, request: request, issues_links: true).as_json

      expect(data).to include(:issues_links)
      expect(data[:issues_links]).to include(:assign_to_closing, :closing, :mentioned_but_not_closing)
    end

    it 'omits issue links by default' do
      expect(subject).not_to include(:issues_links)
    end
  end

  describe 'pipeline' do
    let(:pipeline) { create(:ci_empty_pipeline, project: project, ref: resource.source_branch, sha: resource.source_branch_sha, head_pipeline_of: resource) }

    before do
      allow_any_instance_of(MergeRequestPresenter).to receive(:can?).and_call_original
      allow_any_instance_of(MergeRequestPresenter).to receive(:can?).with(user, :read_pipeline, anything).and_return(result)
    end

    context 'when user has access to pipelines' do
      let(:result) { true }

      context 'when is up to date' do
        let(:req) { double('request', current_user: user, project: project) }

        it 'returns pipeline' do
          pipeline_payload = PipelineDetailsEntity
            .represent(pipeline, request: req)
            .as_json

          expect(subject[:pipeline]).to eq(pipeline_payload)
        end
      end

      context 'when is not up to date' do
        it 'returns nil' do
          pipeline.update(sha: "not up to date")

          expect(subject[:pipeline]).to eq(nil)
        end
      end
    end

    context 'when user does not have access to pipelines' do
      let(:result) { false }

      it 'does not have pipeline' do
        expect(subject[:pipeline]).to eq(nil)
      end
    end
  end

  describe 'merge_pipeline' do
    it 'returns nil' do
      expect(subject[:merge_pipeline]).to be_nil
    end

    context 'when is merged' do
      let(:resource) { create(:merged_merge_request, source_project: project, merge_commit_sha: project.commit.id) }
      let(:pipeline) { create(:ci_empty_pipeline, project: project, ref: resource.target_branch, sha: resource.merge_commit_sha) }

      before do
        project.add_maintainer(user)
      end

      it 'returns merge_pipeline' do
        pipeline.reload
        pipeline_payload = PipelineDetailsEntity
                             .represent(pipeline, request: request)
                             .as_json

        expect(subject[:merge_pipeline]).to eq(pipeline_payload)
      end

      context 'when user cannot read pipelines on target project' do
        before do
          project.add_guest(user)
        end

        it 'returns nil' do
          expect(subject[:merge_pipeline]).to be_nil
        end
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

  it 'has email_patches_path' do
    expect(subject[:email_patches_path])
      .to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}.patch")
  end

  it 'has plain_diff_path' do
    expect(subject[:plain_diff_path])
      .to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}.diff")
  end

  it 'has default_merge_commit_message_with_description' do
    expect(subject[:default_merge_commit_message_with_description])
      .to eq(resource.default_merge_commit_message(include_description: true))
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

  describe 'new_blob_path' do
    context 'when user can push to project' do
      it 'returns path' do
        project.add_developer(user)

        expect(subject[:new_blob_path])
          .to eq("/#{resource.project.full_path}/new/#{resource.source_branch}")
      end
    end

    context 'when user cannot push to project' do
      it 'returns nil' do
        expect(subject[:new_blob_path]).to be_nil
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

  describe 'when source project is deleted' do
    let(:project) { create(:project, :repository) }
    let(:forked_project) { fork_project(project) }
    let(:merge_request) { create(:merge_request, source_project: forked_project, target_project: project) }

    it 'returns a blank rebase_path' do
      allow(merge_request).to receive(:should_be_rebased?).and_return(true)
      forked_project.destroy
      merge_request.reload

      entity = described_class.new(merge_request, request: request).as_json

      expect(entity[:rebase_path]).to be_nil
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
        expect(subject[:auto_merge_strategy]).to eq('merge_when_pipeline_succeeds')
      end
    end

    context 'when auto merge is not enabled' do
      let(:resource) { create(:merge_request) }

      it 'returns auto merge related information' do
        expect(subject[:auto_merge_enabled]).to be_falsy
        expect(subject[:auto_merge_strategy]).to be_nil
      end
    end

    context 'when head pipeline is running' do
      before do
        create(:ci_pipeline, :running, project: project,
                                       ref: resource.source_branch,
                                       sha: resource.diff_head_sha)
        resource.update_head_pipeline
      end

      it 'returns available auto merge strategies' do
        expect(subject[:available_auto_merge_strategies]).to eq(%w[merge_when_pipeline_succeeds])
      end
    end

    context 'when head pipeline is finished' do
      before do
        create(:ci_pipeline, :success, project: project,
                                       ref: resource.source_branch,
                                       sha: resource.diff_head_sha)
        resource.update_head_pipeline
      end

      it 'returns available auto merge strategies' do
        expect(subject[:available_auto_merge_strategies]).to be_empty
      end
    end
  end

  describe 'exposed_artifacts_path' do
    context 'when merge request has exposed artifacts' do
      before do
        expect(resource).to receive(:has_exposed_artifacts?).and_return(true)
      end

      it 'set the path to poll data' do
        expect(subject[:exposed_artifacts_path]).to be_present
      end
    end

    context 'when merge request has no exposed artifacts' do
      before do
        expect(resource).to receive(:has_exposed_artifacts?).and_return(false)
      end

      it 'set the path to poll data' do
        expect(subject[:exposed_artifacts_path]).to be_nil
      end
    end
  end
end
