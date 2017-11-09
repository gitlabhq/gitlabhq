require 'spec_helper'

describe MergeRequestEntity do
  let(:project)  { create :project, :repository }
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject do
    described_class.new(resource, request: request).as_json
  end

  it 'includes pipeline' do
    req = double('request', current_user: user)
    pipeline = build_stubbed(:ci_pipeline)
    allow(resource).to receive(:head_pipeline).and_return(pipeline)

    pipeline_payload = PipelineDetailsEntity
      .represent(pipeline, request: req)
      .as_json

    expect(subject[:pipeline]).to eq(pipeline_payload)
  end

  it 'includes issues_links' do
    issues_links = subject[:issues_links]

    expect(issues_links).to include(:closing, :mentioned_but_not_closing,
                                    :assign_to_closing)
  end

  it 'has Issuable attributes' do
    expect(subject).to include(:id, :iid, :author_id, :description, :lock_version, :milestone_id,
                               :title, :updated_by_id, :created_at, :updated_at, :milestone, :labels)
  end

  it 'has time estimation attributes' do
    expect(subject).to include(:time_estimate, :total_time_spent, :human_time_estimate, :human_total_time_spent)
  end

  it 'has important MergeRequest attributes' do
    expect(subject).to include(:state, :deleted_at, :diff_head_sha, :merge_commit_message,
                               :has_conflicts, :has_ci, :merge_path,
                               :conflict_resolution_path,
                               :cancel_merge_when_pipeline_succeeds_path,
                               :create_issue_to_resolve_discussions_path,
                               :source_branch_path, :target_branch_commits_path,
                               :target_branch_tree_path, :commits_count, :merge_ongoing,
                               :ff_only_enabled)
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

  it 'includes merge_event' do
    create(:event, :merged, author: user, project: resource.project, target: resource)

    expect(subject[:merge_event]).to include(:author, :updated_at)
  end

  it 'includes closed_event' do
    create(:event, :closed, author: user, project: resource.project, target: resource)

    expect(subject[:closed_event]).to include(:author, :updated_at)
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
