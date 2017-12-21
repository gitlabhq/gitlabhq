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

    context 'when no diff head commit' do
      it 'returns nil' do
        allow(resource).to receive(:diff_head_commit) { nil }

        expect(subject[:diff_head_sha]).to be_nil
      end
    end

    context 'when diff head commit present' do
      it 'returns diff head commit short id' do
        allow(resource).to receive(:diff_head_commit) { double }

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
end
