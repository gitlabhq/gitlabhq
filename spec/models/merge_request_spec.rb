require 'spec_helper'

describe MergeRequest do
  include RepoHelpers
  include ProjectForksHelper

  subject { create(:merge_request) }

  describe 'associations' do
    it { is_expected.to belong_to(:target_project).class_name('Project') }
    it { is_expected.to belong_to(:source_project).class_name('Project') }
    it { is_expected.to belong_to(:merge_user).class_name("User") }
    it { is_expected.to belong_to(:assignee) }
    it { is_expected.to have_many(:merge_request_diffs) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(NonatomicInternalId) }
    it { is_expected.to include_module(Issuable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(Taskable) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:target_branch) }
    it { is_expected.to validate_presence_of(:source_branch) }

    context "Validation of merge user with Merge When Pipeline Succeeds" do
      it "allows user to be nil when the feature is disabled" do
        expect(subject).to be_valid
      end

      it "is invalid without merge user" do
        subject.merge_when_pipeline_succeeds = true
        expect(subject).not_to be_valid
      end

      it "is valid with merge user" do
        subject.merge_when_pipeline_succeeds = true
        subject.merge_user = build(:user)

        expect(subject).to be_valid
      end
    end

    context 'for forks' do
      let(:project) { create(:project) }
      let(:fork1) { fork_project(project) }
      let(:fork2) { fork_project(project) }

      it 'allows merge requests for sibling-forks' do
        subject.source_project = fork1
        subject.target_project = fork2

        expect(subject).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe '#ensure_merge_request_metrics' do
      it 'creates metrics after saving' do
        merge_request = create(:merge_request)

        expect(merge_request.metrics).to be_persisted
        expect(MergeRequest::Metrics.count).to eq(1)
      end

      it 'does not duplicate metrics for a merge request' do
        merge_request = create(:merge_request)

        merge_request.mark_as_merged!

        expect(MergeRequest::Metrics.count).to eq(1)
      end
    end
  end

  describe 'respond to' do
    it { is_expected.to respond_to(:unchecked?) }
    it { is_expected.to respond_to(:can_be_merged?) }
    it { is_expected.to respond_to(:cannot_be_merged?) }
    it { is_expected.to respond_to(:merge_params) }
    it { is_expected.to respond_to(:merge_when_pipeline_succeeds) }
  end

  describe '.by_commit_sha' do
    subject(:by_commit_sha) { described_class.by_commit_sha(sha) }

    let!(:merge_request) { create(:merge_request, :with_diffs) }

    context 'with sha contained in latest merge request diff' do
      let(:sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }

      it 'returns merge requests' do
        expect(by_commit_sha).to eq([merge_request])
      end
    end

    context 'with sha contained not in latest merge request diff' do
      let(:sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }

      it 'returns empty requests' do
        latest_merge_request_diff = merge_request.merge_request_diffs.create
        latest_merge_request_diff.merge_request_diff_commits.where(sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0').delete_all

        expect(by_commit_sha).to be_empty
      end
    end

    context 'with sha not contained in' do
      let(:sha) { 'b83d6e3' }

      it 'returns empty result' do
        expect(by_commit_sha).to be_empty
      end
    end
  end

  describe '.in_projects' do
    it 'returns the merge requests for a set of projects' do
      expect(described_class.in_projects(Project.all)).to eq([subject])
    end
  end

  describe '.set_latest_merge_request_diff_ids!' do
    def create_merge_request_with_diffs(source_branch, diffs: 2)
      params = {
        target_project: project,
        target_branch: 'master',
        source_project: project,
        source_branch: source_branch
      }

      create(:merge_request, params).tap do |mr|
        diffs.times { mr.merge_request_diffs.create }
      end
    end

    let(:project) { create(:project) }

    it 'sets IDs for merge requests, whether they are already set or not' do
      merge_requests = [
        create_merge_request_with_diffs('feature'),
        create_merge_request_with_diffs('feature-conflict'),
        create_merge_request_with_diffs('wip', diffs: 0),
        create_merge_request_with_diffs('csv')
      ]

      merge_requests.take(2).each do |merge_request|
        merge_request.update_column(:latest_merge_request_diff_id, nil)
      end

      expected = merge_requests.map do |merge_request|
        merge_request.merge_request_diffs.maximum(:id)
      end

      expect { project.merge_requests.set_latest_merge_request_diff_ids! }
        .to change { merge_requests.map { |mr| mr.reload.latest_merge_request_diff_id } }.to(expected)
    end
  end

  describe '#target_branch_sha' do
    let(:project) { create(:project, :repository) }

    subject { create(:merge_request, source_project: project, target_project: project) }

    context 'when the target branch does not exist' do
      before do
        project.repository.rm_branch(subject.author, subject.target_branch)
        subject.clear_memoized_shas
      end

      it 'returns nil' do
        expect(subject.target_branch_sha).to be_nil
      end
    end

    it 'returns memoized value' do
      subject.target_branch_sha = '8ffb3c15a5475e59ae909384297fede4badcb4c7'

      expect(subject.target_branch_sha).to eq '8ffb3c15a5475e59ae909384297fede4badcb4c7'
    end
  end

  describe '#card_attributes' do
    it 'includes the author name' do
      allow(subject).to receive(:author).and_return(double(name: 'Robert'))
      allow(subject).to receive(:assignee).and_return(nil)

      expect(subject.card_attributes)
        .to eq({ 'Author' => 'Robert', 'Assignee' => nil })
    end

    it 'includes the assignee name' do
      allow(subject).to receive(:author).and_return(double(name: 'Robert'))
      allow(subject).to receive(:assignee).and_return(double(name: 'Douwe'))

      expect(subject.card_attributes)
        .to eq({ 'Author' => 'Robert', 'Assignee' => 'Douwe' })
    end
  end

  describe '#assignee_ids' do
    it 'returns an array of the assigned user id' do
      subject.assignee_id = 123

      expect(subject.assignee_ids).to eq([123])
    end
  end

  describe '#assignee_ids=' do
    it 'sets assignee_id to the last id in the array' do
      subject.assignee_ids = [123, 456]

      expect(subject.assignee_id).to eq(456)
    end
  end

  describe '#assignee_or_author?' do
    let(:user) { create(:user) }

    it 'returns true for a user that is assigned to a merge request' do
      subject.assignee = user

      expect(subject.assignee_or_author?(user)).to eq(true)
    end

    it 'returns true for a user that is the author of a merge request' do
      subject.author = user

      expect(subject.assignee_or_author?(user)).to eq(true)
    end

    it 'returns false for a user that is not the assignee or author' do
      expect(subject.assignee_or_author?(user)).to eq(false)
    end
  end

  describe '#cache_merge_request_closes_issues!' do
    before do
      subject.project.add_developer(subject.author)
      subject.target_branch = subject.project.default_branch
    end

    it 'caches closed issues' do
      issue  = create :issue, project: subject.project
      commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
      allow(subject).to receive(:commits).and_return([commit])

      expect { subject.cache_merge_request_closes_issues!(subject.author) }.to change(subject.merge_requests_closing_issues, :count).by(1)
    end

    context 'when both internal and external issue trackers are enabled' do
      before do
        subject.project.has_external_issue_tracker = true
        subject.project.save!
        create(:jira_service, project: subject.project)
      end

      it 'does not cache issues from external trackers' do
        issue  = ExternalIssue.new('JIRA-123', subject.project)
        commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
        allow(subject).to receive(:commits).and_return([commit])

        expect { subject.cache_merge_request_closes_issues!(subject.author) }.not_to raise_error
        expect { subject.cache_merge_request_closes_issues!(subject.author) }.not_to change(subject.merge_requests_closing_issues, :count)
      end

      it 'caches an internal issue' do
        issue  = create(:issue, project: subject.project)
        commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
        allow(subject).to receive(:commits).and_return([commit])

        expect { subject.cache_merge_request_closes_issues!(subject.author) }
          .to change(subject.merge_requests_closing_issues, :count).by(1)
      end
    end

    context 'when only external issue tracker enabled' do
      before do
        subject.project.has_external_issue_tracker = true
        subject.project.issues_enabled = false
        subject.project.save!
      end

      it 'does not cache issues from external trackers' do
        issue  = ExternalIssue.new('JIRA-123', subject.project)
        commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
        allow(subject).to receive(:commits).and_return([commit])

        expect { subject.cache_merge_request_closes_issues!(subject.author) }.not_to change(subject.merge_requests_closing_issues, :count)
      end

      it 'does not cache an internal issue' do
        issue  = create(:issue, project: subject.project)
        commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
        allow(subject).to receive(:commits).and_return([commit])

        expect { subject.cache_merge_request_closes_issues!(subject.author) }
          .not_to change(subject.merge_requests_closing_issues, :count)
      end
    end
  end

  describe '#source_branch_sha' do
    let(:last_branch_commit) { subject.source_project.repository.commit(Gitlab::Git::BRANCH_REF_PREFIX + subject.source_branch) }

    context 'with diffs' do
      subject { create(:merge_request, :with_diffs) }
      it 'returns the sha of the source branch last commit' do
        expect(subject.source_branch_sha).to eq(last_branch_commit.sha)
      end
    end

    context 'without diffs' do
      subject { create(:merge_request, :without_diffs) }
      it 'returns the sha of the source branch last commit' do
        expect(subject.source_branch_sha).to eq(last_branch_commit.sha)
      end

      context 'when there is a tag name matching the branch name' do
        let(:tag_name) { subject.source_branch }

        it 'returns the sha of the source branch last commit' do
          subject.source_project.repository.add_tag(subject.author,
                                                    tag_name,
                                                    subject.target_branch_sha,
                                                    'Add a tag')

          expect(subject.source_branch_sha).to eq(last_branch_commit.sha)

          subject.source_project.repository.rm_tag(subject.author, tag_name)
        end
      end
    end

    context 'when the merge request is being created' do
      subject { build(:merge_request, source_branch: nil, compare_commits: []) }
      it 'returns nil' do
        expect(subject.source_branch_sha).to be_nil
      end
    end

    it 'returns memoized value' do
      subject.source_branch_sha = '2e5d3239642f9161dcbbc4b70a211a68e5e45e2b'

      expect(subject.source_branch_sha).to eq '2e5d3239642f9161dcbbc4b70a211a68e5e45e2b'
    end
  end

  describe '#to_reference' do
    let(:project) { build(:project, name: 'sample-project') }
    let(:merge_request) { build(:merge_request, target_project: project, iid: 1) }

    it 'returns a String reference to the object' do
      expect(merge_request.to_reference).to eq "!1"
    end

    it 'supports a cross-project reference' do
      another_project = build(:project, name: 'another-project', namespace: project.namespace)
      expect(merge_request.to_reference(another_project)).to eq "sample-project!1"
    end

    it 'returns a String reference with the full path' do
      expect(merge_request.to_reference(full: true)).to eq(project.full_path + '!1')
    end
  end

  describe '#raw_diffs' do
    let(:merge_request) { build(:merge_request) }
    let(:options) { { paths: ['a/b', 'b/a', 'c/*'] } }

    context 'when there are MR diffs' do
      it 'delegates to the MR diffs' do
        merge_request.merge_request_diff = MergeRequestDiff.new

        expect(merge_request.merge_request_diff).to receive(:raw_diffs).with(options)

        merge_request.raw_diffs(options)
      end
    end

    context 'when there are no MR diffs' do
      it 'delegates to the compare object' do
        merge_request.compare = double(:compare)

        expect(merge_request.compare).to receive(:raw_diffs).with(options)

        merge_request.raw_diffs(options)
      end
    end
  end

  describe '#diffs' do
    let(:merge_request) { build(:merge_request) }
    let(:options) { { paths: ['a/b', 'b/a', 'c/*'] } }

    context 'when there are MR diffs' do
      it 'delegates to the MR diffs' do
        merge_request.save

        expect(merge_request.merge_request_diff).to receive(:raw_diffs).with(hash_including(options))

        merge_request.diffs(options)
      end
    end

    context 'when there are no MR diffs' do
      it 'delegates to the compare object, setting expanded: true' do
        merge_request.compare = double(:compare)

        expect(merge_request.compare).to receive(:diffs).with(options.merge(expanded: true))

        merge_request.diffs(options)
      end
    end
  end

  describe '#diff_size' do
    let(:merge_request) do
      build(:merge_request, source_branch: 'expand-collapse-files', target_branch: 'master')
    end

    context 'when there are MR diffs' do
      it 'returns the correct count' do
        merge_request.save

        expect(merge_request.diff_size).to eq('105')
      end

      it 'returns the correct overflow count' do
        allow(Commit).to receive(:max_diff_options).and_return(max_files: 2)
        merge_request.save

        expect(merge_request.diff_size).to eq('2+')
      end

      it 'does not perform highlighting' do
        merge_request.save

        expect(Gitlab::Diff::Highlight).not_to receive(:new)

        merge_request.diff_size
      end
    end

    context 'when there are no MR diffs' do
      def set_compare(merge_request)
        merge_request.compare = CompareService.new(
          merge_request.source_project,
          merge_request.source_branch
        ).execute(
          merge_request.target_project,
          merge_request.target_branch
        )
      end

      it 'returns the correct count' do
        set_compare(merge_request)

        expect(merge_request.diff_size).to eq('105')
      end

      it 'returns the correct overflow count' do
        allow(Commit).to receive(:max_diff_options).and_return(max_files: 2)
        set_compare(merge_request)

        expect(merge_request.diff_size).to eq('2+')
      end

      it 'does not perform highlighting' do
        set_compare(merge_request)

        expect(Gitlab::Diff::Highlight).not_to receive(:new)

        merge_request.diff_size
      end
    end
  end

  describe "#related_notes" do
    let!(:merge_request) { create(:merge_request) }

    before do
      allow(merge_request).to receive(:commits) { [merge_request.source_project.repository.commit] }
      create(:note_on_commit, commit_id: merge_request.commits.first.id,
                              project: merge_request.project)
      create(:note, noteable: merge_request, project: merge_request.project)
    end

    it "includes notes for commits" do
      expect(merge_request.commits).not_to be_empty
      expect(merge_request.related_notes.count).to eq(2)
    end

    it "includes notes for commits from target project as well" do
      create(:note_on_commit, commit_id: merge_request.commits.first.id,
                              project: merge_request.target_project)

      expect(merge_request.commits).not_to be_empty
      expect(merge_request.related_notes.count).to eq(3)
    end
  end

  describe '#for_fork?' do
    it 'returns true if the merge request is for a fork' do
      subject.source_project = build_stubbed(:project, namespace: create(:group))
      subject.target_project = build_stubbed(:project, namespace: create(:group))

      expect(subject.for_fork?).to be_truthy
    end

    it 'returns false if is not for a fork' do
      expect(subject.for_fork?).to be_falsey
    end
  end

  describe '#closes_issues' do
    let(:issue0) { create :issue, project: subject.project }
    let(:issue1) { create :issue, project: subject.project }

    let(:commit0) { double('commit0', safe_message: "Fixes #{issue0.to_reference}") }
    let(:commit1) { double('commit1', safe_message: "Fixes #{issue0.to_reference}") }
    let(:commit2) { double('commit2', safe_message: "Fixes #{issue1.to_reference}") }

    before do
      subject.project.add_developer(subject.author)
      allow(subject).to receive(:commits).and_return([commit0, commit1, commit2])
    end

    it 'accesses the set of issues that will be closed on acceptance' do
      allow(subject.project).to receive(:default_branch)
        .and_return(subject.target_branch)

      closed = subject.closes_issues

      expect(closed).to include(issue0, issue1)
    end

    it 'only lists issues as to be closed if it targets the default branch' do
      allow(subject.project).to receive(:default_branch).and_return('master')
      subject.target_branch = 'something-else'

      expect(subject.closes_issues).to be_empty
    end
  end

  describe '#issues_mentioned_but_not_closing' do
    let(:closing_issue) { create :issue, project: subject.project }
    let(:mentioned_issue) { create :issue, project: subject.project }

    let(:commit) { double('commit', safe_message: "Fixes #{closing_issue.to_reference}") }

    it 'detects issues mentioned in description but not closed' do
      subject.project.add_developer(subject.author)
      subject.description = "Is related to #{mentioned_issue.to_reference} and #{closing_issue.to_reference}"

      allow(subject).to receive(:commits).and_return([commit])
      allow(subject.project).to receive(:default_branch)
        .and_return(subject.target_branch)

      expect(subject.issues_mentioned_but_not_closing(subject.author)).to match_array([mentioned_issue])
    end

    context 'when the project has an external issue tracker' do
      before do
        subject.project.add_developer(subject.author)
        commit = double(:commit, safe_message: 'Fixes TEST-3')

        create(:jira_service, project: subject.project)

        allow(subject).to receive(:commits).and_return([commit])
        allow(subject).to receive(:description).and_return('Is related to TEST-2 and TEST-3')
        allow(subject.project).to receive(:default_branch).and_return(subject.target_branch)
      end

      it 'detects issues mentioned in description but not closed' do
        expect(subject.issues_mentioned_but_not_closing(subject.author).map(&:to_s)).to match_array(['TEST-2'])
      end
    end
  end

  describe "#work_in_progress?" do
    ['WIP ', 'WIP:', 'WIP: ', '[WIP]', '[WIP] ', ' [WIP] WIP [WIP] WIP: WIP '].each do |wip_prefix|
      it "detects the '#{wip_prefix}' prefix" do
        subject.title = "#{wip_prefix}#{subject.title}"
        expect(subject.work_in_progress?).to eq true
      end
    end

    it "doesn't detect WIP for words starting with WIP" do
      subject.title = "Wipwap #{subject.title}"
      expect(subject.work_in_progress?).to eq false
    end

    it "doesn't detect WIP for words containing with WIP" do
      subject.title = "WupWipwap #{subject.title}"
      expect(subject.work_in_progress?).to eq false
    end

    it "doesn't detect WIP by default" do
      expect(subject.work_in_progress?).to eq false
    end
  end

  describe "#wipless_title" do
    ['WIP ', 'WIP:', 'WIP: ', '[WIP]', '[WIP] ', ' [WIP] WIP [WIP] WIP: WIP '].each do |wip_prefix|
      it "removes the '#{wip_prefix}' prefix" do
        wipless_title = subject.title
        subject.title = "#{wip_prefix}#{subject.title}"

        expect(subject.wipless_title).to eq wipless_title
      end

      it "is satisfies the #work_in_progress? method" do
        subject.title = "#{wip_prefix}#{subject.title}"
        subject.title = subject.wipless_title

        expect(subject.work_in_progress?).to eq false
      end
    end
  end

  describe "#wip_title" do
    it "adds the WIP: prefix to the title" do
      wip_title = "WIP: #{subject.title}"

      expect(subject.wip_title).to eq wip_title
    end

    it "does not add the WIP: prefix multiple times" do
      wip_title = "WIP: #{subject.title}"
      subject.title = subject.wip_title
      subject.title = subject.wip_title

      expect(subject.wip_title).to eq wip_title
    end

    it "is satisfies the #work_in_progress? method" do
      subject.title = subject.wip_title

      expect(subject.work_in_progress?).to eq true
    end
  end

  describe '#can_remove_source_branch?' do
    set(:user) { create(:user) }
    set(:merge_request) { create(:merge_request, :simple) }

    subject { merge_request }

    before do
      subject.source_project.add_master(user)
    end

    it "can't be removed when its a protected branch" do
      allow(ProtectedBranch).to receive(:protected?).and_return(true)

      expect(subject.can_remove_source_branch?(user)).to be_falsey
    end

    it "can't remove a root ref" do
      subject.update(source_branch: 'master', target_branch: 'feature')

      expect(subject.can_remove_source_branch?(user)).to be_falsey
    end

    it "is unable to remove the source branch for a project the user cannot push to" do
      user2 = create(:user)

      expect(subject.can_remove_source_branch?(user2)).to be_falsey
    end

    it "can be removed if the last commit is the head of the source branch" do
      allow(subject).to receive(:source_branch_head).and_return(subject.diff_head_commit)

      expect(subject.can_remove_source_branch?(user)).to be_truthy
    end

    it "cannot be removed if the last commit is not also the head of the source branch" do
      subject.clear_memoized_shas
      subject.source_branch = "lfs"

      expect(subject.can_remove_source_branch?(user)).to be_falsey
    end
  end

  describe '#merge_commit_message' do
    it 'includes merge information as the title' do
      request = build(:merge_request, source_branch: 'source', target_branch: 'target')

      expect(request.merge_commit_message)
        .to match("Merge branch 'source' into 'target'\n\n")
    end

    it 'includes its title in the body' do
      request = build(:merge_request, title: 'Remove all technical debt')

      expect(request.merge_commit_message)
        .to match("Remove all technical debt\n\n")
    end

    it 'includes its closed issues in the body' do
      issue = create(:issue, project: subject.project)

      subject.project.add_developer(subject.author)
      subject.description = "This issue Closes #{issue.to_reference}"

      allow(subject.project).to receive(:default_branch)
        .and_return(subject.target_branch)

      expect(subject.merge_commit_message)
        .to match("Closes #{issue.to_reference}")
    end

    it 'includes its reference in the body' do
      request = build_stubbed(:merge_request)

      expect(request.merge_commit_message)
        .to match("See merge request #{request.to_reference(full: true)}")
    end

    it 'excludes multiple linebreak runs when description is blank' do
      request = build(:merge_request, title: 'Title', description: nil)

      expect(request.merge_commit_message).not_to match("Title\n\n\n\n")
    end

    it 'includes its description in the body' do
      request = build(:merge_request, description: 'By removing all code')

      expect(request.merge_commit_message(include_description: true))
        .to match("By removing all code\n\n")
    end

    it 'does not includes its description in the body' do
      request = build(:merge_request, description: 'By removing all code')

      expect(request.merge_commit_message)
        .not_to match("By removing all code\n\n")
    end
  end

  describe "#reset_merge_when_pipeline_succeeds" do
    let(:merge_if_green) do
      create :merge_request, merge_when_pipeline_succeeds: true, merge_user: create(:user),
                             merge_params: { "should_remove_source_branch" => "1", "commit_message" => "msg" }
    end

    it "sets the item to false" do
      merge_if_green.reset_merge_when_pipeline_succeeds
      merge_if_green.reload

      expect(merge_if_green.merge_when_pipeline_succeeds).to be_falsey
      expect(merge_if_green.merge_params["should_remove_source_branch"]).to be_nil
      expect(merge_if_green.merge_params["commit_message"]).to be_nil
    end
  end

  describe '#hook_attrs' do
    it 'delegates to Gitlab::HookData::MergeRequestBuilder#build' do
      builder = double

      expect(Gitlab::HookData::MergeRequestBuilder)
        .to receive(:new).with(subject).and_return(builder)
      expect(builder).to receive(:build)

      subject.hook_attrs
    end
  end

  describe '#diverged_commits_count' do
    let(:project)      { create(:project, :repository) }
    let(:forked_project) { fork_project(project, nil, repository: true) }

    context 'when the target branch does not exist anymore' do
      subject { create(:merge_request, source_project: project, target_project: project) }

      before do
        project.repository.raw_repository.delete_branch(subject.target_branch)
        subject.clear_memoized_shas
      end

      it 'does not crash' do
        expect { subject.diverged_commits_count }.not_to raise_error
      end

      it 'returns 0' do
        expect(subject.diverged_commits_count).to eq(0)
      end
    end

    context 'diverged on same repository' do
      subject(:merge_request_with_divergence) { create(:merge_request, :diverged, source_project: project, target_project: project) }

      it 'counts commits that are on target branch but not on source branch' do
        expect(subject.diverged_commits_count).to eq(29)
      end
    end

    context 'diverged on fork' do
      subject(:merge_request_fork_with_divergence) { create(:merge_request, :diverged, source_project: forked_project, target_project: project) }

      it 'counts commits that are on target branch but not on source branch' do
        expect(subject.diverged_commits_count).to eq(29)
      end
    end

    context 'rebased on fork' do
      subject(:merge_request_rebased) { create(:merge_request, :rebased, source_project: forked_project, target_project: project) }

      it 'counts commits that are on target branch but not on source branch' do
        expect(subject.diverged_commits_count).to eq(0)
      end
    end

    describe 'caching' do
      before do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      end

      it 'caches the output' do
        expect(subject).to receive(:compute_diverged_commits_count)
          .once
          .and_return(2)

        subject.diverged_commits_count
        subject.diverged_commits_count
      end

      it 'invalidates the cache when the source sha changes' do
        expect(subject).to receive(:compute_diverged_commits_count)
          .twice
          .and_return(2)

        subject.diverged_commits_count
        allow(subject).to receive(:source_branch_sha).and_return('123abc')
        subject.diverged_commits_count
      end

      it 'invalidates the cache when the target sha changes' do
        expect(subject).to receive(:compute_diverged_commits_count)
          .twice
          .and_return(2)

        subject.diverged_commits_count
        allow(subject).to receive(:target_branch_sha).and_return('123abc')
        subject.diverged_commits_count
      end
    end
  end

  it_behaves_like 'an editable mentionable' do
    subject { create(:merge_request, :simple) }

    let(:backref_text) { "merge request #{subject.to_reference}" }
    let(:set_mentionable_text) { ->(txt) { subject.description = txt } }
  end

  it_behaves_like 'a Taskable' do
    subject { create :merge_request, :simple }
  end

  describe '#commit_shas' do
    before do
      allow(subject.merge_request_diff).to receive(:commit_shas)
        .and_return(['sha1'])
    end

    it 'delegates to merge request diff' do
      expect(subject.commit_shas).to eq ['sha1']
    end
  end

  context 'head pipeline' do
    before do
      allow(subject).to receive(:diff_head_sha).and_return('lastsha')
    end

    describe '#head_pipeline' do
      it 'returns nil for MR without head_pipeline_id' do
        subject.update_attribute(:head_pipeline_id, nil)

        expect(subject.head_pipeline).to be_nil
      end

      context 'when the source project does not exist' do
        it 'returns nil' do
          allow(subject).to receive(:source_project).and_return(nil)

          expect(subject.head_pipeline).to be_nil
        end
      end
    end

    describe '#actual_head_pipeline' do
      it 'returns nil for MR with old pipeline' do
        pipeline = create(:ci_empty_pipeline, sha: 'notlatestsha')
        subject.update_attribute(:head_pipeline_id, pipeline.id)

        expect(subject.actual_head_pipeline).to be_nil
      end

      it 'returns the pipeline for MR with recent pipeline' do
        pipeline = create(:ci_empty_pipeline, sha: 'lastsha')
        subject.update_attribute(:head_pipeline_id, pipeline.id)

        expect(subject.actual_head_pipeline).to eq(subject.head_pipeline)
        expect(subject.actual_head_pipeline).to eq(pipeline)
      end

      it 'returns nil when source project does not exist' do
        allow(subject).to receive(:source_project).and_return(nil)

        expect(subject.actual_head_pipeline).to be_nil
      end
    end
  end

  describe '#has_ci?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    context 'has ci' do
      it 'returns true if MR has head_pipeline_id and commits' do
        allow(merge_request).to receive_message_chain(:source_project, :ci_service) { nil }
        allow(merge_request).to receive(:head_pipeline_id) { double }
        allow(merge_request).to receive(:has_no_commits?) { false }

        expect(merge_request.has_ci?).to be(true)
      end

      it 'returns true if MR has any pipeline and commits' do
        allow(merge_request).to receive_message_chain(:source_project, :ci_service) { nil }
        allow(merge_request).to receive(:head_pipeline_id) { nil }
        allow(merge_request).to receive(:has_no_commits?) { false }
        allow(merge_request).to receive(:all_pipelines) { [double] }

        expect(merge_request.has_ci?).to be(true)
      end

      it 'returns true if MR has CI service and commits' do
        allow(merge_request).to receive_message_chain(:source_project, :ci_service) { double }
        allow(merge_request).to receive(:head_pipeline_id) { nil }
        allow(merge_request).to receive(:has_no_commits?) { false }
        allow(merge_request).to receive(:all_pipelines) { [] }

        expect(merge_request.has_ci?).to be(true)
      end
    end

    context 'has no ci' do
      it 'returns false if MR has no CI service nor pipeline, and no commits' do
        allow(merge_request).to receive_message_chain(:source_project, :ci_service) { nil }
        allow(merge_request).to receive(:head_pipeline_id) { nil }
        allow(merge_request).to receive(:all_pipelines) { [] }
        allow(merge_request).to receive(:has_no_commits?) { true }

        expect(merge_request.has_ci?).to be(false)
      end
    end
  end

  describe '#all_pipelines' do
    shared_examples 'returning pipelines with proper ordering' do
      let!(:all_pipelines) do
        subject.all_commit_shas.map do |sha|
          create(:ci_empty_pipeline,
                 project: subject.source_project,
                 sha: sha,
                 ref: subject.source_branch)
        end
      end

      it 'returns all pipelines' do
        expect(subject.all_pipelines).not_to be_empty
        expect(subject.all_pipelines).to eq(all_pipelines.reverse)
      end
    end

    context 'with single merge_request_diffs' do
      it_behaves_like 'returning pipelines with proper ordering'
    end

    context 'with multiple irrelevant merge_request_diffs' do
      before do
        subject.update(target_branch: 'v1.0.0')
      end

      it_behaves_like 'returning pipelines with proper ordering'
    end

    context 'with unsaved merge request' do
      subject { build(:merge_request) }

      let!(:pipeline) do
        create(:ci_empty_pipeline,
               project: subject.project,
               sha: subject.diff_head_sha,
               ref: subject.source_branch)
      end

      it 'returns pipelines from diff_head_sha' do
        expect(subject.all_pipelines).to contain_exactly(pipeline)
      end
    end
  end

  describe '#all_commit_shas' do
    context 'when merge request is persisted' do
      let(:all_commit_shas) do
        subject.merge_request_diffs.flat_map(&:commits).map(&:sha).uniq
      end

      shared_examples 'returning all SHA' do
        it 'returns all SHAs from all merge_request_diffs' do
          expect(subject.merge_request_diffs.size).to eq(2)
          expect(subject.all_commit_shas).to match_array(all_commit_shas)
        end
      end

      context 'with a completely different branch' do
        before do
          subject.update(target_branch: 'csv')
        end

        it_behaves_like 'returning all SHA'
      end

      context 'with a branch having no difference' do
        before do
          subject.update(target_branch: 'branch-merged')
          subject.reload # make sure commits were not cached
        end

        it_behaves_like 'returning all SHA'
      end
    end

    context 'when merge request is not persisted' do
      context 'when compare commits are set in the service' do
        let(:commit) { spy('commit') }

        subject do
          build(:merge_request, compare_commits: [commit, commit])
        end

        it 'returns commits from compare commits temporary data' do
          expect(subject.all_commit_shas).to eq [commit, commit]
        end
      end

      context 'when compare commits are not set in the service' do
        subject { build(:merge_request) }

        it 'returns array with diff head sha element only' do
          expect(subject.all_commit_shas).to eq [subject.diff_head_sha]
        end
      end
    end
  end

  describe '#can_be_reverted?' do
    context 'when there is no merge_commit for the MR' do
      before do
        subject.metrics.update!(merged_at: Time.now.utc)
      end

      it 'returns false' do
        expect(subject.can_be_reverted?(nil)).to be_falsey
      end
    end

    context 'when the MR has been merged' do
      before do
        MergeRequests::MergeService
          .new(subject.target_project, subject.author)
          .execute(subject)
      end

      context 'when there is no revert commit' do
        it 'returns true' do
          expect(subject.can_be_reverted?(nil)).to be_truthy
        end
      end

      context 'when there is no merged_at for the MR' do
        before do
          subject.metrics.update!(merged_at: nil)
        end

        it 'returns true' do
          expect(subject.can_be_reverted?(nil)).to be_truthy
        end
      end

      context 'when there is a revert commit' do
        let(:current_user) { subject.author }
        let(:branch) { subject.target_branch }
        let(:project) { subject.target_project }

        let(:revert_commit_id) do
          params = {
            commit: subject.merge_commit,
            branch_name: branch,
            start_branch: branch
          }

          Commits::RevertService.new(project, current_user, params).execute[:result]
        end

        before do
          project.add_master(current_user)

          ProcessCommitWorker.new.perform(project.id,
                                          current_user.id,
                                          project.commit(revert_commit_id).to_hash,
                                          project.default_branch == branch)
        end

        context 'when the revert commit is mentioned in a note after the MR was merged' do
          it 'returns false' do
            expect(subject.can_be_reverted?(current_user)).to be_falsey
          end
        end

        context 'when there is no merged_at for the MR' do
          before do
            subject.metrics.update!(merged_at: nil)
          end

          it 'returns false' do
            expect(subject.can_be_reverted?(current_user)).to be_falsey
          end
        end

        context 'when the revert commit is mentioned in a note just before the MR was merged' do
          before do
            subject.notes.last.update!(created_at: subject.metrics.merged_at - 30.seconds)
          end

          it 'returns false' do
            expect(subject.can_be_reverted?(current_user)).to be_falsey
          end
        end

        context 'when the revert commit is mentioned in a note long before the MR was merged' do
          before do
            subject.notes.last.update!(created_at: subject.metrics.merged_at - 2.minutes)
          end

          it 'returns true' do
            expect(subject.can_be_reverted?(current_user)).to be_truthy
          end
        end
      end
    end
  end

  describe '#participants' do
    let(:project) { create(:project, :public) }

    let(:mr) do
      create(:merge_request, source_project: project, target_project: project)
    end

    let!(:note1) do
      create(:note_on_merge_request, noteable: mr, project: project, note: 'a')
    end

    let!(:note2) do
      create(:note_on_merge_request, noteable: mr, project: project, note: 'b')
    end

    it 'includes the merge request author' do
      expect(mr.participants).to include(mr.author)
    end

    it 'includes the authors of the notes' do
      expect(mr.participants).to include(note1.author, note2.author)
    end
  end

  describe 'cached counts' do
    it 'updates when assignees change' do
      user1 = create(:user)
      user2 = create(:user)
      mr = create(:merge_request, assignee: user1)
      mr.project.add_developer(user1)
      mr.project.add_developer(user2)

      expect(user1.assigned_open_merge_requests_count).to eq(1)
      expect(user2.assigned_open_merge_requests_count).to eq(0)

      mr.assignee = user2
      mr.save

      expect(user1.assigned_open_merge_requests_count).to eq(0)
      expect(user2.assigned_open_merge_requests_count).to eq(1)
    end
  end

  describe '#merge_async' do
    it 'enqueues MergeWorker job and updates merge_jid' do
      merge_request = create(:merge_request)
      user_id = double(:user_id)
      params = double(:params)
      merge_jid = 'hash-123'

      expect(MergeWorker).to receive(:perform_async).with(merge_request.id, user_id, params) do
        merge_jid
      end

      merge_request.merge_async(user_id, params)

      expect(merge_request.reload.merge_jid).to eq(merge_jid)
    end
  end

  describe '#check_if_can_be_merged' do
    let(:project) { create(:project, only_allow_merge_if_pipeline_succeeds: true) }

    subject { create(:merge_request, source_project: project, merge_status: :unchecked) }

    context 'when it is not broken and has no conflicts' do
      before do
        allow(subject).to receive(:broken?) { false }
        allow(project.repository).to receive(:can_be_merged?).and_return(true)
      end

      it 'is marked as mergeable' do
        expect { subject.check_if_can_be_merged }.to change { subject.merge_status }.to('can_be_merged')
      end
    end

    context 'when broken' do
      before do
        allow(subject).to receive(:broken?) { true }
      end

      it 'becomes unmergeable' do
        expect { subject.check_if_can_be_merged }.to change { subject.merge_status }.to('cannot_be_merged')
      end
    end

    context 'when it has conflicts' do
      before do
        allow(subject).to receive(:broken?) { false }
        allow(project.repository).to receive(:can_be_merged?).and_return(false)
      end

      it 'becomes unmergeable' do
        expect { subject.check_if_can_be_merged }.to change { subject.merge_status }.to('cannot_be_merged')
      end
    end
  end

  describe '#mergeable?' do
    let(:project) { create(:project) }

    subject { create(:merge_request, source_project: project) }

    it 'returns false if #mergeable_state? is false' do
      expect(subject).to receive(:mergeable_state?) { false }

      expect(subject.mergeable?).to be_falsey
    end

    it 'return true if #mergeable_state? is true and the MR #can_be_merged? is true' do
      allow(subject).to receive(:mergeable_state?) { true }
      expect(subject).to receive(:check_if_can_be_merged)
      expect(subject).to receive(:can_be_merged?) { true }

      expect(subject.mergeable?).to be_truthy
    end
  end

  describe '#mergeable_state?' do
    let(:project) { create(:project, :repository) }

    subject { create(:merge_request, source_project: project) }

    it 'checks if merge request can be merged' do
      allow(subject).to receive(:mergeable_ci_state?) { true }
      expect(subject).to receive(:check_if_can_be_merged)

      subject.mergeable?
    end

    context 'when not open' do
      before do
        subject.close
      end

      it 'returns false' do
        expect(subject.mergeable_state?).to be_falsey
      end
    end

    context 'when working in progress' do
      before do
        subject.title = 'WIP MR'
      end

      it 'returns false' do
        expect(subject.mergeable_state?).to be_falsey
      end
    end

    context 'when broken' do
      before do
        allow(subject).to receive(:broken?) { true }
      end

      it 'returns false' do
        expect(subject.mergeable_state?).to be_falsey
      end
    end

    context 'when failed' do
      context 'when #mergeable_ci_state? is false' do
        before do
          allow(subject).to receive(:mergeable_ci_state?) { false }
        end

        it 'returns false' do
          expect(subject.mergeable_state?).to be_falsey
        end
      end

      context 'when #mergeable_discussions_state? is false' do
        before do
          allow(subject).to receive(:mergeable_discussions_state?) { false }
        end

        it 'returns false' do
          expect(subject.mergeable_state?).to be_falsey
        end

        it 'returns true when skipping discussions check' do
          expect(subject.mergeable_state?(skip_discussions_check: true)).to be(true)
        end
      end
    end
  end

  describe '#mergeable_ci_state?' do
    let(:project) { create(:project, only_allow_merge_if_pipeline_succeeds: true) }
    let(:pipeline) { create(:ci_empty_pipeline) }

    subject { build(:merge_request, target_project: project) }

    context 'when it is only allowed to merge when build is green' do
      context 'and a failed pipeline is associated' do
        before do
          pipeline.update(status: 'failed', sha: subject.diff_head_sha)
          allow(subject).to receive(:head_pipeline) { pipeline }
        end

        it { expect(subject.mergeable_ci_state?).to be_falsey }
      end

      context 'and a successful pipeline is associated' do
        before do
          pipeline.update(status: 'success', sha: subject.diff_head_sha)
          allow(subject).to receive(:head_pipeline) { pipeline }
        end

        it { expect(subject.mergeable_ci_state?).to be_truthy }
      end

      context 'and a skipped pipeline is associated' do
        before do
          pipeline.update(status: 'skipped', sha: subject.diff_head_sha)
          allow(subject).to receive(:head_pipeline) { pipeline }
        end

        it { expect(subject.mergeable_ci_state?).to be_truthy }
      end

      context 'when no pipeline is associated' do
        before do
          allow(subject).to receive(:head_pipeline) { nil }
        end

        it { expect(subject.mergeable_ci_state?).to be_truthy }
      end
    end

    context 'when merges are not restricted to green builds' do
      subject { build(:merge_request, target_project: build(:project, only_allow_merge_if_pipeline_succeeds: false)) }

      context 'and a failed pipeline is associated' do
        before do
          pipeline.statuses << create(:commit_status, status: 'failed', project: project)
          allow(subject).to receive(:head_pipeline) { pipeline }
        end

        it { expect(subject.mergeable_ci_state?).to be_truthy }
      end

      context 'when no pipeline is associated' do
        before do
          allow(subject).to receive(:head_pipeline) { nil }
        end

        it { expect(subject.mergeable_ci_state?).to be_truthy }
      end
    end

    context 'when project does not have pipelines enabled' do
      subject { build(:merge_request, target_project: build(:project, :builds_disabled)) }

      context 'when merges are restricted to green builds' do
        before do
          subject.target_project.only_allow_merge_if_pipeline_succeeds = true
        end

        it { expect(subject.mergeable_ci_state?).to be_truthy }
      end

      context 'when merges are not restricted to green builds' do
        before do
          subject.target_project.only_allow_merge_if_pipeline_succeeds = false
        end

        it { expect(subject.mergeable_ci_state?).to be_truthy }
      end
    end
  end

  describe '#mergeable_discussions_state?' do
    let(:merge_request) { create(:merge_request_with_diff_notes, source_project: project) }

    context 'when project.only_allow_merge_if_all_discussions_are_resolved == true' do
      let(:project) { create(:project, :repository, only_allow_merge_if_all_discussions_are_resolved: true) }

      context 'with all discussions resolved' do
        before do
          merge_request.discussions.each { |d| d.resolve!(merge_request.author) }
        end

        it 'returns true' do
          expect(merge_request.mergeable_discussions_state?).to be_truthy
        end
      end

      context 'with unresolved discussions' do
        before do
          merge_request.discussions.each(&:unresolve!)
        end

        it 'returns false' do
          expect(merge_request.mergeable_discussions_state?).to be_falsey
        end
      end

      context 'with no discussions' do
        before do
          merge_request.notes.destroy_all
        end

        it 'returns true' do
          expect(merge_request.mergeable_discussions_state?).to be_truthy
        end
      end
    end

    context 'when project.only_allow_merge_if_all_discussions_are_resolved == false' do
      let(:project) { create(:project, :repository, only_allow_merge_if_all_discussions_are_resolved: false) }

      context 'with unresolved discussions' do
        before do
          merge_request.discussions.each(&:unresolve!)
        end

        it 'returns true' do
          expect(merge_request.mergeable_discussions_state?).to be_truthy
        end
      end
    end
  end

  describe "#environments_for" do
    let(:project)       { create(:project, :repository) }
    let(:user)          { project.creator }
    let(:merge_request) { create(:merge_request, source_project: project) }

    before do
      merge_request.source_project.add_master(user)
      merge_request.target_project.add_master(user)
    end

    context 'with multiple environments' do
      let(:environments) { create_list(:environment, 3, project: project) }

      before do
        create(:deployment, environment: environments.first, ref: 'master', sha: project.commit('master').id)
        create(:deployment, environment: environments.second, ref: 'feature', sha: project.commit('feature').id)
      end

      it 'selects deployed environments' do
        expect(merge_request.environments_for(user)).to contain_exactly(environments.first)
      end
    end

    context 'with environments on source project' do
      let(:source_project) { fork_project(project, nil, repository: true) }

      let(:merge_request) do
        create(:merge_request,
               source_project: source_project, source_branch: 'feature',
               target_project: project)
      end

      let(:source_environment) { create(:environment, project: source_project) }

      before do
        create(:deployment, environment: source_environment, ref: 'feature', sha: merge_request.diff_head_sha)
      end

      it 'selects deployed environments' do
        expect(merge_request.environments_for(user)).to contain_exactly(source_environment)
      end

      context 'with environments on target project' do
        let(:target_environment) { create(:environment, project: project) }

        before do
          create(:deployment, environment: target_environment, tag: true, sha: merge_request.diff_head_sha)
        end

        it 'selects deployed environments' do
          expect(merge_request.environments_for(user)).to contain_exactly(source_environment, target_environment)
        end
      end
    end

    context 'without a diff_head_commit' do
      before do
        expect(merge_request).to receive(:diff_head_commit).and_return(nil)
      end

      it 'returns an empty array' do
        expect(merge_request.environments_for(user)).to be_empty
      end
    end
  end

  describe "#reload_diff" do
    let(:discussion) { create(:diff_note_on_merge_request, project: subject.project, noteable: subject).to_discussion }
    let(:commit) { subject.project.commit(sample_commit.id) }

    it "does not change existing merge request diff" do
      expect(subject.merge_request_diff).not_to receive(:save_git_content)
      subject.reload_diff
    end

    it "creates new merge request diff" do
      expect { subject.reload_diff }.to change { subject.merge_request_diffs.count }.by(1)
    end

    it "executes diff cache service" do
      expect_any_instance_of(MergeRequests::MergeRequestDiffCacheService).to receive(:execute).with(subject, an_instance_of(MergeRequestDiff))

      subject.reload_diff
    end

    it "calls update_diff_discussion_positions" do
      expect(subject).to receive(:update_diff_discussion_positions)

      subject.reload_diff
    end

    context 'when using the after_update hook to update' do
      context 'when the branches are updated' do
        it 'uses the new heads to generate the diff' do
          expect { subject.update!(source_branch: subject.target_branch, target_branch: subject.source_branch) }
            .to change { subject.merge_request_diff.start_commit_sha }
            .and change { subject.merge_request_diff.head_commit_sha }
        end
      end
    end
  end

  describe '#update_diff_discussion_positions' do
    let(:discussion) { create(:diff_note_on_merge_request, project: subject.project, noteable: subject).to_discussion }
    let(:commit) { subject.project.commit(sample_commit.id) }
    let(:old_diff_refs) { subject.diff_refs }

    before do
      # Update merge_request_diff so that #diff_refs will return commit.diff_refs
      allow(subject).to receive(:create_merge_request_diff) do
        subject.merge_request_diffs.create(
          base_commit_sha: commit.parent_id,
          start_commit_sha: commit.parent_id,
          head_commit_sha: commit.sha
        )

        subject.merge_request_diff(true)
      end
    end

    it "updates diff discussion positions" do
      expect(Discussions::UpdateDiffPositionService).to receive(:new).with(
        subject.project,
        subject.author,
        old_diff_refs: old_diff_refs,
        new_diff_refs: commit.diff_refs,
        paths: discussion.position.paths
      ).and_call_original

      expect_any_instance_of(Discussions::UpdateDiffPositionService).to receive(:execute).with(discussion).and_call_original
      expect_any_instance_of(DiffNote).to receive(:save).once

      subject.update_diff_discussion_positions(old_diff_refs: old_diff_refs,
                                               new_diff_refs: commit.diff_refs,
                                               current_user: subject.author)
    end

    context 'when resolve_outdated_diff_discussions is set' do
      before do
        discussion

        subject.project.update!(resolve_outdated_diff_discussions: true)
      end

      it 'calls MergeRequests::ResolvedDiscussionNotificationService' do
        expect_any_instance_of(MergeRequests::ResolvedDiscussionNotificationService)
          .to receive(:execute).with(subject)

        subject.update_diff_discussion_positions(old_diff_refs: old_diff_refs,
                                                 new_diff_refs: commit.diff_refs,
                                                 current_user: subject.author)
      end
    end
  end

  describe '#branch_merge_base_commit' do
    context 'source and target branch exist' do
      it { expect(subject.branch_merge_base_commit.sha).to eq('ae73cb07c9eeaf35924a10f713b364d32b2dd34f') }
      it { expect(subject.branch_merge_base_commit).to be_a(Commit) }
    end

    context 'when the target branch does not exist' do
      before do
        subject.project.repository.rm_branch(subject.author, subject.target_branch)
        subject.clear_memoized_shas
      end

      it 'returns nil' do
        expect(subject.branch_merge_base_commit).to be_nil
      end
    end
  end

  describe "#diff_refs" do
    context "with diffs" do
      subject { create(:merge_request, :with_diffs) }

      it "does not touch the repository" do
        subject # Instantiate the object

        expect_any_instance_of(Repository).not_to receive(:commit)

        subject.diff_refs
      end

      it "returns expected diff_refs" do
        expected_diff_refs = Gitlab::Diff::DiffRefs.new(
          base_sha:  subject.merge_request_diff.base_commit_sha,
          start_sha: subject.merge_request_diff.start_commit_sha,
          head_sha:  subject.merge_request_diff.head_commit_sha
        )

        expect(subject.diff_refs).to eq(expected_diff_refs)
      end
    end
  end

  describe "#source_project_missing?" do
    let(:project)      { create(:project) }
    let(:forked_project) { fork_project(project) }
    let(:user)         { create(:user) }
    let(:unlink_project) { Projects::UnlinkForkService.new(forked_project, user) }

    context "when the fork exists" do
      let(:merge_request) do
        create(:merge_request,
          source_project: forked_project,
          target_project: project)
      end

      it { expect(merge_request.source_project_missing?).to be_falsey }
    end

    context "when the source project is the same as the target project" do
      let(:merge_request) { create(:merge_request, source_project: project) }

      it { expect(merge_request.source_project_missing?).to be_falsey }
    end

    context "when the fork does not exist" do
      let!(:merge_request) do
        create(:merge_request,
          source_project: forked_project,
          target_project: project)
      end

      it "returns true" do
        unlink_project.execute
        merge_request.reload

        expect(merge_request.source_project_missing?).to be_truthy
      end
    end
  end

  describe '#merge_ongoing?' do
    it 'returns true when the merge request is locked' do
      merge_request = build_stubbed(:merge_request, state: :locked)

      expect(merge_request.merge_ongoing?).to be(true)
    end

    it 'returns true when merge_id, MR is not merged and it has no running job' do
      merge_request = build_stubbed(:merge_request, state: :open, merge_jid: 'foo')
      allow(Gitlab::SidekiqStatus).to receive(:running?).with('foo') { true }

      expect(merge_request.merge_ongoing?).to be(true)
    end

    it 'returns false when merge_jid is nil' do
      merge_request = build_stubbed(:merge_request, state: :open, merge_jid: nil)

      expect(merge_request.merge_ongoing?).to be(false)
    end

    it 'returns false if MR is merged' do
      merge_request = build_stubbed(:merge_request, state: :merged, merge_jid: 'foo')

      expect(merge_request.merge_ongoing?).to be(false)
    end

    it 'returns false if there is no merge job running' do
      merge_request = build_stubbed(:merge_request, state: :open, merge_jid: 'foo')
      allow(Gitlab::SidekiqStatus).to receive(:running?).with('foo') { false }

      expect(merge_request.merge_ongoing?).to be(false)
    end
  end

  describe "#closed_without_fork?" do
    let(:project)      { create(:project) }
    let(:forked_project) { fork_project(project) }
    let(:user)         { create(:user) }
    let(:unlink_project) { Projects::UnlinkForkService.new(forked_project, user) }

    context "when the merge request is closed" do
      let(:closed_merge_request) do
        create(:closed_merge_request,
          source_project: forked_project,
          target_project: project)
      end

      it "returns false if the fork exist" do
        expect(closed_merge_request.closed_without_fork?).to be_falsey
      end

      it "returns true if the fork does not exist" do
        unlink_project.execute
        closed_merge_request.reload

        expect(closed_merge_request.closed_without_fork?).to be_truthy
      end
    end

    context "when the merge request is open" do
      let(:open_merge_request) do
        create(:merge_request,
          source_project: forked_project,
          target_project: project)
      end

      it "returns false" do
        expect(open_merge_request.closed_without_fork?).to be_falsey
      end
    end
  end

  describe '#reopenable?' do
    context 'when the merge request is closed' do
      it 'returns true' do
        subject.close

        expect(subject.reopenable?).to be_truthy
      end

      context 'forked project' do
        let(:project)      { create(:project, :public) }
        let(:user)         { create(:user) }
        let(:forked_project) { fork_project(project, user) }

        let!(:merge_request) do
          create(:closed_merge_request,
            source_project: forked_project,
            target_project: project)
        end

        it 'returns false if unforked' do
          Projects::UnlinkForkService.new(forked_project, user).execute

          expect(merge_request.reload.reopenable?).to be_falsey
        end

        it 'returns false if the source project is deleted' do
          Projects::DestroyService.new(forked_project, user).execute

          expect(merge_request.reload.reopenable?).to be_falsey
        end

        it 'returns false if the merge request is merged' do
          merge_request.update_attributes(state: 'merged')

          expect(merge_request.reload.reopenable?).to be_falsey
        end
      end
    end

    context 'when the merge request is opened' do
      it 'returns false' do
        expect(subject.reopenable?).to be_falsey
      end
    end
  end

  describe '#mergeable_with_quick_action?' do
    def create_pipeline(status)
      pipeline = create(:ci_pipeline_with_one_job,
        project: project,
        ref:     merge_request.source_branch,
        sha:     merge_request.diff_head_sha,
        status:  status,
        head_pipeline_of: merge_request)

      pipeline
    end

    let(:project)       { create(:project, :public, :repository, only_allow_merge_if_pipeline_succeeds: true) }
    let(:developer)     { create(:user) }
    let(:user)          { create(:user) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:mr_sha)        { merge_request.diff_head_sha }

    before do
      project.add_developer(developer)
    end

    context 'when autocomplete_precheck is set to true' do
      it 'is mergeable by developer' do
        expect(merge_request.mergeable_with_quick_action?(developer, autocomplete_precheck: true)).to be_truthy
      end

      it 'is not mergeable by normal user' do
        expect(merge_request.mergeable_with_quick_action?(user, autocomplete_precheck: true)).to be_falsey
      end
    end

    context 'when autocomplete_precheck is set to false' do
      it 'is mergeable by developer' do
        expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_truthy
      end

      it 'is not mergeable by normal user' do
        expect(merge_request.mergeable_with_quick_action?(user, last_diff_sha: mr_sha)).to be_falsey
      end

      context 'closed MR'  do
        before do
          merge_request.update_attribute(:state, :closed)
        end

        it 'is not mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_falsey
        end
      end

      context 'MR with WIP'  do
        before do
          merge_request.update_attribute(:title, 'WIP: some MR')
        end

        it 'is not mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_falsey
        end
      end

      context 'sha differs from the MR diff_head_sha'  do
        it 'is not mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: 'some other sha')).to be_falsey
        end
      end

      context 'sha is not provided'  do
        it 'is not mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer)).to be_falsey
        end
      end

      context 'with pipeline ok'  do
        before do
          create_pipeline(:success)
        end

        it 'is mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_truthy
        end
      end

      context 'with failing pipeline'  do
        before do
          create_pipeline(:failed)
        end

        it 'is not mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_falsey
        end
      end

      context 'with running pipeline'  do
        before do
          create_pipeline(:running)
        end

        it 'is mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_truthy
        end
      end
    end
  end

  describe '#has_commits?' do
    before do
      allow(subject.merge_request_diff).to receive(:commits_count)
        .and_return(2)
    end

    it 'returns true when merge request diff has commits' do
      expect(subject.has_commits?).to be_truthy
    end
  end

  describe '#has_no_commits?' do
    before do
      allow(subject.merge_request_diff).to receive(:commits_count)
        .and_return(0)
    end

    it 'returns true when merge request diff has 0 commits' do
      expect(subject.has_no_commits?).to be_truthy
    end
  end

  describe '#merge_request_diff_for' do
    subject { create(:merge_request, importing: true) }
    let!(:merge_request_diff1) { subject.merge_request_diffs.create(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
    let!(:merge_request_diff2) { subject.merge_request_diffs.create(head_commit_sha: nil) }
    let!(:merge_request_diff3) { subject.merge_request_diffs.create(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }

    context 'with diff refs' do
      it 'returns the diffs' do
        expect(subject.merge_request_diff_for(merge_request_diff1.diff_refs)).to eq(merge_request_diff1)
      end
    end

    context 'with a commit SHA' do
      it 'returns the diffs' do
        expect(subject.merge_request_diff_for(merge_request_diff3.head_commit_sha)).to eq(merge_request_diff3)
      end
    end

    it 'runs a single query on the initial call, and none afterwards' do
      expect { subject.merge_request_diff_for(merge_request_diff1.diff_refs) }
        .not_to exceed_query_limit(1)

      expect { subject.merge_request_diff_for(merge_request_diff2.diff_refs) }
        .not_to exceed_query_limit(0)

      expect { subject.merge_request_diff_for(merge_request_diff3.head_commit_sha) }
        .not_to exceed_query_limit(0)
    end
  end

  describe '#version_params_for' do
    subject { create(:merge_request, importing: true) }
    let(:project) { subject.project }
    let!(:merge_request_diff1) { subject.merge_request_diffs.create(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
    let!(:merge_request_diff2) { subject.merge_request_diffs.create(head_commit_sha: nil) }
    let!(:merge_request_diff3) { subject.merge_request_diffs.create(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }

    context 'when the diff refs are for an older merge request version' do
      let(:diff_refs) { merge_request_diff1.diff_refs }

      it 'returns the diff ID for the version to show' do
        expect(subject.version_params_for(diff_refs)).to eq(diff_id: merge_request_diff1.id)
      end
    end

    context 'when the diff refs are for a comparison between merge request versions' do
      let(:diff_refs) { merge_request_diff3.compare_with(merge_request_diff1.head_commit_sha).diff_refs }

      it 'returns the diff ID and start sha of the versions to compare' do
        expect(subject.version_params_for(diff_refs)).to eq(diff_id: merge_request_diff3.id, start_sha: merge_request_diff1.head_commit_sha)
      end
    end

    context 'when the diff refs are not for a merge request version' do
      let(:diff_refs) { project.commit(sample_commit.id).diff_refs }

      it 'returns nil' do
        expect(subject.version_params_for(diff_refs)).to be_nil
      end
    end
  end

  describe '#fetch_ref!' do
    it 'fetches the ref correctly' do
      expect { subject.target_project.repository.delete_refs(subject.ref_path) }.not_to raise_error

      subject.fetch_ref!
      expect(subject.target_project.repository.ref_exists?(subject.ref_path)).to be_truthy
    end
  end

  describe 'removing a merge request' do
    it 'refreshes the number of open merge requests of the target project' do
      project = subject.target_project

      expect { subject.destroy }
        .to change { project.open_merge_requests_count }.from(1).to(0)
    end
  end

  it_behaves_like 'throttled touch' do
    subject { create(:merge_request, updated_at: 1.hour.ago) }
  end

  context 'state machine transitions' do
    describe '#unlock_mr' do
      subject { create(:merge_request, state: 'locked', merge_jid: 123) }

      it 'updates merge request head pipeline and sets merge_jid to nil' do
        pipeline = create(:ci_empty_pipeline, project: subject.project, ref: subject.source_branch, sha: subject.source_branch_sha)

        subject.unlock_mr

        subject.reload
        expect(subject.head_pipeline).to eq(pipeline)
        expect(subject.merge_jid).to be_nil
      end
    end
  end

  describe '#should_be_rebased?' do
    let(:project) { create(:project, :repository) }

    it 'returns false for the same source and target branches' do
      merge_request = create(:merge_request, source_project: project, target_project: project)

      expect(merge_request.should_be_rebased?).to be_falsey
    end
  end

  describe '#rebase_in_progress?' do
    shared_examples 'checking whether a rebase is in progress' do
      let(:repo_path) { subject.source_project.repository.path }
      let(:rebase_path) { File.join(repo_path, "gitlab-worktree", "rebase-#{subject.id}") }

      before do
        system(*%W(#{Gitlab.config.git.bin_path} -C #{repo_path} worktree add --detach #{rebase_path} master))
      end

      it 'returns true when there is a current rebase directory' do
        expect(subject.rebase_in_progress?).to be_truthy
      end

      it 'returns false when there is no rebase directory' do
        FileUtils.rm_rf(rebase_path)

        expect(subject.rebase_in_progress?).to be_falsey
      end

      it 'returns false when the rebase directory has expired' do
        time = 20.minutes.ago.to_time
        File.utime(time, time, rebase_path)

        expect(subject.rebase_in_progress?).to be_falsey
      end

      it 'returns false when the source project has been removed' do
        allow(subject).to receive(:source_project).and_return(nil)

        expect(subject.rebase_in_progress?).to be_falsey
      end
    end

    context 'when Gitaly rebase_in_progress is enabled' do
      it_behaves_like 'checking whether a rebase is in progress'
    end

    context 'when Gitaly rebase_in_progress is enabled', :disable_gitaly do
      it_behaves_like 'checking whether a rebase is in progress'
    end
  end

  describe '#allow_maintainer_to_push' do
    let(:merge_request) do
      build(:merge_request, source_branch: 'fixes', allow_maintainer_to_push: true)
    end

    it 'is false when pushing by a maintainer is not possible' do
      expect(merge_request).to receive(:maintainer_push_possible?) { false }

      expect(merge_request.allow_maintainer_to_push).to be_falsy
    end

    it 'is true when pushing by a maintainer is possible' do
      expect(merge_request).to receive(:maintainer_push_possible?) { true }

      expect(merge_request.allow_maintainer_to_push).to be_truthy
    end
  end

  describe '#maintainer_push_possible?' do
    let(:merge_request) do
      build(:merge_request, source_branch: 'fixes')
    end

    before do
      allow(ProtectedBranch).to receive(:protected?) { false }
    end

    it 'does not allow maintainer to push if the source project is the same as the target' do
      merge_request.target_project = merge_request.source_project = create(:project, :public)

      expect(merge_request.maintainer_push_possible?).to be_falsy
    end

    it 'allows maintainer to push when both source and target are public' do
      merge_request.target_project = build(:project, :public)
      merge_request.source_project = build(:project, :public)

      expect(merge_request.maintainer_push_possible?).to be_truthy
    end

    it 'is not available for protected branches' do
      merge_request.target_project = build(:project, :public)
      merge_request.source_project = build(:project, :public)

      expect(ProtectedBranch).to receive(:protected?)
                                   .with(merge_request.source_project, 'fixes')
                                   .and_return(true)

      expect(merge_request.maintainer_push_possible?).to be_falsy
    end
  end

  describe '#can_allow_maintainer_to_push?' do
    let(:target_project) { create(:project, :public) }
    let(:source_project) { fork_project(target_project) }
    let(:merge_request) do
      create(:merge_request,
             source_project: source_project,
             source_branch: 'fixes',
             target_project: target_project)
    end
    let(:user) { create(:user) }

    before do
      allow(merge_request).to receive(:maintainer_push_possible?) { true }
    end

    it 'is false if the user does not have push access to the source project' do
      expect(merge_request.can_allow_maintainer_to_push?(user)).to be_falsy
    end

    it 'is true when the user has push access to the source project' do
      source_project.add_developer(user)

      expect(merge_request.can_allow_maintainer_to_push?(user)).to be_truthy
    end
  end
end
