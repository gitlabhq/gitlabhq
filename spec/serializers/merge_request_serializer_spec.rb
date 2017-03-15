require 'spec_helper'

describe MergeRequestSerializer do
  let(:resource) { create(:merge_request) }
  let(:user)     { create(:user) }

  subject { described_class.new(current_user: user).represent(resource) }

  it 'includes author' do
    req = double('request')

    author_payload = UserEntity
      .represent(resource.author, request: req)
      .as_json

    expect(subject[:author]).to eql(author_payload)
  end

  it 'includes pipeline' do
    req = double('request', current_user: user)
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

  it 'has target_branch_path' do
    expect(subject[:target_branch_path])
      .to eql("/#{resource.target_project.full_path}/branches/#{resource.target_branch}")
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

  context 'current_user' do
    describe 'can_update_merge_request' do
      context 'user can update issue' do
        it 'returns true' do
          resource.project.team << [user, :developer]

          expect(subject[:current_user][:can_update_merge_request]).to eql(true)
        end
      end

      context 'user cannot update issue' do
        it 'returns false' do
          expect(subject[:current_user][:can_update_merge_request]).to eql(false)
        end
      end
    end
  end

  context 'issues_links' do
    let(:project) { create(:project, :private, creator: user, namespace: user.namespace) }
    let(:issue_a) { create(:issue, project: project) }
    let(:issue_b) { create(:issue, project: project) }

    let(:resource) do
      create(:merge_request,
             source_project: project, target_project: project,
             description: "Fixes #{issue_a.to_reference} Related #{issue_b.to_reference}")
    end

    before do
      project.team << [user, :developer]

      allow(resource.project).to receive(:default_branch)
        .and_return(resource.target_branch)
    end

    describe 'closing' do
      let(:sentence) { subject[:issues_links][:closing] }

      it 'presents closing issues links' do
        expect(sentence).to match("#{project.full_path}/issues/#{issue_a.iid}")
      end

      it 'does not present related issues links' do
        expect(sentence).not_to match("#{project.full_path}/issues/#{issue_b.iid}")
      end
    end

    describe 'mentioned_but_not_closing' do
      let(:sentence) { subject[:issues_links][:mentioned_but_not_closing] }

      it 'presents related issues links' do
        expect(sentence).to match("#{project.full_path}/issues/#{issue_b.iid}")
      end

      it 'does not present closing issues links' do
        expect(sentence).not_to match("#{project.full_path}/issues/#{issue_a.iid}")
      end
    end
  end
end
