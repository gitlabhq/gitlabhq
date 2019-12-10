# frozen_string_literal: true

require 'spec_helper'

describe MergeRequest do
  include RepoHelpers
  include ProjectForksHelper
  include ReactiveCachingHelpers

  using RSpec::Parameterized::TableSyntax

  subject { create(:merge_request) }

  describe 'associations' do
    it { is_expected.to belong_to(:target_project).class_name('Project') }
    it { is_expected.to belong_to(:source_project).class_name('Project') }
    it { is_expected.to belong_to(:merge_user).class_name("User") }
    it { is_expected.to have_many(:assignees).through(:merge_request_assignees) }
    it { is_expected.to have_many(:merge_request_diffs) }
    it { is_expected.to have_many(:user_mentions).class_name("MergeRequestUserMention") }

    context 'for forks' do
      let!(:project) { create(:project) }
      let!(:fork) { fork_project(project) }
      let!(:merge_request) { create(:merge_request, target_project: project, source_project: fork) }

      it 'does not load another project due to inverse relationship' do
        expect(project.merge_requests.first.target_project.object_id).to eq(project.object_id)
      end

      it 'finds the associated merge request' do
        expect(project.merge_requests.find(merge_request.id)).to eq(merge_request)
      end
    end
  end

  describe '.from_and_to_forks' do
    it 'returns only MRs from and to forks (with no internal MRs)' do
      project = create(:project)
      fork = fork_project(project)
      fork_2 = fork_project(project)
      mr_from_fork = create(:merge_request, source_project: fork, target_project: project)
      mr_to_fork = create(:merge_request, source_project: project, target_project: fork)

      create(:merge_request, source_project: fork, target_project: fork_2)
      create(:merge_request, source_project: project, target_project: project)

      expect(described_class.from_and_to_forks(project)).to contain_exactly(mr_from_fork, mr_to_fork)
    end
  end

  describe 'locking' do
    using RSpec::Parameterized::TableSyntax

    where(:lock_version) do
      [
        [0],
        ["0"]
      ]
    end

    with_them do
      it 'works when a merge request has a NULL lock_version' do
        merge_request = create(:merge_request)

        described_class.where(id: merge_request.id).update_all('lock_version = NULL')

        merge_request.update!(lock_version: lock_version, title: 'locking test')

        expect(merge_request.reload.title).to eq('locking test')
      end
    end
  end

  describe '#squash_in_progress?' do
    let(:repo_path) do
      Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        subject.source_project.repository.path
      end
    end
    let(:squash_path) { File.join(repo_path, "gitlab-worktree", "squash-#{subject.id}") }

    before do
      system(*%W(#{Gitlab.config.git.bin_path} -C #{repo_path} worktree add --detach #{squash_path} master))
    end

    it 'returns true when there is a current squash directory' do
      expect(subject.squash_in_progress?).to be_truthy
    end

    it 'returns false when there is no squash directory' do
      FileUtils.rm_rf(squash_path)

      expect(subject.squash_in_progress?).to be_falsey
    end

    it 'returns false when the squash directory has expired' do
      time = 20.minutes.ago.to_time
      File.utime(time, time, squash_path)

      expect(subject.squash_in_progress?).to be_falsey
    end

    it 'returns false when the source project has been removed' do
      allow(subject).to receive(:source_project).and_return(nil)

      expect(subject.squash_in_progress?).to be_falsey
    end
  end

  describe '#squash?' do
    let(:merge_request) { build(:merge_request, squash: squash) }
    subject { merge_request.squash? }

    context 'disabled in database' do
      let(:squash) { false }

      it { is_expected.to be_falsy }
    end

    context 'enabled in database' do
      let(:squash) { true }

      it { is_expected.to be_truthy }
    end
  end

  describe '#default_squash_commit_message' do
    let(:project) { subject.project }
    let(:is_multiline) { -> (c) { c.description.present? } }
    let(:multiline_commits) { subject.commits.select(&is_multiline) }
    let(:singleline_commits) { subject.commits.reject(&is_multiline) }

    context 'when the total number of commits is safe' do
      it 'returns the oldest multiline commit message' do
        expect(subject.default_squash_commit_message).to eq(multiline_commits.last.message)
      end
    end

    context 'when the total number of commits is big' do
      let(:safe_number) { 20 }

      before do
        stub_const('MergeRequestDiff::COMMITS_SAFE_SIZE', safe_number)
      end

      it 'returns the oldest multiline commit message from safe number of commits' do
        expect(subject.default_squash_commit_message).to eq(
          "remove emtpy file.(beacase git ignore empty file)\nadd whitespace test file.\n"
        )
      end
    end

    it 'returns the merge request title if there are no multiline commits' do
      expect(subject).to receive(:commits).and_return(
        CommitCollection.new(project, singleline_commits)
      )

      expect(subject.default_squash_commit_message).to eq(subject.title)
    end

    it 'does not return commit messages from multiline merge commits' do
      collection = CommitCollection.new(project, multiline_commits).enrich!

      expect(collection.commits).to all( receive(:merge_commit?).and_return(true) )
      expect(subject).to receive(:commits).and_return(collection)
      expect(subject.default_squash_commit_message).to eq(subject.title)
    end
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Issuable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(Taskable) }

    it_behaves_like 'AtomicInternalId' do
      let(:internal_id_attribute) { :iid }
      let(:instance) { build(:merge_request) }
      let(:scope) { :target_project }
      let(:scope_attrs) { { project: instance.target_project } }
      let(:usage) { :merge_requests }
    end
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

    context 'for branch' do
      before do
        stub_feature_flags(stricter_mr_branch_name: false)
      end

      using RSpec::Parameterized::TableSyntax

      where(:branch_name, :valid) do
        'foo' | true
        'foo:bar' | false
        '+foo:bar' | false
        'foo bar' | false
        '-foo' | false
        'HEAD' | true
        'refs/heads/master' | true
      end

      with_them do
        it "validates source_branch" do
          subject = build(:merge_request, source_branch: branch_name, target_branch: 'master')
          subject.valid?

          expect(subject.errors.added?(:source_branch)).to eq(!valid)
        end

        it "validates target_branch" do
          subject = build(:merge_request, source_branch: 'master', target_branch: branch_name)
          subject.valid?

          expect(subject.errors.added?(:target_branch)).to eq(!valid)
        end
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

  describe '.by_merge_commit_sha' do
    it 'returns merge requests that match the given merge commit' do
      mr = create(:merge_request, :merged, merge_commit_sha: '123abc')

      create(:merge_request, :merged, merge_commit_sha: '123def')

      expect(described_class.by_merge_commit_sha('123abc')).to eq([mr])
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

  describe '.recent_target_branches' do
    let(:project) { create(:project) }
    let!(:merge_request1) { create(:merge_request, :opened, source_project: project, target_branch: 'feature') }
    let!(:merge_request2) { create(:merge_request, :closed, source_project: project, target_branch: 'merge-test') }
    let!(:merge_request3) { create(:merge_request, :opened, source_project: project, target_branch: 'fix') }
    let!(:merge_request4) { create(:merge_request, :closed, source_project: project, target_branch: 'feature') }

    before do
      merge_request1.update_columns(updated_at: 1.day.since)
      merge_request2.update_columns(updated_at: 2.days.since)
      merge_request3.update_columns(updated_at: 3.days.since)
      merge_request4.update_columns(updated_at: 4.days.since)
    end

    it 'returns target branches sort by updated at desc' do
      expect(described_class.recent_target_branches).to match_array(['feature', 'merge-test', 'fix'])
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
      allow(subject).to receive(:assignees).and_return([])

      expect(subject.card_attributes)
        .to eq({ 'Author' => 'Robert', 'Assignee' => "" })
    end

    it 'includes the assignees name' do
      allow(subject).to receive(:author).and_return(double(name: 'Robert'))
      allow(subject).to receive(:assignees).and_return([double(name: 'Douwe'), double(name: 'Robert')])

      expect(subject.card_attributes)
        .to eq({ 'Author' => 'Robert', 'Assignee' => 'Douwe and Robert' })
    end
  end

  describe '#assignee_or_author?' do
    let(:user) { create(:user) }

    it 'returns true for a user that is assigned to a merge request' do
      subject.assignees = [user]

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

  describe '#visible_closing_issues_for' do
    let(:guest) { create(:user) }
    let(:developer) { create(:user) }
    let(:issue_1) { create(:issue, project: subject.source_project) }
    let(:issue_2) { create(:issue, project: subject.source_project) }
    let(:confidential_issue) { create(:issue, :confidential, project: subject.source_project) }

    before do
      subject.project.add_developer(subject.author)
      subject.target_branch = subject.project.default_branch
      commit = double('commit1', safe_message: "Fixes #{issue_1.to_reference} #{issue_2.to_reference} #{confidential_issue.to_reference}")
      allow(subject).to receive(:commits).and_return([commit])
    end

    it 'shows only allowed issues to guest' do
      subject.project.add_guest(guest)

      subject.cache_merge_request_closes_issues!

      expect(subject.visible_closing_issues_for(guest)).to match_array([issue_1, issue_2])
    end

    it 'shows only allowed issues to developer' do
      subject.project.add_developer(developer)

      subject.cache_merge_request_closes_issues!

      expect(subject.visible_closing_issues_for(developer)).to match_array([issue_1, confidential_issue, issue_2])
    end

    context 'when external issue tracker is enabled' do
      before do
        subject.project.has_external_issue_tracker = true
        subject.project.save!
      end

      it 'calls non #closes_issues to retrieve data' do
        expect(subject).to receive(:closes_issues)
        expect(subject).not_to receive(:cached_closes_issues)

        subject.visible_closing_issues_for
      end
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

    it 'does not cache closed issues when merge request is closed' do
      issue  = create :issue, project: subject.project
      commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")

      allow(subject).to receive(:commits).and_return([commit])
      allow(subject).to receive(:state_id).and_return(described_class.available_states[:closed])

      expect { subject.cache_merge_request_closes_issues!(subject.author) }.not_to change(subject.merge_requests_closing_issues, :count)
    end

    it 'does not cache closed issues when merge request is merged' do
      issue  = create :issue, project: subject.project
      commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
      allow(subject).to receive(:commits).and_return([commit])
      allow(subject).to receive(:state_id).and_return(described_class.available_states[:merged])

      expect { subject.cache_merge_request_closes_issues!(subject.author) }.not_to change(subject.merge_requests_closing_issues, :count)
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

        expect(merge_request.merge_request_diff).to receive(:raw_diffs).with(hash_including(options)).and_call_original

        merge_request.diffs(options).diff_files
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

  describe '#note_positions_for_paths' do
    let(:merge_request) { create(:merge_request, :with_diffs) }
    let(:project) { merge_request.project }
    let!(:diff_note) do
      create(:diff_note_on_merge_request, project: project, noteable: merge_request)
    end

    let(:file_paths) { merge_request.diffs.diff_files.map(&:file_path) }

    subject do
      merge_request.note_positions_for_paths(file_paths)
    end

    it 'returns a Gitlab::Diff::PositionCollection' do
      expect(subject).to be_a(Gitlab::Diff::PositionCollection)
    end

    context 'within all diff files' do
      it 'returns correct positions' do
        expect(subject).to match_array([diff_note.position])
      end
    end

    context 'within specific diff file' do
      let(:file_paths) { [diff_note.position.file_path] }

      it 'returns correct positions' do
        expect(subject).to match_array([diff_note.position])
      end
    end

    context 'within no diff files' do
      let(:file_paths) { [] }

      it 'returns no positions' do
        expect(subject.to_a).to be_empty
      end
    end
  end

  describe '#discussions_diffs' do
    let(:merge_request) { create(:merge_request) }

    shared_examples 'discussions diffs collection' do
      it 'initializes Gitlab::DiscussionsDiff::FileCollection with correct data' do
        note_diff_file = diff_note.note_diff_file

        expect(Gitlab::DiscussionsDiff::FileCollection)
          .to receive(:new)
          .with([note_diff_file])
          .and_call_original

        result = merge_request.discussions_diffs

        expect(result).to be_a(Gitlab::DiscussionsDiff::FileCollection)
      end

      it 'eager loads relations' do
        result = merge_request.discussions_diffs

        recorder = ActiveRecord::QueryRecorder.new do
          result.first.diff_note
          result.first.diff_note.project
        end

        expect(recorder.count).to be_zero
      end
    end

    context 'with commit diff note' do
      let(:other_merge_request) { create(:merge_request) }

      let!(:diff_note) do
        create(:diff_note_on_commit, project: merge_request.project)
      end

      let!(:other_mr_diff_note) do
        create(:diff_note_on_commit, project: other_merge_request.project)
      end

      it_behaves_like 'discussions diffs collection'
    end

    context 'with merge request diff note' do
      let!(:diff_note) do
        create(:diff_note_on_merge_request, project: merge_request.project, noteable: merge_request)
      end

      it_behaves_like 'discussions diffs collection'
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

  describe '#modified_paths' do
    let(:paths) { double(:paths) }
    subject(:merge_request) { build(:merge_request) }

    before do
      expect(diff).to receive(:modified_paths).and_return(paths)
    end

    context 'when past_merge_request_diff is specified' do
      let(:another_diff) { double(:merge_request_diff) }
      let(:diff) { another_diff }

      it 'returns affected file paths from specified past_merge_request_diff' do
        expect(merge_request.modified_paths(past_merge_request_diff: another_diff)).to eq(paths)
      end
    end

    context 'when compare is present' do
      let(:compare) { double(:compare) }
      let(:diff) { compare }

      it 'returns affected file paths from compare' do
        merge_request.compare = compare

        expect(merge_request.modified_paths).to eq(paths)
      end
    end

    context 'when no arguments provided' do
      let(:diff) { merge_request.merge_request_diff }
      subject(:merge_request) { create(:merge_request, source_branch: 'feature', target_branch: 'master') }

      it 'returns affected file paths for merge_request_diff' do
        expect(merge_request.modified_paths).to eq(paths)
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

    it "excludes system notes for commits" do
      system_note = create(:note_on_commit, :system, commit_id: merge_request.commits.first.id,
                                                     project: merge_request.project)

      expect(merge_request.related_notes.count).to eq(2)
      expect(merge_request.related_notes).not_to include(system_note)
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
      subject.cache_merge_request_closes_issues!

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
        subject.cache_merge_request_closes_issues!

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
    ['WIP ', 'WIP:', 'WIP: ', '[WIP]', '[WIP] ', '[WIP] WIP [WIP] WIP: WIP '].each do |wip_prefix|
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
      subject.source_project.add_maintainer(user)
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

  describe '#default_merge_commit_message' do
    it 'includes merge information as the title' do
      request = build(:merge_request, source_branch: 'source', target_branch: 'target')

      expect(request.default_merge_commit_message)
        .to match("Merge branch 'source' into 'target'\n\n")
    end

    it 'includes its title in the body' do
      request = build(:merge_request, title: 'Remove all technical debt')

      expect(request.default_merge_commit_message)
        .to match("Remove all technical debt\n\n")
    end

    it 'includes its closed issues in the body' do
      issue = create(:issue, project: subject.project)

      subject.project.add_developer(subject.author)
      subject.description = "This issue Closes #{issue.to_reference}"
      allow(subject.project).to receive(:default_branch).and_return(subject.target_branch)
      subject.cache_merge_request_closes_issues!

      expect(subject.default_merge_commit_message)
        .to match("Closes #{issue.to_reference}")
    end

    it 'includes its reference in the body' do
      request = build_stubbed(:merge_request)

      expect(request.default_merge_commit_message)
        .to match("See merge request #{request.to_reference(full: true)}")
    end

    it 'excludes multiple linebreak runs when description is blank' do
      request = build(:merge_request, title: 'Title', description: nil)

      expect(request.default_merge_commit_message).not_to match("Title\n\n\n\n")
    end

    it 'includes its description in the body' do
      request = build(:merge_request, description: 'By removing all code')

      expect(request.default_merge_commit_message(include_description: true))
        .to match("By removing all code\n\n")
    end

    it 'does not includes its description in the body' do
      request = build(:merge_request, description: 'By removing all code')

      expect(request.default_merge_commit_message)
        .not_to match("By removing all code\n\n")
    end
  end

  describe "#auto_merge_strategy" do
    subject { merge_request.auto_merge_strategy }

    let(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }

    it { is_expected.to eq('merge_when_pipeline_succeeds') }

    context 'when auto merge is disabled' do
      let(:merge_request) { create(:merge_request) }

      it { is_expected.to be_nil }
    end
  end

  describe '#committers' do
    it 'returns all the committers of every commit in the merge request' do
      users = subject.commits.without_merge_commits.map(&:committer_email).uniq.map do |email|
        create(:user, email: email)
      end

      expect(subject.committers).to match_array(users)
    end

    it 'returns an empty array if no committer is associated with a user' do
      expect(subject.committers).to be_empty
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
    let(:project) { create(:project, :repository) }
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

      it 'counts commits that are on target branch but not on source branch', :sidekiq_might_not_need_inline do
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
    context 'persisted merge request' do
      context 'with a limit' do
        it 'returns a limited number of commit shas' do
          expect(subject.commit_shas(limit: 2)).to eq(%w[
            b83d6e391c22777fca1ed3012fce84f633d7fed0 498214de67004b1da3d820901307bed2a68a8ef6
          ])
        end
      end

      context 'without a limit' do
        it 'returns all commit shas of the merge request diff' do
          expect(subject.commit_shas.size).to eq(29)
        end
      end
    end

    context 'new merge request' do
      subject { build(:merge_request) }

      context 'compare commits' do
        before do
          subject.compare_commits = [
            double(sha: 'sha1'), double(sha: 'sha2')
          ]
        end

        context 'without a limit' do
          it 'returns all shas of compare commits' do
            expect(subject.commit_shas).to eq(%w[sha2 sha1])
          end
        end

        context 'with a limit' do
          it 'returns a limited number of shas' do
            expect(subject.commit_shas(limit: 1)).to eq(['sha2'])
          end
        end
      end

      it 'returns diff_head_sha as an array' do
        expect(subject.commit_shas).to eq([subject.diff_head_sha])
        expect(subject.commit_shas(limit: 2)).to eq([subject.diff_head_sha])
      end
    end
  end

  context 'head pipeline' do
    let(:diff_head_sha) { Digest::SHA1.hexdigest(SecureRandom.hex) }

    before do
      allow(subject).to receive(:diff_head_sha).and_return(diff_head_sha)
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
        pipeline = create(:ci_empty_pipeline, sha: diff_head_sha)
        subject.update_attribute(:head_pipeline_id, pipeline.id)

        expect(subject.actual_head_pipeline).to eq(subject.head_pipeline)
        expect(subject.actual_head_pipeline).to eq(pipeline)
      end

      it 'returns the pipeline for MR with recent merge request pipeline' do
        pipeline = create(:ci_empty_pipeline, sha: 'merge-sha', source_sha: diff_head_sha)
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

  describe '#merge_pipeline' do
    it 'returns nil when not merged' do
      expect(subject.merge_pipeline).to be_nil
    end

    context 'when the MR is merged' do
      let(:sha)      { subject.target_project.commit.id }
      let(:pipeline) { create(:ci_empty_pipeline, sha: sha, ref: subject.target_branch, project: subject.target_project) }

      before do
        subject.mark_as_merged!
        subject.update_attribute(:merge_commit_sha, pipeline.sha)
      end

      it 'returns the post-merge pipeline' do
        expect(subject.merge_pipeline).to eq(pipeline)
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

  describe '#update_head_pipeline' do
    subject { merge_request.update_head_pipeline }

    let(:merge_request) { create(:merge_request) }

    context 'when there is a pipeline with the diff head sha' do
      let!(:pipeline) do
        create(:ci_empty_pipeline,
               project: merge_request.project,
               sha: merge_request.diff_head_sha,
               ref: merge_request.source_branch)
      end

      it 'updates the head pipeline' do
        expect { subject }
          .to change { merge_request.reload.head_pipeline }
          .from(nil).to(pipeline)
      end

      context 'when merge request has already had head pipeline' do
        before do
          merge_request.update!(head_pipeline: pipeline)
        end

        context 'when failed to find an actual head pipeline' do
          before do
            allow(merge_request).to receive(:find_actual_head_pipeline) { }
          end

          it 'does not update the current head pipeline' do
            expect { subject }
              .not_to change { merge_request.reload.head_pipeline }
          end
        end
      end
    end

    context 'when detached merge request pipeline is run on head ref of the merge request' do
      let!(:pipeline) do
        create(:ci_pipeline,
               source: :merge_request_event,
               project: merge_request.source_project,
               ref: merge_request.ref_path,
               sha: sha,
               merge_request: merge_request)
      end

      let(:sha) { merge_request.diff_head_sha }

      it 'sets the head ref of the merge request to the pipeline ref' do
        expect(pipeline.ref).to match(%r{refs/merge-requests/\d+/head})
      end

      it 'updates correctly even though the target branch name of the merge request is different from the pipeline ref' do
        expect { subject }
          .to change { merge_request.reload.head_pipeline }
          .from(nil).to(pipeline)
      end

      context 'when sha is not HEAD of the source branch' do
        let(:sha) { merge_request.diff_base_sha }

        it 'does not update head pipeline' do
          expect { subject }.not_to change { merge_request.reload.head_pipeline }
        end
      end
    end

    context 'when there are no pipelines with the diff head sha' do
      it 'does not update the head pipeline' do
        expect { subject }
          .not_to change { merge_request.reload.head_pipeline }
      end
    end
  end

  describe '#has_test_reports?' do
    subject { merge_request.has_test_reports? }

    let(:project) { create(:project, :repository) }

    context 'when head pipeline has test reports' do
      let(:merge_request) { create(:merge_request, :with_test_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have test reports' do
      let(:merge_request) { create(:merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#calculate_reactive_cache' do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    subject { merge_request.calculate_reactive_cache(service_class_name) }

    context 'when given an unknown service class name' do
      let(:service_class_name) { 'Integer' }

      it 'raises a NameError exception' do
        expect { subject }.to raise_error(NameError, service_class_name)
      end
    end

    context 'when given a known service class name' do
      let(:service_class_name) { 'Ci::CompareTestReportsService' }

      it 'does not raises a NameError exception' do
        allow_any_instance_of(service_class_name.constantize).to receive(:execute).and_return(nil)

        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#find_exposed_artifacts' do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, :with_test_reports, source_project: project) }
    let(:pipeline) { merge_request.head_pipeline }

    subject { merge_request.find_exposed_artifacts }

    context 'when head pipeline has exposed artifacts' do
      let!(:job) do
        create(:ci_build, options: { artifacts: { expose_as: 'artifact', paths: ['ci_artifacts.txt'] } }, pipeline: pipeline)
      end

      let!(:artifacts_metadata) { create(:ci_job_artifact, :metadata, job: job) }

      context 'when reactive cache worker is parsing results asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect(subject[:status]).to eq(:parsed)
        end

        context 'when an error occurrs' do
          before do
            expect_next_instance_of(Ci::FindExposedArtifactsService) do |service|
              expect(service).to receive(:for_pipeline)
                .and_raise(StandardError.new)
            end
          end

          it 'returns an error message' do
            expect(subject[:status]).to eq(:error)
          end
        end

        context 'when cached results is not latest' do
          before do
            allow_next_instance_of(Ci::GenerateExposedArtifactsReportService) do |service|
              allow(service).to receive(:latest?).and_return(false)
            end
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_test_reports' do
    subject { merge_request.compare_test_reports }

    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ci_pipeline,
             :with_test_reports,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has test reports' do
      let!(:head_pipeline) do
        create(:ci_pipeline,
               :with_test_reports,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      context 'when reactive cache worker is parsing asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect_any_instance_of(Ci::CompareTestReportsService)
            .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareTestReportsService)
              .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end

    context 'when head pipeline does not have test reports' do
      let!(:head_pipeline) do
        create(:ci_pipeline,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to eq('This merge request does not have test reports')
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

  describe '#short_merge_commit_sha' do
    let(:merge_request) { build_stubbed(:merge_request) }

    it 'returns short id when there is a merge_commit_sha' do
      merge_request.merge_commit_sha = 'f7ce827c314c9340b075657fd61c789fb01cf74d'

      expect(merge_request.short_merge_commit_sha).to eq('f7ce827c')
    end

    it 'returns nil when there is no merge_commit_sha' do
      merge_request.merge_commit_sha = nil

      expect(merge_request.short_merge_commit_sha).to be_nil
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
          .new(subject.target_project, subject.author, { sha: subject.diff_head_sha })
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
          project.add_maintainer(current_user)

          ProcessCommitWorker.new.perform(project.id,
                                          current_user.id,
                                          project.commit(revert_commit_id).to_hash,
                                          project.default_branch == branch)
        end

        context 'but merged at timestamp cannot be found' do
          before do
            allow(subject).to receive(:merged_at) { nil }
          end

          it 'returns false' do
            expect(subject.can_be_reverted?(current_user)).to be_falsey
          end
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

  describe '#merged_at' do
    context 'when MR is not merged' do
      let(:merge_request) { create(:merge_request, :closed) }

      it 'returns nil' do
        expect(merge_request.merged_at).to be_nil
      end
    end

    context 'when metrics has merged_at data' do
      let(:merge_request) { create(:merge_request, :merged) }

      before do
        merge_request.metrics.update!(merged_at: 1.day.ago)
      end

      it 'returns metrics merged_at' do
        expect(merge_request.merged_at).to eq(merge_request.metrics.merged_at)
      end
    end

    context 'when merged event is persisted, but no metrics merged_at is persisted' do
      let(:user) { create(:user) }
      let(:merge_request) { create(:merge_request, :merged) }

      before do
        EventCreateService.new.merge_mr(merge_request, user)
      end

      it 'returns merged event creation date' do
        expect(merge_request.merge_event).to be_persisted
        expect(merge_request.merged_at).to eq(merge_request.merge_event.created_at)
      end
    end

    context 'when merging note is persisted, but no metrics or merge event exists' do
      let(:user) { create(:user) }
      let(:merge_request) { create(:merge_request, :merged) }

      before do
        merge_request.metrics.destroy!

        SystemNoteService.change_status(merge_request,
                                        merge_request.target_project,
                                        user,
                                        merge_request.state, nil)
      end

      it 'returns merging note creation date' do
        expect(merge_request.reload.metrics).to be_nil
        expect(merge_request.merge_event).to be_nil
        expect(merge_request.notes.count).to eq(1)
        expect(merge_request.merged_at).to eq(merge_request.notes.first.created_at)
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
      mr = create(:merge_request, assignees: [user1])
      mr.project.add_developer(user1)
      mr.project.add_developer(user2)

      expect(user1.assigned_open_merge_requests_count).to eq(1)
      expect(user2.assigned_open_merge_requests_count).to eq(0)

      mr.assignees = [user2]

      expect(user1.assigned_open_merge_requests_count).to eq(0)
      expect(user2.assigned_open_merge_requests_count).to eq(1)
    end
  end

  describe '#merge_async' do
    it 'enqueues MergeWorker job and updates merge_jid' do
      merge_request = create(:merge_request)
      user_id = double(:user_id)
      params = {}
      merge_jid = 'hash-123'

      expect(merge_request).to receive(:expire_etag_cache)
      expect(MergeWorker).to receive(:perform_async).with(merge_request.id, user_id, params) do
        merge_jid
      end

      merge_request.merge_async(user_id, params)

      expect(merge_request.reload.merge_jid).to eq(merge_jid)
    end
  end

  describe '#rebase_async' do
    let(:merge_request) { create(:merge_request) }
    let(:user_id) { double(:user_id) }
    let(:rebase_jid) { 'rebase-jid' }

    subject(:execute) { merge_request.rebase_async(user_id) }

    it 'atomically enqueues a RebaseWorker job and updates rebase_jid' do
      expect(RebaseWorker)
        .to receive(:perform_async)
        .with(merge_request.id, user_id)
        .and_return(rebase_jid)

      expect(merge_request).to receive(:expire_etag_cache)
      expect(merge_request).to receive(:lock!).and_call_original

      execute

      expect(merge_request.rebase_jid).to eq(rebase_jid)
    end

    it 'refuses to enqueue a job if a rebase is in progress' do
      merge_request.update_column(:rebase_jid, rebase_jid)

      expect(RebaseWorker).not_to receive(:perform_async)
      expect(Gitlab::SidekiqStatus)
        .to receive(:running?)
        .with(rebase_jid)
        .and_return(true)

      expect { execute }.to raise_error(ActiveRecord::StaleObjectError)
    end

    it 'refuses to enqueue a job if the MR is not open' do
      merge_request.update_column(:state_id, 5)

      expect(RebaseWorker).not_to receive(:perform_async)

      expect { execute }.to raise_error(ActiveRecord::StaleObjectError)
    end

    it "raises ActiveRecord::LockWaitTimeout after 6 tries" do
      expect(merge_request).to receive(:with_lock).exactly(6).times.and_raise(ActiveRecord::LockWaitTimeout)
      expect(RebaseWorker).not_to receive(:perform_async)

      expect { execute }.to raise_error(MergeRequest::RebaseLockTimeout)
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
      expect(subject).to receive(:check_mergeability)
      expect(subject).to receive(:can_be_merged?) { true }

      expect(subject.mergeable?).to be_truthy
    end
  end

  describe '#check_mergeability' do
    let(:mergeability_service) { double }

    before do
      allow(MergeRequests::MergeabilityCheckService).to receive(:new) do
        mergeability_service
      end
    end

    context 'if the merge status is unchecked' do
      before do
        subject.mark_as_unchecked!
      end

      it 'executes MergeabilityCheckService' do
        expect(mergeability_service).to receive(:execute)

        subject.check_mergeability
      end
    end

    context 'if the merge status is checked' do
      context 'and feature flag is enabled' do
        it 'executes MergeabilityCheckService' do
          expect(mergeability_service).not_to receive(:execute)

          subject.check_mergeability
        end
      end

      context 'and feature flag is disabled' do
        before do
          stub_feature_flags(merge_requests_conditional_mergeability_check: false)
        end

        it 'does not execute MergeabilityCheckService' do
          expect(mergeability_service).to receive(:execute)

          subject.check_mergeability
        end
      end
    end
  end

  describe '#mergeable_state?' do
    let(:project) { create(:project, :repository) }

    subject { create(:merge_request, source_project: project) }

    it 'checks if merge request can be merged' do
      allow(subject).to receive(:mergeable_ci_state?) { true }
      expect(subject).to receive(:check_mergeability)

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

  describe "#head_pipeline_active? " do
    it do
      is_expected
        .to delegate_method(:active?)
        .to(:head_pipeline)
        .with_prefix
        .with_arguments(allow_nil: true)
    end
  end

  describe "#actual_head_pipeline_success? " do
    it do
      is_expected
        .to delegate_method(:success?)
        .to(:actual_head_pipeline)
        .with_prefix
        .with_arguments(allow_nil: true)
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

        it { expect(subject.mergeable_ci_state?).to be_falsey }
      end

      context 'when no pipeline is associated' do
        before do
          allow(subject).to receive(:head_pipeline) { nil }
        end

        it { expect(subject.mergeable_ci_state?).to be_falsey }
      end
    end

    context 'when merges are not restricted to green builds' do
      subject { build(:merge_request, target_project: create(:project, only_allow_merge_if_pipeline_succeeds: false)) }

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
          merge_request.notes.destroy_all # rubocop: disable DestroyAll
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
      merge_request.source_project.add_maintainer(user)
      merge_request.target_project.add_maintainer(user)
    end

    context 'with multiple environments' do
      let(:environments) { create_list(:environment, 3, project: project) }

      before do
        create(:deployment, :success, environment: environments.first, ref: 'master', sha: project.commit('master').id)
        create(:deployment, :success, environment: environments.second, ref: 'feature', sha: project.commit('feature').id)
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
        create(:deployment, :success, environment: source_environment, ref: 'feature', sha: merge_request.diff_head_sha)
      end

      it 'selects deployed environments', :sidekiq_might_not_need_inline do
        expect(merge_request.environments_for(user)).to contain_exactly(source_environment)
      end

      context 'with environments on target project' do
        let(:target_environment) { create(:environment, project: project) }

        before do
          create(:deployment, :success, environment: target_environment, tag: true, sha: merge_request.diff_head_sha)
        end

        it 'selects deployed environments', :sidekiq_might_not_need_inline do
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

  describe "#environments" do
    subject { merge_request.environments }

    let(:merge_request) { create(:merge_request, source_branch: 'feature', target_branch: 'master') }
    let(:project) { merge_request.project }

    let(:pipeline) do
      create(:ci_pipeline,
        source: :merge_request_event,
        merge_request: merge_request, project: project,
        sha: merge_request.diff_head_sha,
        merge_requests_as_head_pipeline: [merge_request])
    end

    let!(:job) { create(:ci_build, :with_deployment, :start_review_app, pipeline: pipeline, project: project) }

    it 'returns environments' do
      is_expected.to eq(pipeline.environments)
      expect(subject.count).to be(1)
    end

    context 'when pipeline is not associated with environments' do
      let!(:job) { create(:ci_build, pipeline: pipeline, project: project) }

      it 'returns empty array' do
        is_expected.to be_empty
      end
    end

    context 'when pipeline is not a pipeline for merge request' do
      let(:pipeline) do
        create(:ci_pipeline,
          project: project,
          ref: 'feature',
          sha: merge_request.diff_head_sha,
          merge_requests_as_head_pipeline: [merge_request])
      end

      it 'returns empty relation' do
        is_expected.to be_empty
      end
    end
  end

  describe "#reload_diff" do
    it 'calls MergeRequests::ReloadDiffsService#execute with correct params' do
      user = create(:user)
      service = instance_double(MergeRequests::ReloadDiffsService, execute: nil)

      expect(MergeRequests::ReloadDiffsService)
        .to receive(:new).with(subject, user)
        .and_return(service)

      subject.reload_diff(user)

      expect(service).to have_received(:execute)
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

        subject.reload_merge_request_diff
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

      let(:expected_diff_refs) do
        Gitlab::Diff::DiffRefs.new(
          base_sha:  subject.merge_request_diff.base_commit_sha,
          start_sha: subject.merge_request_diff.start_commit_sha,
          head_sha:  subject.merge_request_diff.head_commit_sha
        )
      end

      it "does not touch the repository" do
        subject # Instantiate the object

        expect_any_instance_of(Repository).not_to receive(:commit)

        subject.diff_refs
      end

      it "returns expected diff_refs" do
        expect(subject.diff_refs).to eq(expected_diff_refs)
      end

      context 'when importing' do
        before do
          subject.importing = true
        end

        it "returns MR diff_refs" do
          expect(subject.diff_refs).to eq(expected_diff_refs)
        end
      end
    end
  end

  describe "#source_project_missing?" do
    let(:project) { create(:project) }
    let(:forked_project) { fork_project(project) }
    let(:user) { create(:user) }
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
      merge_request = build_stubbed(:merge_request, state_id: described_class.available_states[:locked])

      expect(merge_request.merge_ongoing?).to be(true)
    end

    it 'returns true when merge_id, MR is not merged and it has no running job' do
      merge_request = build_stubbed(:merge_request, state_id: described_class.available_states[:opened], merge_jid: 'foo')
      allow(Gitlab::SidekiqStatus).to receive(:running?).with('foo') { true }

      expect(merge_request.merge_ongoing?).to be(true)
    end

    it 'returns false when merge_jid is nil' do
      merge_request = build_stubbed(:merge_request, state_id: described_class.available_states[:opened], merge_jid: nil)

      expect(merge_request.merge_ongoing?).to be(false)
    end

    it 'returns false if MR is merged' do
      merge_request = build_stubbed(:merge_request, state_id: described_class.available_states[:merged], merge_jid: 'foo')

      expect(merge_request.merge_ongoing?).to be(false)
    end

    it 'returns false if there is no merge job running' do
      merge_request = build_stubbed(:merge_request, state_id: described_class.available_states[:opened], merge_jid: 'foo')
      allow(Gitlab::SidekiqStatus).to receive(:running?).with('foo') { false }

      expect(merge_request.merge_ongoing?).to be(false)
    end
  end

  describe "#closed_without_fork?" do
    let(:project) { create(:project) }
    let(:forked_project) { fork_project(project) }
    let(:user) { create(:user) }
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
          merge_request.update(state: 'merged')

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
      pipeline = create(:ci_pipeline,
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

      context 'closed MR' do
        before do
          merge_request.update_attribute(:state_id, described_class.available_states[:closed])
        end

        it 'is not mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_falsey
        end
      end

      context 'MR with WIP' do
        before do
          merge_request.update_attribute(:title, 'WIP: some MR')
        end

        it 'is not mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_falsey
        end
      end

      context 'sha differs from the MR diff_head_sha' do
        it 'is not mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: 'some other sha')).to be_falsey
        end
      end

      context 'sha is not provided' do
        it 'is not mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer)).to be_falsey
        end
      end

      context 'with pipeline ok' do
        before do
          create_pipeline(:success)
        end

        it 'is mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_truthy
        end
      end

      context 'with failing pipeline' do
        before do
          create_pipeline(:failed)
        end

        it 'is not mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_falsey
        end
      end

      context 'with running pipeline' do
        before do
          create_pipeline(:running)
        end

        it 'is mergeable' do
          expect(merge_request.mergeable_with_quick_action?(developer, last_diff_sha: mr_sha)).to be_truthy
        end
      end
    end
  end

  describe '#base_pipeline' do
    let(:pipeline_arguments) do
      {
        project: project,
        ref: merge_request.target_branch,
        sha: merge_request.diff_base_sha
      }
    end

    let(:project) { create(:project, :public, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:first_pipeline) { create(:ci_pipeline, pipeline_arguments) }
    let!(:last_pipeline) { create(:ci_pipeline, pipeline_arguments) }
    let!(:last_pipeline_with_other_ref) { create(:ci_pipeline, pipeline_arguments.merge(ref: 'other')) }

    it 'returns latest pipeline for the target branch' do
      expect(merge_request.base_pipeline).to eq(last_pipeline)
    end
  end

  describe '#has_commits?' do
    it 'returns true when merge request diff has commits' do
      allow(subject.merge_request_diff).to receive(:commits_count)
        .and_return(2)

      expect(subject.has_commits?).to be_truthy
    end

    context 'when commits_count is nil' do
      it 'returns false' do
        allow(subject.merge_request_diff).to receive(:commits_count)
        .and_return(nil)

        expect(subject.has_commits?).to be_falsey
      end
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

      it 'updates merge request head pipeline and sets merge_jid to nil', :sidekiq_might_not_need_inline do
        pipeline = create(:ci_empty_pipeline, project: subject.project, ref: subject.source_branch, sha: subject.source_branch_sha)

        subject.unlock_mr

        subject.reload
        expect(subject.head_pipeline).to eq(pipeline)
        expect(subject.merge_jid).to be_nil
      end
    end

    describe 'transition to cannot_be_merged' do
      let(:notification_service) { double(:notification_service) }
      let(:todo_service) { double(:todo_service) }
      subject { create(:merge_request, state, merge_status: :unchecked) }

      before do
        allow(NotificationService).to receive(:new).and_return(notification_service)
        allow(TodoService).to receive(:new).and_return(todo_service)

        allow(subject.project.repository).to receive(:can_be_merged?).and_return(false)
      end

      [:opened, :locked].each do |state|
        context state do
          let(:state) { state }

          it 'notifies conflict, but does not notify again if rechecking still results in cannot_be_merged' do
            expect(notification_service).to receive(:merge_request_unmergeable).with(subject).once
            expect(todo_service).to receive(:merge_request_became_unmergeable).with(subject).once

            subject.mark_as_unmergeable
            subject.mark_as_unchecked
            subject.mark_as_unmergeable
          end

          it 'notifies conflict, whenever newly unmergeable' do
            expect(notification_service).to receive(:merge_request_unmergeable).with(subject).twice
            expect(todo_service).to receive(:merge_request_became_unmergeable).with(subject).twice

            subject.mark_as_unmergeable
            subject.mark_as_unchecked
            subject.mark_as_mergeable
            subject.mark_as_unchecked
            subject.mark_as_unmergeable
          end

          it 'does not notify whenever merge request is newly unmergeable due to other reasons' do
            allow(subject.project.repository).to receive(:can_be_merged?).and_return(true)

            expect(notification_service).not_to receive(:merge_request_unmergeable)
            expect(todo_service).not_to receive(:merge_request_became_unmergeable)

            subject.mark_as_unmergeable
          end
        end
      end

      [:closed, :merged].each do |state|
        let(:state) { state }

        context state do
          it 'does not notify' do
            expect(notification_service).not_to receive(:merge_request_unmergeable)
            expect(todo_service).not_to receive(:merge_request_became_unmergeable)

            subject.mark_as_unmergeable
          end
        end
      end

      context 'source branch is missing' do
        subject { create(:merge_request, :invalid, :opened, merge_status: :unchecked, target_branch: 'master') }

        before do
          allow(subject.project.repository).to receive(:can_be_merged?).and_call_original
        end

        it 'does not raise error' do
          expect(notification_service).not_to receive(:merge_request_unmergeable)
          expect(todo_service).not_to receive(:merge_request_became_unmergeable)

          expect { subject.mark_as_unmergeable }.not_to raise_error
          expect(subject.cannot_be_merged?).to eq(true)
        end
      end
    end

    describe 'check_state?' do
      it 'indicates whether MR is still checking for mergeability' do
        state_machine = described_class.state_machines[:merge_status]
        check_states = [:unchecked, :cannot_be_merged_recheck]

        check_states.each do |merge_status|
          expect(state_machine.check_state?(merge_status)).to be true
        end

        (state_machine.states.map(&:name) - check_states).each do |merge_status|
          expect(state_machine.check_state?(merge_status)).to be false
        end
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
    where(:rebase_jid, :jid_valid, :result) do
      'foo' | true  | true
      'foo' | false | false
      ''    | true  | false
      nil   | true  | false
    end

    with_them do
      let(:merge_request) { create(:merge_request) }

      subject { merge_request.rebase_in_progress? }

      it do
        allow(Gitlab::SidekiqStatus).to receive(:running?).with(rebase_jid) { jid_valid }

        merge_request.rebase_jid = rebase_jid

        is_expected.to eq(result)
      end
    end
  end

  describe '#allow_collaboration' do
    let(:merge_request) do
      build(:merge_request, source_branch: 'fixes', allow_collaboration: true)
    end

    it 'is false when pushing by a maintainer is not possible' do
      expect(merge_request).to receive(:collaborative_push_possible?) { false }

      expect(merge_request.allow_collaboration).to be_falsy
    end

    it 'is true when pushing by a maintainer is possible' do
      expect(merge_request).to receive(:collaborative_push_possible?) { true }

      expect(merge_request.allow_collaboration).to be_truthy
    end
  end

  describe '#collaborative_push_possible?' do
    let(:merge_request) do
      build(:merge_request, source_branch: 'fixes')
    end

    before do
      allow(ProtectedBranch).to receive(:protected?) { false }
    end

    it 'does not allow maintainer to push if the source project is the same as the target' do
      merge_request.target_project = merge_request.source_project = create(:project, :public)

      expect(merge_request.collaborative_push_possible?).to be_falsy
    end

    it 'allows maintainer to push when both source and target are public' do
      merge_request.target_project = build(:project, :public)
      merge_request.source_project = build(:project, :public)

      expect(merge_request.collaborative_push_possible?).to be_truthy
    end

    it 'is not available for protected branches' do
      merge_request.target_project = build(:project, :public)
      merge_request.source_project = build(:project, :public)

      expect(ProtectedBranch).to receive(:protected?)
                                   .with(merge_request.source_project, 'fixes')
                                   .and_return(true)

      expect(merge_request.collaborative_push_possible?).to be_falsy
    end
  end

  describe '#can_allow_collaboration?' do
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
      allow(merge_request).to receive(:collaborative_push_possible?) { true }
    end

    it 'is false if the user does not have push access to the source project' do
      expect(merge_request.can_allow_collaboration?(user)).to be_falsy
    end

    it 'is true when the user has push access to the source project' do
      source_project.add_developer(user)

      expect(merge_request.can_allow_collaboration?(user)).to be_truthy
    end
  end

  describe '#merge_participants' do
    it 'contains author' do
      expect(subject.merge_participants).to eq([subject.author])
    end

    describe 'when merge_when_pipeline_succeeds? is true' do
      describe 'when merge user is author' do
        let(:user) { create(:user) }
        subject do
          create(:merge_request,
                 merge_when_pipeline_succeeds: true,
                 merge_user: user,
                 author: user)
        end

        it 'contains author only' do
          expect(subject.merge_participants).to eq([subject.author])
        end
      end

      describe 'when merge user and author are different users' do
        let(:merge_user) { create(:user) }
        subject do
          create(:merge_request,
                 merge_when_pipeline_succeeds: true,
                 merge_user: merge_user)
        end

        it 'contains author and merge user' do
          expect(subject.merge_participants).to eq([subject.author, merge_user])
        end
      end
    end
  end

  describe '.merge_request_ref?' do
    subject { described_class.merge_request_ref?(ref) }

    context 'when ref is ref name of a branch' do
      let(:ref) { 'feature' }

      it { is_expected.to be_falsey }
    end

    context 'when ref is HEAD ref path of a branch' do
      let(:ref) { 'refs/heads/feature' }

      it { is_expected.to be_falsey }
    end

    context 'when ref is HEAD ref path of a merge request' do
      let(:ref) { 'refs/merge-requests/1/head' }

      it { is_expected.to be_truthy }
    end

    context 'when ref is merge ref path of a merge request' do
      let(:ref) { 'refs/merge-requests/1/merge' }

      it { is_expected.to be_truthy }
    end
  end

  describe '.merge_train_ref?' do
    subject { described_class.merge_train_ref?(ref) }

    context 'when ref is ref name of a branch' do
      let(:ref) { 'feature' }

      it { is_expected.to be_falsey }
    end

    context 'when ref is HEAD ref path of a branch' do
      let(:ref) { 'refs/heads/feature' }

      it { is_expected.to be_falsey }
    end

    context 'when ref is HEAD ref path of a merge request' do
      let(:ref) { 'refs/merge-requests/1/head' }

      it { is_expected.to be_falsey }
    end

    context 'when ref is merge ref path of a merge request' do
      let(:ref) { 'refs/merge-requests/1/merge' }

      it { is_expected.to be_falsey }
    end

    context 'when ref is train ref path of a merge request' do
      let(:ref) { 'refs/merge-requests/1/train' }

      it { is_expected.to be_truthy }
    end
  end

  describe '#cleanup_refs' do
    subject { merge_request.cleanup_refs(only: only) }

    let(:merge_request) { build(:merge_request) }

    context 'when removing all refs' do
      let(:only) { :all }

      it 'deletes all refs from the target project' do
        expect(merge_request.target_project.repository)
          .to receive(:delete_refs)
          .with(merge_request.ref_path, merge_request.merge_ref_path, merge_request.train_ref_path)

        subject
      end
    end

    context 'when removing only train ref' do
      let(:only) { :train }

      it 'deletes train ref from the target project' do
        expect(merge_request.target_project.repository)
          .to receive(:delete_refs)
          .with(merge_request.train_ref_path)

        subject
      end
    end
  end

  describe '.with_auto_merge_enabled' do
    let!(:project) { create(:project) }
    let!(:fork) { fork_project(project) }
    let!(:merge_request1) do
      create(:merge_request,
             :merge_when_pipeline_succeeds,
             target_project: project,
             target_branch: 'master',
             source_project: project,
             source_branch: 'feature-1')
    end

    let!(:merge_request4) do
      create(:merge_request,
             target_project: project,
             target_branch: 'master',
             source_project: fork,
             source_branch: 'fork-feature-2')
    end

    let(:query) { described_class.with_auto_merge_enabled }

    it { expect(query).to contain_exactly(merge_request1) }
  end

  it_behaves_like 'versioned description'

  describe '#commits' do
    context 'persisted merge request' do
      context 'with a limit' do
        it 'returns a limited number of commits' do
          expect(subject.commits(limit: 2).map(&:sha)).to eq(%w[
            b83d6e391c22777fca1ed3012fce84f633d7fed0
            498214de67004b1da3d820901307bed2a68a8ef6
          ])
          expect(subject.commits(limit: 3).map(&:sha)).to eq(%w[
            b83d6e391c22777fca1ed3012fce84f633d7fed0
            498214de67004b1da3d820901307bed2a68a8ef6
            1b12f15a11fc6e62177bef08f47bc7b5ce50b141
          ])
        end
      end

      context 'without a limit' do
        it 'returns all commits of the merge request diff' do
          expect(subject.commits.size).to eq(29)
        end
      end
    end

    context 'new merge request' do
      subject { build(:merge_request) }

      context 'compare commits' do
        let(:first_commit) { double }
        let(:second_commit) { double }

        before do
          subject.compare_commits = [
            first_commit, second_commit
          ]
        end

        context 'without a limit' do
          it 'returns all the compare commits' do
            expect(subject.commits.to_a).to eq([second_commit, first_commit])
          end
        end

        context 'with a limit' do
          it 'returns a limited number of commits' do
            expect(subject.commits(limit: 1).to_a).to eq([second_commit])
          end
        end
      end
    end
  end

  describe '#recent_commits' do
    before do
      stub_const("#{MergeRequestDiff}::COMMITS_SAFE_SIZE", 2)
    end

    it 'returns the safe number of commits' do
      expect(subject.recent_commits.map(&:sha)).to eq(%w[
        b83d6e391c22777fca1ed3012fce84f633d7fed0 498214de67004b1da3d820901307bed2a68a8ef6
      ])
    end
  end

  describe '#recent_visible_deployments' do
    let(:merge_request) { create(:merge_request) }

    let(:environment) do
      create(:environment, project: merge_request.target_project)
    end

    it 'returns visible deployments' do
      created = create(
        :deployment,
        :created,
        project: merge_request.target_project,
        environment: environment
      )

      success = create(
        :deployment,
        :success,
        project: merge_request.target_project,
        environment: environment
      )

      failed = create(
        :deployment,
        :failed,
        project: merge_request.target_project,
        environment: environment
      )

      merge_request.deployment_merge_requests.create!(deployment: created)
      merge_request.deployment_merge_requests.create!(deployment: success)
      merge_request.deployment_merge_requests.create!(deployment: failed)

      expect(merge_request.recent_visible_deployments).to eq([failed, success])
    end

    it 'only returns a limited number of deployments' do
      20.times do
        deploy = create(
          :deployment,
          :success,
          project: merge_request.target_project,
          environment: environment
        )

        merge_request.deployment_merge_requests.create!(deployment: deploy)
      end

      expect(merge_request.recent_visible_deployments.count).to eq(10)
    end
  end
end
