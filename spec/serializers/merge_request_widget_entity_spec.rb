require 'spec_helper'

describe MergeRequestWidgetEntity do
  let(:project)  { create :project, :repository }
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user, project: project) }

  subject do
    described_class.new(resource, request: request).as_json
  end

  describe 'pipeline' do
    let(:pipeline) { create(:ci_empty_pipeline, project: project, ref: resource.source_branch, sha: resource.source_branch_sha, head_pipeline_of: resource) }

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

        expect(subject[:pipeline]).to be_nil
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

  it 'has merge_commit_message_with_description' do
    expect(subject[:merge_commit_message_with_description])
      .to eq(resource.merge_commit_message(include_description: true))
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
    let(:fork_project) { create(:project, :repository, forked_from_project: project) }
    let(:merge_request) { create(:merge_request, source_project: fork_project, target_project: project) }

    it 'returns a blank rebase_path' do
      allow(merge_request).to receive(:should_be_rebased?).and_return(true)
      fork_project.destroy
      merge_request.reload

      entity = described_class.new(merge_request, request: request).as_json

      expect(entity[:rebase_path]).to be_nil
    end
  end

  describe 'has_new_ci_config' do
    context 'when merge request has a new gitlab-ci.yml file' do
      before do
        allow(resource).to receive(:merge_request_diff).and_call_original
        allow(resource).to receive_message_chain(:merge_request_diff, :merge_request_diff_files, :where, :any?).and_return(true)
      end

      it 'returns true' do
        expect(subject[:has_new_ci_config]).to eq true
      end
    end

    context 'when merge request does not have a new gitlab-ci.yml file' do
      before do
        allow(resource).to receive(:merge_request_diff).and_call_original
        allow(resource).to receive_message_chain(:merge_request_diff, :merge_request_diff_files, :where, :any?).and_return(false)
      end

      it 'returns false' do
        expect(subject[:has_new_ci_config]).to eq false
      end
    end
  end
end
