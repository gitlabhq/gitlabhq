require 'spec_helper'

describe MergeRequestSerializer do
  let(:resource) { create(:merge_request) }
  let(:user)     { build_stubbed(:user) }

  subject { described_class.new(current_user: user, user: user).represent(resource) }

  it 'includes author' do
    req = double('request', user: user)

    author_payload = UserEntity
      .represent(resource.author, request: req)
      .as_json

    expect(subject[:author]).to eql(author_payload)
  end

  it 'includes pipeline' do
    req = double('request', user: user)
    pipeline = build_stubbed(:ci_pipeline)
    allow(resource).to receive(:head_pipeline).and_return(pipeline)

    pipeline_payload = PipelineEntity
      .represent(pipeline, request: req)
      .as_json

    expect(subject[:pipeline]).to eql(pipeline_payload)
  end

  it 'has important MergeRequest attributes' do
    expect(subject).to include(:diff_head_sha, :merge_commit_message,
                              :can_be_merged, :can_be_cherry_picked,
                              :has_conflicts)
  end

  context 'current_user attributes' do
    it '' do
    end
  end

  it 'has merge_path' do
    expect(subject[:merge_path])
      .to eql("/#{resource.project.full_path}/merge_requests/#{resource.iid}/merge")
  end

  it 'has remove_wip_path' do
    expect(subject[:remove_wip_path])
      .to eql("/#{resource.project.full_path}/merge_requests/#{resource.iid}/remove_wip")
  end

  it 'has conflict_resolution_ui_path' do
    expect(subject[:conflict_resolution_ui_path])
      .to eql("/#{resource.project.full_path}/merge_requests/#{resource.iid}/conflicts")
  end

  it 'has email_patches_path' do
    expect(subject[:email_patches_path])
      .to eql("/#{resource.project.full_path}/merge_requests/#{resource.iid}.patch")
  end

  it 'has plain_diff_path' do
    expect(subject[:plain_diff_path])
      .to eql("/#{resource.project.full_path}/merge_requests/#{resource.iid}.diff")
  end

  it 'has plain_diff_path' do
    expect(subject[:plain_diff_path])
      .to eql("/#{resource.project.full_path}/merge_requests/#{resource.iid}.diff")
  end

  it 'has target_branch_path' do
    expect(subject[:source_branch_path])
      .to eql("/#{resource.project.full_path}/branches/#{resource.source_branch}")
  end

  it 'has source_branch_path' do
    expect(subject[:source_branch_path])
      .to eql("/#{resource.source_project.full_path}/branches/#{resource.source_branch}")
  end

  it 'has merge_commit_message_with_description' do
    expect(subject[:merge_commit_message_with_description])
      .to eql(resource.merge_commit_message(include_description: true))
  end

  describe 'diverged_commits_count' do
    context 'when MR open and its diverging' do
      it 'returns diverged commits count' do
        allow(resource).to receive_messages(open?: true, diverged_from_target_branch?: true,
                                            diverged_commits_count: 10)

        expect(subject[:diverged_commits_count]).to eql(10)
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
