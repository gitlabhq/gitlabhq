# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest, factory_default: :keep, feature_category: :code_review_workflow do
  include RepoHelpers
  include ProjectForksHelper
  include ReactiveCachingHelpers

  using RSpec::Parameterized::TableSyntax

  let_it_be(:namespace) { create_default(:namespace).freeze }
  let_it_be(:project, refind: true) { create_default(:project, :repository).freeze }

  subject { create(:merge_request, source_project: project) }

  describe 'associations' do
    subject { build_stubbed(:merge_request) }

    it { is_expected.to belong_to(:target_project).class_name('Project') }
    it { is_expected.to belong_to(:source_project).class_name('Project') }
    it { is_expected.to belong_to(:merge_user).class_name("User") }

    it do
      is_expected.to belong_to(:head_pipeline).class_name('Ci::Pipeline').inverse_of(:merge_requests_as_head_pipeline)
    end

    it { is_expected.to have_many(:assignees).through(:merge_request_assignees) }
    it { is_expected.to have_many(:reviewers).through(:merge_request_reviewers) }
    it { is_expected.to have_many(:merge_request_diffs) }
    it { is_expected.to have_many(:user_mentions).class_name("MergeRequestUserMention") }
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to have_many(:resource_milestone_events) }
    it { is_expected.to have_many(:resource_state_events) }
    it { is_expected.to have_many(:draft_notes) }
    it { is_expected.to have_many(:reviews).inverse_of(:merge_request) }
    it { is_expected.to have_many(:reviewed_by_users).through(:reviews).source(:author) }
    it { is_expected.to have_one(:cleanup_schedule).inverse_of(:merge_request) }
    it { is_expected.to have_one(:merge_schedule).class_name('MergeRequests::MergeSchedule').inverse_of(:merge_request) }
    it { is_expected.to have_many(:created_environments).class_name('Environment').inverse_of(:merge_request) }
    it { is_expected.to have_many(:assignment_events).class_name('ResourceEvents::MergeRequestAssignmentEvent').inverse_of(:merge_request) }

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

    describe '#reviewed_by_users' do
      let!(:merge_request) { create(:merge_request) }

      context 'when the same user has several reviews' do
        before do
          2.times { create(:review, merge_request: merge_request, project: merge_request.project, author: merge_request.author) }
        end

        it 'returns distinct users' do
          expect(merge_request.reviewed_by_users).to match_array([merge_request.author])
        end
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

  describe '.order_merged_at_asc' do
    let_it_be(:older_mr) { create(:merge_request, :with_merged_metrics) }
    let_it_be(:newer_mr) { create(:merge_request, :with_merged_metrics) }

    it 'returns MRs ordered by merged_at ascending' do
      expect(described_class.order_merged_at_asc).to eq([older_mr, newer_mr])
    end
  end

  describe '.order_merged_at_desc' do
    let_it_be(:older_mr) { create(:merge_request, :with_merged_metrics) }
    let_it_be(:newer_mr) { create(:merge_request, :with_merged_metrics) }

    it 'returns MRs ordered by merged_at descending' do
      expect(described_class.order_merged_at_desc).to eq([newer_mr, older_mr])
    end
  end

  describe '.order_closed_at_asc' do
    let_it_be(:older_mr) { create(:merge_request, :closed_last_month) }
    let_it_be(:newer_mr) { create(:merge_request, :closed_last_month) }

    it 'returns MRs ordered by closed_at ascending' do
      expect(described_class.order_closed_at_asc).to eq([older_mr, newer_mr])
    end
  end

  describe '.order_closed_at_desc' do
    let_it_be(:older_mr) { create(:merge_request, :closed_last_month) }
    let_it_be(:newer_mr) { create(:merge_request, :closed_last_month) }

    it 'returns MRs ordered by closed_at descending' do
      expect(described_class.order_closed_at_desc).to eq([newer_mr, older_mr])
    end
  end

  describe '.with_jira_issue_keys' do
    let_it_be(:mr_with_jira_title) { create(:merge_request, :unique_branches, title: 'Fix TEST-123') }
    let_it_be(:mr_with_jira_description) { create(:merge_request, :unique_branches, description: 'this closes TEST-321') }
    let_it_be(:mr_without_jira_reference) { create(:merge_request, :unique_branches) }

    subject { described_class.with_jira_issue_keys }

    it { is_expected.to contain_exactly(mr_with_jira_title, mr_with_jira_description) }

    it { is_expected.not_to include(mr_without_jira_reference) }
  end

  context 'scopes' do
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }

    let_it_be(:merge_request1) do
      create(:merge_request, :prepared, :unique_branches, reviewers: [user1], created_at:
             2.days.ago)
    end

    let_it_be(:merge_request2) do
      create(:merge_request, :unprepared, :unique_branches, reviewers: [user1, user2], created_at:
             3.hours.ago)
    end

    let_it_be(:merge_request3) do
      create(:merge_request, :unprepared, :unique_branches, reviewers: [], created_at:
                                        Time.current)
    end

    let_it_be(:merge_request4) { create(:merge_request, :prepared, :draft_merge_request) }

    before_all do
      merge_request1.merge_request_reviewers.update_all(state: :requested_changes)
      merge_request2.merge_request_reviewers.update_all(state: :reviewed)
    end

    describe '.preload_target_project_with_namespace' do
      subject(:mr) { described_class.preload_target_project_with_namespace.first }

      it 'returns MR with the target project\'s namespace preloaded' do
        expect(mr.association(:target_project)).to be_loaded
        expect(mr.target_project.association(:namespace)).to be_loaded
      end
    end

    describe '.review_requested' do
      it 'returns MRs that have any review requests' do
        expect(described_class.review_requested).to eq([merge_request1, merge_request2])
      end
    end

    describe '.no_review_requested' do
      it 'returns MRs that have no review requests' do
        expect(described_class.no_review_requested).to eq([merge_request3, merge_request4])
      end
    end

    describe '.review_requested_to' do
      let(:states) { nil }

      subject(:merge_requests) { described_class.review_requested_to(user1, states) }

      it 'returns MRs that the user has been requested to review' do
        expect(merge_requests).to match_array([merge_request1, merge_request2])
      end

      context 'when state is requested_changes' do
        let(:states) { MergeRequestReviewer.states[:requested_changes] }

        it 'returns MRs that the user has been requested to review and has the passed state' do
          expect(merge_requests).to eq([merge_request1])
        end
      end

      context 'when states includes requested_changes and reviewed' do
        let(:states) { [MergeRequestReviewer.states[:reviewed], MergeRequestReviewer.states[:requested_changes]] }

        it { expect(merge_requests).to match_array([merge_request1, merge_request2]) }
      end

      context 'when state is approved' do
        let(:states) { MergeRequestReviewer.states[:approved] }

        it 'returns MRs that the user has been requested to review and has the passed state' do
          expect(merge_requests).to eq([])
        end
      end
    end

    describe '.by_blob_path' do
      let(:path) { 'bar/branch-test.txt' }

      it 'returns MRs that modified blob by provided path' do
        expect(described_class.by_blob_path(path))
          .to match_array([merge_request4])
      end
    end

    describe '.no_review_requested_to' do
      it 'returns MRs that the user has not been requested to review' do
        expect(described_class.no_review_requested_to(user1))
          .to match_array([merge_request3, merge_request4])
      end
    end

    describe '.review_states' do
      let(:states) { MergeRequestReviewer.states[:requested_changes] }

      subject(:merge_requests) { described_class.review_states(states) }

      it 'returns MRs that have a reviewer with the passed state' do
        expect(merge_requests).to eq([merge_request1])
      end

      context 'when states includes requested_changes and reviewed' do
        let(:states) { [MergeRequestReviewer.states[:reviewed], MergeRequestReviewer.states[:requested_changes]] }

        it { expect(merge_requests).to match_array([merge_request1, merge_request2]) }
      end
    end

    describe '.no_review_states' do
      let(:states) { [MergeRequestReviewer.states[:requested_changes]] }

      subject(:merge_requests) { described_class.no_review_states(states) }

      it { expect(merge_requests).to contain_exactly(merge_request2) }
    end

    describe '.assignee_or_reviewer' do
      let_it_be(:merge_request5) do
        create(:merge_request, :prepared, :unique_branches, assignees: [user1], reviewers: [user2], created_at:
              2.days.ago)
      end

      it 'returns merge requests that the user is a reviewer or an assignee of' do
        expect(described_class.assignee_or_reviewer(user1, nil, nil)).to match_array([merge_request1, merge_request2, merge_request5])
      end

      context 'when the user is an assignee and a reviewer reviewed' do
        before_all do
          merge_request5.merge_request_reviewers.update_all(state: :reviewed)
        end

        it { expect(described_class.assignee_or_reviewer(user1, MergeRequestReviewer.states[:reviewed], nil)).to match_array([merge_request1, merge_request2, merge_request5]) }

        it { expect(described_class.assignee_or_reviewer(user1, MergeRequestReviewer.states[:requested_changes], nil)).to match_array([merge_request1, merge_request2]) }
      end

      context 'when the user is a reviewer and left a review' do
        it { expect(described_class.assignee_or_reviewer(user1, nil, MergeRequestReviewer.states[:reviewed])).to match_array([merge_request2, merge_request5]) }

        it { expect(described_class.assignee_or_reviewer(user1, nil, MergeRequestReviewer.states[:requested_changes])).to match_array([merge_request1, merge_request5]) }
      end
    end

    describe '.drafts' do
      it 'returns MRs where draft == true' do
        expect(described_class.drafts).to eq([merge_request4])
      end
    end

    describe '.recently_unprepared' do
      it 'only returns the recently unprepared mrs' do
        merge_request5 = create(:merge_request, :unprepared, :unique_branches, created_at: merge_request3.created_at)

        expect(described_class.recently_unprepared).to eq([merge_request3, merge_request5])
      end
    end

    describe '.by_sorted_source_branches' do
      let(:fork_for_project) { fork_project(project) }

      let!(:merge_request_to_master) { create(:merge_request, :closed, target_project: project, source_branch: 'a-feature') }
      let!(:merge_request_to_other_branch) { create(:merge_request, target_project: project, source_branch: 'b-feature') }
      let!(:merge_request_to_master2) { create(:merge_request, target_project: project, source_branch: 'a-feature') }
      let!(:merge_request_from_fork_to_master) { create(:merge_request, source_project: fork_for_project, target_project: project, source_branch: 'b-feature') }

      it 'returns merge requests sorted by name and id' do
        expect(described_class.by_sorted_source_branches(%w[a-feature b-feature non-existing-feature])).to eq(
          [
            merge_request_to_master2,
            merge_request_to_master,
            merge_request_from_fork_to_master,
            merge_request_to_other_branch
          ]
        )
      end
    end

    describe '.without_hidden', feature_category: :insider_threat do
      let_it_be(:banned_user) { create(:user, :banned) }
      let_it_be(:hidden_merge_request) { create(:merge_request, :unique_branches, author: banned_user) }

      it 'only returns public issuables' do
        expect(described_class.without_hidden).not_to include(hidden_merge_request)
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(hide_merge_requests_from_banned_users: false)
        end

        it 'returns public and hidden issuables' do
          expect(described_class.without_hidden).to include(hidden_merge_request)
        end
      end
    end

    describe '.merged_without_state_event_source' do
      let(:source_merge_request) { nil }
      let(:source_commit) { nil }

      subject { described_class.merged_without_state_event_source }

      before do
        create(:resource_state_event, merge_request: merge_request1, state: :merged, source_merge_request: source_merge_request, source_commit: source_commit)
      end

      context 'when the state matches and event source is empty' do
        it 'filters by resource_state_event' do
          expect(subject).to contain_exactly(merge_request1)
        end
      end

      context 'when source_merge_request is not empty' do
        let(:source_merge_request) { merge_request2 }

        it 'filters by resource_state_event' do
          expect(subject).to be_empty
        end
      end

      context 'when source_commit is not empty' do
        let(:source_commit) { 'abcd1234' }

        it 'filters by resource_state_event' do
          expect(subject).to be_empty
        end
      end
    end
  end

  describe '#squash_option' do
    let(:merge_request) { build(:merge_request, project: project) }
    let(:project_setting) { project.project_setting }

    subject { merge_request.squash_option }

    it { is_expected.to eq(project_setting) }
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

  describe '#squash_commit' do
    subject { merge_request.squash_commit }

    let(:merge_request) { build(:merge_request, target_project: project, squash: true, squash_commit_sha: sha) }
    let(:commit) { project.repository.commit }

    context 'when a commit is present in the repository' do
      let(:sha) { commit.sha }

      it { is_expected.to eq(commit) }
    end

    context 'when a commit is not found' do
      let(:sha) { 'abc123' }

      it { is_expected.to be_nil }
    end
  end

  describe '#commit_to_revert' do
    subject { merge_request.commit_to_revert }

    context 'when a merge request is not merged' do
      let(:merge_request) { build(:merge_request, :opened, target_project: project) }

      it { is_expected.to be_nil }
    end

    context 'when a merge request is merged' do
      let_it_be(:commit) { project.repository.commit }

      let(:merge_request) do
        build(
          :merge_request,
          :merged,
          target_project: project,
          merge_commit_sha: merge_commit_sha,
          squash_commit_sha: squash_commit_sha
        )
      end

      let(:merge_commit_sha) { nil }
      let(:squash_commit_sha) { nil }

      context 'when merge request has a merge commit' do
        let(:merge_commit_sha) { commit.sha }

        it { is_expected.to eq(commit) }
      end

      context 'when merge request has a squash commit' do
        let(:squash_commit_sha) { commit.sha }

        it { is_expected.to eq(commit) }
      end

      context 'when merge request does not have merge and squash commits' do
        let(:merge_request) { create(:merge_request, :merged, target_project: project) }
        let(:merge_request_diff) { create(:merge_request_diff, merge_request: merge_request, head_commit_sha: commit.sha) }

        context 'when the diff has only one commit' do
          before do
            create(:merge_request_diff_commit, merge_request_diff: merge_request_diff, sha: 'abc123')
            merge_request_diff.save_git_content
          end

          it { is_expected.to eq(commit) }
        end

        context 'when the diff has more than one commit' do
          before do
            create(:merge_request_diff_commit, merge_request_diff: merge_request_diff, sha: 'abc456')
            create(:merge_request_diff_commit, merge_request_diff: merge_request_diff, sha: 'abc123', relative_order: 1)
            merge_request_diff.save_git_content
          end

          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe '#commit_to_cherry_pick' do
    subject { merge_request.commit_to_cherry_pick }

    let(:merge_request) { build(:merge_request) }
    let(:commit_to_revert_result) { double }

    it 'delegates the call to #commit_to_revert' do
      expect(merge_request).to receive(:commit_to_revert).and_return(commit_to_revert_result)

      is_expected.to eq(commit_to_revert_result)
    end
  end

  describe '#default_squash_commit_message' do
    let(:default_squash_commit_message) { subject.default_squash_commit_message }

    it 'returns the merge request title' do
      expect(default_squash_commit_message).to eq(subject.title)
    end

    it 'uses template from target project' do
      subject.target_project.squash_commit_template = 'Squashed branch %{source_branch} into %{target_branch}'

      expect(default_squash_commit_message).to eq('Squashed branch master into feature')
    end

    context 'when squash commit message is empty after placeholders replacement' do
      before do
        subject.target_project.squash_commit_template = '%{approved_by}'
      end

      it 'returns the merge request title' do
        expect(default_squash_commit_message).to eq(subject.title)
      end
    end
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Issuable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(Taskable) }
    it { is_expected.to include_module(MilestoneEventable) }
    it { is_expected.to include_module(StateEventable) }

    it_behaves_like 'AtomicInternalId' do
      let(:internal_id_attribute) { :iid }
      let(:instance) { build(:merge_request) }
      let(:scope) { :target_project }
      let(:scope_attrs) { { project: instance.target_project } }
      let(:usage) { :merge_requests }
    end
  end

  describe 'validation' do
    subject { build_stubbed(:merge_request) }

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

    describe "#validate_reviewer_size_length" do
      let(:merge_request) { build(:merge_request, transitioning: transitioning) }

      where(:transitioning, :to_or_not_to) do
        false  | :to
        true   | :not_to
      end

      with_them do
        it do
          expect(merge_request).send(to_or_not_to, receive(:validate_reviewer_size_length))

          merge_request.valid?
        end
      end
    end

    describe '#validate_target_project' do
      let(:merge_request) do
        build(:merge_request, source_project: project, target_project: project, importing: importing)
      end

      let(:project) { build_stubbed(:project) }
      let(:importing) { false }

      context 'when projects #merge_requests_enabled? is true' do
        it { expect(merge_request.valid?(false)).to eq true }
      end

      context 'when projects #merge_requests_enabled? is false' do
        let(:project) { build_stubbed(:project, merge_requests_enabled: false) }

        it 'is invalid' do
          expect(merge_request.valid?(false)).to eq false
          expect(merge_request.errors.full_messages).to contain_exactly('Target project has disabled merge requests')
        end

        context 'when #import? is true' do
          let(:importing) { true }

          it { expect(merge_request.valid?(false)).to eq true }
        end
      end

      context "when transitioning between states" do
        let(:merge_request) { build(:merge_request, transitioning: transitioning) }

        where(:transitioning, :to_or_not_to) do
          false | :to
          true  | :not_to
        end

        with_them do
          it do
            expect(merge_request).send(to_or_not_to, receive(:validate_target_project))

            merge_request.valid?
          end
        end
      end
    end
  end

  describe 'callbacks' do
    describe '#ensure_merge_request_diff' do
      let(:merge_request) { build(:merge_request) }

      context 'when skip_ensure_merge_request_diff is true' do
        before do
          merge_request.skip_ensure_merge_request_diff = true
        end

        it 'does not create a merge_request_diff after create' do
          merge_request.save!

          expect(merge_request.merge_request_diff).to be_empty
        end
      end

      context 'when skip_ensure_merge_request_diff is false' do
        before do
          merge_request.skip_ensure_merge_request_diff = false
        end

        it 'creates merge_request_diff after create' do
          merge_request.save!

          expect(merge_request.merge_request_diff).not_to be_empty
        end
      end
    end

    describe '#ensure_merge_request_metrics' do
      let(:merge_request) { create(:merge_request) }

      it 'creates metrics after saving' do
        expect(merge_request.metrics).to be_persisted
        expect(MergeRequest::Metrics.count).to eq(1)
      end

      it 'does not duplicate metrics for a merge request' do
        merge_request.mark_as_merged!

        expect(MergeRequest::Metrics.count).to eq(1)
      end

      it 'does not create duplicated metrics records when MR is concurrently updated' do
        merge_request.metrics.destroy!

        instance1 = described_class.find(merge_request.id)
        instance2 = described_class.find(merge_request.id)

        instance1.ensure_metrics!
        instance2.ensure_metrics!

        metrics_records = MergeRequest::Metrics.where(merge_request_id: merge_request.id)
        expect(metrics_records.size).to eq(1)
      end

      it 'syncs the `target_project_id` to the metrics record' do
        project = create(:project)

        merge_request.update!(target_project: project, state: :closed)

        expect(merge_request.target_project_id).to eq(project.id)
        expect(merge_request.target_project_id).to eq(merge_request.metrics.target_project_id)
      end
    end

    describe '#set_draft_status' do
      let(:merge_request) { create(:merge_request) }

      context 'MR is a draft' do
        before do
          expect(merge_request.draft).to be_falsy

          merge_request.title = "Draft: #{merge_request.title}"
        end

        it 'sets draft to true' do
          merge_request.save!

          expect(merge_request.draft).to be_truthy
        end
      end

      context 'MR is not a draft' do
        before do
          expect(merge_request.draft).to be_falsey

          merge_request.title = "This is not a draft"
        end

        it 'sets draft to true' do
          merge_request.save!

          expect(merge_request.draft).to be_falsey
        end
      end
    end
  end

  describe 'respond to' do
    subject { build(:merge_request) }

    it { is_expected.to respond_to(:unchecked?) }
    it { is_expected.to respond_to(:checking?) }
    it { is_expected.to respond_to(:can_be_merged?) }
    it { is_expected.to respond_to(:cannot_be_merged?) }
    it { is_expected.to respond_to(:merge_params) }
    it { is_expected.to respond_to(:merge_when_pipeline_succeeds) }
  end

  describe '.by_commit_sha' do
    subject(:by_commit_sha) { described_class.by_commit_sha(sha) }

    let!(:merge_request) { create(:merge_request) }

    context 'with sha contained in latest merge request diff' do
      let(:sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }

      it 'returns merge requests' do
        expect(by_commit_sha).to eq([merge_request])
      end
    end

    context 'with sha contained not in latest merge request diff' do
      let(:sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }

      it 'returns empty requests' do
        latest_merge_request_diff = merge_request.merge_request_diffs.create!

        MergeRequestDiffCommit.where(
          merge_request_diff_id: latest_merge_request_diff,
          sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0'
        ).delete_all

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

  describe '.by_merged_commit_sha' do
    it 'returns merge requests that match the given merged commit' do
      mr = create(:merge_request, :merged, merged_commit_sha: '123abc')

      create(:merge_request, :merged, merged_commit_sha: '123def')

      expect(described_class.by_merged_commit_sha('123abc')).to eq([mr])
    end
  end

  describe '.by_merge_commit_sha' do
    it 'returns merge requests that match the given merge commit' do
      mr = create(:merge_request, :merged, merge_commit_sha: '123abc')

      create(:merge_request, :merged, merge_commit_sha: '123def')

      expect(described_class.by_merge_commit_sha('123abc')).to eq([mr])
    end
  end

  describe '.by_squash_commit_sha' do
    subject { described_class.by_squash_commit_sha(sha) }

    let(:sha) { '123abc' }
    let(:merge_request) { create(:merge_request, :merged, squash_commit_sha: sha) }

    it 'returns merge requests that match the given squash commit' do
      is_expected.to eq([merge_request])
    end
  end

  describe '.by_merged_or_merge_or_squash_commit_sha' do
    subject { described_class.by_merged_or_merge_or_squash_commit_sha([sha1, sha2, sha3]) }

    let(:sha1) { '123abc' }
    let(:sha2) { '456abc' }
    let(:sha3) { '111111' }
    let(:mr1) { create(:merge_request, :merged, squash_commit_sha: sha1) }
    let(:mr2) { create(:merge_request, :merged, merge_commit_sha: sha2) }
    let(:mr3) { create(:merge_request, :merged, merged_commit_sha: sha3) }

    it 'returns merge requests that match the given squash, merge and merged commits' do
      is_expected.to include(mr1, mr2, mr3)
    end
  end

  describe '.by_latest_merge_request_diffs' do
    let!(:merge_request) { create(:merge_request, merge_commit_sha: nil) }
    let!(:merge_request_diff) { create(:merge_request_diff, merge_request: merge_request) }

    subject(:by_latest_merge_request_diffs) { described_class.by_latest_merge_request_diffs(merge_request_diff_id) }

    context "when given merge_request_diff is the latest diff for the merge_request" do
      let(:merge_request_diff_id) { merge_request_diff.id }

      it 'returns merge request' do
        expect(by_latest_merge_request_diffs).to eq([merge_request])
      end
    end

    context "when given merge_request_diff is not the latest diff for the merge request" do
      let(:merge_request_diff_id) { merge_request_diff.id + 1 }

      it 'returns empty merge requests' do
        expect(by_latest_merge_request_diffs).to be_empty
      end
    end
  end

  describe '.join_metrics' do
    let_it_be(:join_condition) { '"merge_request_metrics"."target_project_id" = 1' }

    context 'when a no target_project_id is available' do
      it 'moves target_project_id condition to the merge request metrics' do
        expect(described_class.join_metrics(1).to_sql).to include(join_condition)
      end
    end

    context 'when a target_project_id is present in the where conditions' do
      it 'moves target_project_id condition to the merge request metrics' do
        expect(described_class.where(target_project_id: 1).join_metrics.to_sql).to include(join_condition)
      end
    end
  end

  describe '.by_related_commit_sha' do
    subject { described_class.by_related_commit_sha(sha) }

    context 'when commit is a squash commit' do
      let!(:merge_request) { create(:merge_request, :merged, squash_commit_sha: sha) }
      let(:sha) { '123abc' }

      it { is_expected.to eq([merge_request]) }
    end

    context 'when commit is a part of the merge request' do
      let!(:merge_request) { create(:merge_request) }
      let(:sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }

      it { is_expected.to eq([merge_request]) }
    end

    context 'when commit is a merge commit' do
      let!(:merge_request) { create(:merge_request, :merged, merge_commit_sha: sha) }
      let(:sha) { '123abc' }

      it { is_expected.to eq([merge_request]) }
    end

    context 'when commit is a rebased fast-forward commit' do
      let!(:merge_request) { create(:merge_request, :merged, merged_commit_sha: sha) }
      let(:sha) { '123abc' }

      it { is_expected.to eq([merge_request]) }
    end

    context 'when commit is not found' do
      let(:sha) { '0000' }

      it { is_expected.to be_empty }
    end

    context 'when commit is part of the merge request and a squash commit at the same time' do
      let!(:merge_request) { create(:merge_request) }
      let(:sha) { merge_request.commits.first.id }

      before do
        merge_request.update!(squash_commit_sha: sha)
      end

      it { is_expected.to eq([merge_request]) }
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
        diffs.times { mr.merge_request_diffs.create! }
        mr.create_merge_head_diff
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

  describe '.recent_target_branches and .recent_source_branches' do
    def create_mr(source_branch, target_branch, status, remove_source_branch = false)
      if remove_source_branch
        create(:merge_request, status, :remove_source_branch, source_project: project,
          target_branch: target_branch, source_branch: source_branch)
      else
        create(:merge_request, status, source_project: project,
          target_branch: target_branch, source_branch: source_branch)
      end
    end

    let(:project) { create(:project) }
    let!(:merge_request1) { create_mr('source1', 'target1', :opened) }
    let!(:merge_request2) { create_mr('source2', 'target2', :closed) }
    let!(:merge_request3) { create_mr('source3', 'target3', :opened) }
    let!(:merge_request4) { create_mr('source4', 'target1', :closed) }
    let!(:merge_request5) { create_mr('source5', 'target4', :merged, true) }

    before do
      merge_request1.update_columns(updated_at: 1.day.since)
      merge_request2.update_columns(updated_at: 2.days.since)
      merge_request3.update_columns(updated_at: 3.days.since)
      merge_request4.update_columns(updated_at: 4.days.since)
      merge_request5.update_columns(updated_at: 5.days.since)
    end

    it 'returns branches sort by updated at desc' do
      expect(described_class.recent_target_branches).to match_array(%w[target1 target2 target3 target4])
      expect(described_class.recent_source_branches).to match_array(%w[source1 source2 source3 source4 source5])
    end
  end

  describe '.sort_by_attribute' do
    context 'merged_at' do
      let_it_be(:older_mr) { create(:merge_request, :with_merged_metrics) }
      let_it_be(:newer_mr) { create(:merge_request, :with_merged_metrics) }

      it 'sorts asc' do
        merge_requests = described_class.sort_by_attribute(:merged_at_asc)
        expect(merge_requests).to eq([older_mr, newer_mr])
      end

      it 'sorts desc' do
        merge_requests = described_class.sort_by_attribute(:merged_at_desc)
        expect(merge_requests).to eq([newer_mr, older_mr])
      end
    end

    context 'closed_at' do
      let_it_be(:older_mr) { create(:merge_request, :closed_last_month) }
      let_it_be(:newer_mr) { create(:merge_request, :closed_last_month) }

      it 'sorts asc' do
        merge_requests = described_class.sort_by_attribute(:closed_at_asc)
        expect(merge_requests).to eq([older_mr, newer_mr])
      end

      it 'sorts desc' do
        merge_requests = described_class.sort_by_attribute(:closed_at_desc)
        expect(merge_requests).to eq([newer_mr, older_mr])
      end

      it 'sorts asc when its closed_at' do
        merge_requests = described_class.sort_by_attribute(:closed_at)
        expect(merge_requests).to eq([older_mr, newer_mr])
      end
    end

    context 'title' do
      let_it_be(:first_mr) { create(:merge_request, :closed, title: 'One') }
      let_it_be(:second_mr) { create(:merge_request, :closed, title: 'Two') }

      it 'sorts asc' do
        merge_requests = described_class.sort_by_attribute(:title_asc)
        expect(merge_requests).to eq([first_mr, second_mr])
      end

      it 'sorts desc' do
        merge_requests = described_class.sort_by_attribute(:title_desc)
        expect(merge_requests).to eq([second_mr, first_mr])
      end
    end
  end

  describe 'time to merge calculations' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let!(:mr1) do
      create(
        :merge_request,
        :with_merged_metrics,
        source_project: project,
        target_project: project
      )
    end

    let!(:mr2) do
      create(
        :merge_request,
        :with_merged_metrics,
        source_project: project,
        target_project: project
      )
    end

    let!(:mr3) do
      create(
        :merge_request,
        :with_merged_metrics,
        source_project: project,
        target_project: project
      )
    end

    let!(:unmerged_mr) do
      create(
        :merge_request,
        source_project: project,
        target_project: project
      )
    end

    before do
      project.add_member(user, :developer)
    end

    describe '.total_time_to_merge' do
      it 'returns the sum of the time to merge for all merged MRs' do
        mrs = project.merge_requests

        expect(mrs.total_time_to_merge).to be_within(1).of(expected_total_time(mrs))
      end

      context 'when merged_at is earlier than created_at' do
        before do
          mr1.metrics.update!(merged_at: mr1.metrics.created_at - 1.week)
        end

        it 'returns nil' do
          mrs = project.merge_requests.where(id: mr1.id)

          expect(mrs.total_time_to_merge).to be_nil
        end
      end

      context 'when scoped with :merged_before and :merged_after' do
        before do
          mr2.metrics.update!(merged_at: mr1.metrics.merged_at - 1.week)
          mr3.metrics.update!(merged_at: mr1.metrics.merged_at + 1.week)
        end

        it 'excludes merge requests outside of the date range' do
          expect(
            project.merge_requests.merge(
              MergeRequest::Metrics
                .merged_before(mr1.metrics.merged_at + 1.day)
                .merged_after(mr1.metrics.merged_at - 1.day)
            ).total_time_to_merge
          ).to be_within(1).of(expected_total_time([mr1]))
        end
      end

      def expected_total_time(mrs)
        mrs = mrs.reject { |mr| mr.merged_at.nil? }
        mrs.reduce(0.0) do |sum, mr|
          (mr.merged_at - mr.created_at) + sum
        end
      end
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
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project_without_auto_close) { create(:project, :public, group: group, autoclose_referenced_issues: false) }
    let_it_be(:group_issue) { create(:issue, :group_level, namespace: group) }
    let_it_be(:no_close_issue) { create(:issue, project: project_without_auto_close) }
    let(:guest) { create(:user) }
    let(:developer) { create(:user) }
    let(:issue_1) { create(:issue, project: subject.source_project) }
    let(:issue_2) { create(:issue, project: subject.source_project) }
    let(:confidential_issue) { create(:issue, :confidential, project: subject.source_project) }

    before do
      group.add_developer(subject.author) # rubocop:disable RSpec/BeforeAllRoleAssignment -- Subject can't be referenced in a before context
      subject.project.add_developer(subject.author)
      subject.target_branch = subject.project.default_branch
      commit = double(
        'commit1',
        safe_message: "Fixes #{issue_1.to_reference} #{issue_2.to_reference} #{confidential_issue.to_reference} " \
          "Closes #{group_issue.to_reference(full: true)} Closes #{no_close_issue.to_reference(full: true)}"
      )
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
      let(:project) { create(:project, :repository) }

      subject { create(:merge_request, source_project: project) }

      before do
        subject.project.has_external_issue_tracker = true
        subject.project.save!
      end

      it 'calls non #closes_issues to retrieve data' do
        expect(subject).to receive(:closes_issues).and_call_original
        expect(subject).not_to receive(:cached_closes_issues)

        subject.visible_closing_issues_for
      end
    end
  end

  describe '#related_issues' do
    subject(:related_issues) { merge_request.related_issues(user) }

    let_it_be(:issue_referenced_in_mr_title) { create(:issue) }
    let_it_be(:issue_referenced_in_mr_desc) { create(:issue) }
    let_it_be(:issue_referenced_in_mr_commit_msg) { create(:issue) }
    let_it_be(:issue_referenced_in_mr_note) { create(:issue) }
    let_it_be(:issue_referenced_in_internal_mr_note) { create(:issue) }
    let_it_be(:confidential_issue_in_mr_desc) { create(:issue, :confidential) }

    let_it_be(:merge_request) do
      create(
        :merge_request,
        title: "MR for #{issue_referenced_in_mr_title.to_reference}",
        description: "Fix #{issue_referenced_in_mr_desc.to_reference}, #{confidential_issue_in_mr_desc.to_reference}"
      )
    end

    before do
      commit_stub = double('commit1', safe_message: "Fixes #{issue_referenced_in_mr_commit_msg.to_reference}")
      allow(merge_request).to receive(:commits).and_return([commit_stub])

      create(:note, noteable: merge_request, note: "See #{issue_referenced_in_mr_note.to_reference}")
      create(:note, :internal, noteable: merge_request, note: issue_referenced_in_internal_mr_note.to_reference)
    end

    context 'for guest' do
      let_it_be(:user) { create(:user, guest_of: project) }

      it 'returns authorized related issues' do
        expect(related_issues).to contain_exactly(
          issue_referenced_in_mr_title,
          issue_referenced_in_mr_desc,
          issue_referenced_in_mr_note,
          issue_referenced_in_mr_commit_msg
        )
      end
    end

    context 'for developer' do
      let_it_be(:user) { create(:user, developer_of: project) }

      it 'returns authorized related issues' do
        expect(related_issues).to contain_exactly(
          issue_referenced_in_mr_title,
          issue_referenced_in_mr_desc,
          confidential_issue_in_mr_desc,
          issue_referenced_in_mr_note,
          issue_referenced_in_internal_mr_note,
          issue_referenced_in_mr_commit_msg
        )
      end
    end
  end

  describe '#cache_merge_request_closes_issues!', :aggregate_failures do
    let_it_be_with_reload(:issue) { create(:issue, project: project) }

    before do
      project.add_developer(subject.author)
      subject.target_branch = subject.project.default_branch
    end

    it 'caches closed issues' do
      commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
      allow(subject).to receive(:commits).and_return([commit])

      expect { subject.cache_merge_request_closes_issues!(subject.author) }.to change(subject.merge_requests_closing_issues, :count).by(1)
      expect(subject.merge_requests_closing_issues.last).to have_attributes(
        issue: issue,
        merge_request_id: subject.id,
        from_mr_description: true
      )
    end

    it 'works with work item references', :aggregate_failures do
      work_item_url = Gitlab::Routing.url_helpers.project_work_item_url(issue.project, issue)
      commit = double('commit1', safe_message: "Fixes #{work_item_url}")
      allow(subject).to receive(:commits).and_return([commit])

      expect { subject.cache_merge_request_closes_issues!(subject.author) }.to change {
        subject.merge_requests_closing_issues.count
      }.by(1)
      expect(subject.merge_requests_closing_issues.last).to have_attributes(
        issue: issue,
        merge_request_id: subject.id,
        from_mr_description: true
      )
    end

    it 'updates existing records if they were not created from MR description' do
      existing_association = create(
        :merge_requests_closing_issues,
        issue: issue,
        merge_request: subject,
        from_mr_description: false
      )

      expect do
        subject.update_columns(description: "Fixes #{issue.to_reference}")
        subject.cache_merge_request_closes_issues!(subject.author)
      end.to not_change { subject.merge_requests_closing_issues.count }.from(1).and(
        change { existing_association.reload.from_mr_description }.from(false).to(true)
      )
    end

    it 'does not cache closed issues when merge request is closed' do
      commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")

      allow(subject).to receive(:commits).and_return([commit])
      allow(subject).to receive(:state_id).and_return(described_class.available_states[:closed])

      expect { subject.cache_merge_request_closes_issues!(subject.author) }.not_to change(subject.merge_requests_closing_issues, :count)
    end

    it 'does not cache closed issues when merge request is merged' do
      commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
      allow(subject).to receive(:commits).and_return([commit])
      allow(subject).to receive(:state_id).and_return(described_class.available_states[:merged])

      expect { subject.cache_merge_request_closes_issues!(subject.author) }.not_to change(subject.merge_requests_closing_issues, :count)
    end

    context 'when both internal and external issue trackers are enabled' do
      before do
        create(:jira_integration, project: subject.project)
        subject.project.reload
      end

      it 'does not cache issues from external trackers' do
        issue  = ExternalIssue.new('JIRA-123', subject.project)
        commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
        allow(subject).to receive(:commits).and_return([commit])

        expect { subject.cache_merge_request_closes_issues!(subject.author) }.not_to raise_error
        expect { subject.cache_merge_request_closes_issues!(subject.author) }.not_to change(subject.merge_requests_closing_issues, :count)
      end

      it 'caches an internal issue' do
        commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
        allow(subject).to receive(:commits).and_return([commit])

        expect { subject.cache_merge_request_closes_issues!(subject.author) }
          .to change(subject.merge_requests_closing_issues, :count).by(1)
      end
    end

    context 'when only external issue tracker enabled' do
      let(:project) { create(:project, :repository) }

      subject { create(:merge_request, source_project: project) }

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
        commit = double('commit1', safe_message: "Fixes #{issue.to_reference}")
        allow(subject).to receive(:commits).and_return([commit])

        expect { subject.cache_merge_request_closes_issues!(subject.author) }
          .not_to change(subject.merge_requests_closing_issues, :count)
      end

      it 'caches issues from another project with issues enabled even if autoclose_referenced_issues is disabled' do
        project = create(:project, :public, issues_enabled: true, autoclose_referenced_issues: false)
        issue = create(:issue, project: project)
        commit = double('commit1', safe_message: "Fixes #{issue.to_reference(full: true)}")
        allow(subject).to receive(:commits).and_return([commit])

        expect { subject.cache_merge_request_closes_issues!(subject.author) }
          .to change(subject.merge_requests_closing_issues, :count).by(1)
      end
    end
  end

  describe '#source_branch_sha' do
    let(:last_branch_commit) { subject.source_project.repository.commit(Gitlab::Git::BRANCH_REF_PREFIX + subject.source_branch) }

    context 'with diffs' do
      subject { create(:merge_request) }

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
          subject.source_project.repository.add_tag(
            subject.author,
            tag_name,
            subject.target_branch_sha,
            'Add a tag'
          )

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
    let(:project) { build(:project) }
    let(:merge_request) { build(:merge_request, target_project: project, iid: 1) }

    it 'returns a String reference to the object' do
      expect(merge_request.to_reference).to eq "!1"
    end

    it 'supports a cross-project reference' do
      another_project = build(:project, namespace: project.namespace)
      expect(merge_request.to_reference(another_project)).to eq "#{project.path}!1"
    end

    it 'returns a String reference with the full path' do
      expect(merge_request.to_reference(full: true)).to eq("#{project.full_path}!1")
    end
  end

  describe '#raw_diffs' do
    let(:options) { { paths: ['a/b', 'b/a', 'c/*'] } }

    context 'when there are MR diffs' do
      let(:merge_request) { create(:merge_request) }

      it 'delegates to the MR diffs' do
        expect(merge_request.merge_request_diff).to receive(:raw_diffs).with(options)

        merge_request.raw_diffs(options)
      end
    end

    context 'when there are no MR diffs' do
      let(:merge_request) { build(:merge_request) }

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
        merge_request.save!

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
    let(:user) { create(:user) }
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.project }
    let!(:diff_note) do
      create(:diff_note_on_merge_request, project: project, noteable: merge_request)
    end

    let!(:draft_note) do
      create(:draft_note_on_text_diff, author: user, merge_request: merge_request)
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

    context 'when user is given' do
      subject do
        merge_request.note_positions_for_paths(file_paths, user)
      end

      it 'returns notes and draft notes positions' do
        expect(subject).to match_array([draft_note.position, diff_note.position])
      end
    end

    context 'when user is not given' do
      subject do
        merge_request.note_positions_for_paths(file_paths)
      end

      it 'returns notes positions' do
        expect(subject).to match_array([diff_note.position])
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
      let(:other_merge_request) { create(:merge_request, source_project: create(:project, :repository)) }

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
    let_it_be(:project) { create(:project, :repository) }

    let(:merge_request) do
      build(:merge_request, source_project: project, source_branch: 'expand-collapse-files', target_branch: 'master')
    end

    context 'when there are MR diffs' do
      it 'returns the correct count' do
        merge_request.save!

        expect(merge_request.diff_size).to eq('105')
      end

      it 'returns the correct overflow count' do
        allow(Commit).to receive(:max_diff_options).and_return(max_files: 2)
        merge_request.save!

        expect(merge_request.diff_size).to eq('2+')
      end

      it 'does not perform highlighting' do
        merge_request.save!

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
        allow(Commit).to receive(:diff_max_files).and_return(2)
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
      allow(diff).to receive(:modified_paths).and_return(paths)
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

      before do
        merge_request.compare = compare

        expect(merge_request).to receive(:diff_stats).and_return(diff_stats)
      end

      context 'and diff_stats are not present' do
        let(:diff_stats) { nil }

        it 'returns affected file paths from compare' do
          expect(merge_request.modified_paths).to eq(paths)
        end
      end

      context 'and diff_stats are present' do
        let(:diff_stats) { double(:diff_stats) }

        it 'returns affected file paths from compare' do
          diff_stats_path = double(:diff_stats_paths)
          expect(diff_stats).to receive(:paths).and_return(diff_stats_path)

          expect(merge_request.modified_paths).to eq(diff_stats_path)
        end
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

  describe '#changed_paths' do
    let(:commits) { [double(:commit)] }
    let(:changed_paths) { [double(:changed_path, path: 'path.rb')] }
    let(:merge_request) { build(:merge_request, id: 1, project: project) }

    before do
      allow(merge_request).to receive(:commits).and_return(commits)
    end

    it 'fetches the changed paths from gitaly' do
      expect(project.repository)
        .to receive(:find_changed_paths).with(commits, merge_commit_diff_mode: :all_parents)
        .once.and_return(changed_paths)
      expect(merge_request.changed_paths).to eq(changed_paths)
    end

    it 'uses a cache', :request_store do
      expect(project.repository).to receive(:find_changed_paths).once

      2.times { merge_request.changed_paths }
    end

    it 'uses a different cache for different MRs', :request_store do
      merge_request_2 = build(:merge_request, id: 2, project: project)
      expect(project.repository).to receive(:find_changed_paths).twice
      merge_request.changed_paths
      merge_request_2.changed_paths
    end

    it 'invalidates the cache when the diff_head_sha changes', :request_store do
      expect(project.repository).to receive(:find_changed_paths).twice

      2.times { merge_request.changed_paths }

      allow(merge_request).to receive(:diff_head_sha).and_return('new_sha')

      2.times { merge_request.changed_paths }
    end
  end

  describe '#new_paths' do
    let(:merge_request) do
      create(:merge_request, source_branch: 'expand-collapse-files', target_branch: 'master')
    end

    it 'returns new path of changed files' do
      expect(merge_request.new_paths.count).to eq(105)
    end
  end

  describe "#related_notes" do
    let!(:merge_request) { create(:merge_request) }

    before do
      allow(merge_request).to receive(:commits) { [merge_request.source_project.repository.commit] }
      create(:note_on_commit, commit_id: merge_request.commits.first.id, project: merge_request.project)
      create(:note, noteable: merge_request, project: merge_request.project)
    end

    it "includes notes for commits" do
      expect(merge_request.commits).not_to be_empty
      expect(merge_request.related_notes.count).to eq(2)
    end

    it "includes notes for commits from target project as well" do
      create(:note_on_commit, commit_id: merge_request.commits.first.id, project: merge_request.target_project)

      expect(merge_request.commits).not_to be_empty
      expect(merge_request.related_notes.count).to eq(3)
    end

    it "excludes system notes for commits" do
      system_note = create(
        :note_on_commit,
        :system,
        commit_id: merge_request.commits.first.id,
        project: merge_request.project
      )

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
    let(:project) { create(:project) }

    let(:issue0) { create :issue, project: subject.project }
    let(:issue1) { create :issue, project: subject.project }

    let(:commit0) { double('commit0', safe_message: "Fixes #{issue0.to_reference}") }
    let(:commit1) { double('commit1', safe_message: "Fixes #{issue0.to_reference}") }
    let(:commit2) { double('commit2', safe_message: "Fixes #{issue1.to_reference}") }

    subject { create(:merge_request, source_project: project) }

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

    it 'does not ignore referenced issues when auto-close is disabled' do
      subject.project.update!(autoclose_referenced_issues: false)

      allow(subject.project).to receive(:default_branch)
        .and_return(subject.target_branch)

      expect(subject.closes_issues).to contain_exactly(issue0, issue1)
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

        create(:jira_integration, project: subject.project)
        subject.project.reload

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

  describe "#draft?" do
    subject { build_stubbed(:merge_request) }

    [
      'draft:', 'Draft: ', '[Draft]', '[DRAFT] '
    ].each do |draft_prefix|
      it "detects the '#{draft_prefix}' prefix" do
        subject.title = "#{draft_prefix}#{subject.title}"

        expect(subject.draft?).to eq true
      end
    end

    context "returns false" do
      # We have removed support for variations of "WIP", and additionally need
      #   to test unsupported variations of "Draft" that we have seen users
      #   attempt.
      #
      [
        'WIP:', 'WIP: ', '[WIP]', '[WIP] ', ' [WIP] WIP: [WIP] WIP:',
        "WIP ", "(WIP)",
        "draft", "Draft", "Draft -", "draft - ", "Draft ", "draft "
      ].each do |trigger|
        it "when '#{trigger}' prefixes the title" do
          subject.title = "#{trigger}#{subject.title}"

          expect(subject.draft?).to eq false
        end
      end

      ["WIP", "Draft"].each do |trigger| # rubocop:disable Style/WordArray
        it "when merge request title is simply '#{trigger}'" do
          subject.title = trigger

          expect(subject.draft?).to eq false
        end

        it "when #{trigger} is in the middle of the title" do
          subject.title = "Something with #{trigger} in the middle"

          expect(subject.draft?).to eq false
        end

        it "when #{trigger} is at the end of the title" do
          subject.title = "Something ends with #{trigger}"

          expect(subject.draft?).to eq false
        end

        it "when title contains words starting with #{trigger}" do
          subject.title = "#{trigger}foo #{subject.title}"

          expect(subject.draft?).to eq false
        end

        it "when title contains words containing with #{trigger}" do
          subject.title = "Foo#{trigger}Bar #{subject.title}"

          expect(subject.draft?).to eq false
        end
      end

      it 'when Draft: in the middle of the title' do
        subject.title = 'Something with Draft: in the middle'

        expect(subject.draft?).to eq false
      end

      it "when the title does not contain draft" do
        expect(subject.draft?).to eq false
      end

      it "is aliased to #draft?" do
        expect(subject.method(:work_in_progress?)).to eq(subject.method(:draft?))
      end
    end
  end

  describe "#draftless_title" do
    subject { build_stubbed(:merge_request) }

    ['draft:', 'Draft: ', '[Draft]', '[DRAFT] '].each do |draft_prefix|
      it "removes a '#{draft_prefix}' prefix" do
        draftless_title = subject.title
        subject.title = "#{draft_prefix}#{subject.title}"

        expect(subject.draftless_title).to eq draftless_title
      end

      it "is satisfies the #work_in_progress? method" do
        subject.title = "#{draft_prefix}#{subject.title}"
        subject.title = subject.draftless_title

        expect(subject.work_in_progress?).to eq false
      end
    end

    [
      'WIP:', 'WIP: ', '[WIP]', '[WIP] ', '[WIP] WIP: [WIP] WIP:'
    ].each do |wip_prefix|
      it "doesn't remove a '#{wip_prefix}' prefix" do
        subject.title = "#{wip_prefix}#{subject.title}"

        expect(subject.draftless_title).to eq subject.title
      end
    end

    it 'removes only draft prefix from the MR title' do
      subject.title = 'Draft: Implement feature called draft'

      expect(subject.draftless_title).to eq 'Implement feature called draft'
    end

    it 'does not remove WIP in the middle of the title' do
      subject.title = 'Something with WIP in the middle'

      expect(subject.draftless_title).to eq subject.title
    end

    it 'does not remove Draft in the middle of the title' do
      subject.title = 'Something with Draft in the middle'

      expect(subject.draftless_title).to eq subject.title
    end

    it 'does not remove WIP at the end of the title' do
      subject.title = 'Something ends with WIP'

      expect(subject.draftless_title).to eq subject.title
    end

    it 'does not remove Draft at the end of the title' do
      subject.title = 'Something ends with Draft'

      expect(subject.draftless_title).to eq subject.title
    end
  end

  describe "#draft_title" do
    it "adds the Draft: prefix to the title" do
      draft_title = "Draft: #{subject.title}"

      expect(subject.draft_title).to eq draft_title
    end

    it "does not add the Draft: prefix multiple times" do
      draft_title = "Draft: #{subject.title}"
      subject.title = subject.draft_title
      subject.title = subject.draft_title

      expect(subject.draft_title).to eq draft_title
    end

    it "is satisfies the #work_in_progress? method" do
      subject.title = subject.draft_title

      expect(subject.work_in_progress?).to eq true
    end
  end

  describe '#permits_force_push?' do
    let_it_be(:merge_request) { build_stubbed(:merge_request) }

    subject { merge_request.permits_force_push? }

    context 'when source branch is not protected' do
      before do
        allow(ProtectedBranch).to receive(:protected?).and_return(false)
      end

      it { is_expected.to be_truthy }
    end

    context 'when source branch is protected' do
      before do
        allow(ProtectedBranch).to receive(:protected?).and_return(true)
      end

      context 'when force push is not allowed' do
        before do
          allow(ProtectedBranch).to receive(:allow_force_push?) { false }
        end

        it { is_expected.to be_falsey }
      end

      context 'when force push is allowed' do
        before do
          allow(ProtectedBranch).to receive(:allow_force_push?) { true }
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#can_remove_source_branch?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:merge_request, reload: true) { create(:merge_request, :simple) }

    subject { merge_request }

    before do
      subject.source_project.add_maintainer(user)
    end

    it "can't be removed when its a protected branch" do
      allow(ProtectedBranch).to receive(:protected?).and_return(true)

      expect(subject.can_remove_source_branch?(user)).to be_falsey
    end

    it "can't be removed because source project has been deleted" do
      subject.source_project = nil

      expect(subject.can_remove_source_branch?(user)).to be_falsey
    end

    it "can't remove a root ref" do
      subject.update!(source_branch: 'master', target_branch: 'feature')

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

  describe "#source_branch_exists?" do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:repository) { merge_request.source_project.repository }

    context 'when the source project is set' do
      it 'returns true when the branch exists' do
        expect(merge_request.source_branch_exists?).to eq(true)
      end
    end

    context 'when the source project is not set' do
      before do
        merge_request.source_project = nil
      end

      it 'returns false' do
        expect(merge_request.source_branch_exists?).to eq(false)
      end
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

    it 'uses template from target project' do
      request = build(:merge_request, title: 'Fix everything')
      request.target_project.merge_commit_template = '%{title}'

      expect(request.default_merge_commit_message)
        .to eq('Fix everything')
    end

    it 'ignores template when include_description is true' do
      request = build(:merge_request, title: 'Fix everything')
      subject.target_project.merge_commit_template = '%{title}'

      expect(request.default_merge_commit_message(include_description: true))
        .to match("See merge request #{request.to_reference(full: true)}")
    end
  end

  describe "#auto_merge_strategy" do
    subject { merge_request.auto_merge_strategy }

    let(:merge_request) { create(:merge_request, :merge_when_checks_pass) }

    it { is_expected.to eq('merge_when_checks_pass') }

    context 'when auto merge is disabled' do
      let(:merge_request) { create(:merge_request) }

      it { is_expected.to be_nil }
    end
  end

  describe '#default_auto_merge_strategy' do
    subject { merge_request.default_auto_merge_strategy }

    let(:merge_request) { create(:merge_request, :merge_when_checks_pass) }

    it { is_expected.to eq(AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS) }
  end

  describe '#committers' do
    let(:commits) { double }
    let(:committers) { double }

    context 'when not given with_merge_commits, lazy and include_author_when_signed' do
      it 'calls committers on the commits object with the expected param' do
        expect(subject).to receive(:commits).and_return(commits)

        expect(commits)
          .to receive(:committers)
          .with(
            with_merge_commits: false,
            lazy: false,
            include_author_when_signed: false
          )
          .and_return(committers)

        expect(subject.committers).to eq(committers)
      end

      context 'when with_merge_commits, lazy and include_author_when_signed arguments changes' do
        it 'does not use memoized value' do
          subject.committers # this memoizes the value with with_merge_commits and lazy as false

          expect(subject).to receive(:commits).and_return(commits)

          expect(commits)
            .to receive(:committers)
            .with(
              with_merge_commits: true,
              lazy: true,
              include_author_when_signed: true
            )
            .and_return(committers)

          subject.committers(with_merge_commits: true, lazy: true, include_author_when_signed: true)
        end
      end
    end

    context 'when given with_merge_commits true' do
      it 'calls committers on the commits object with the expected param' do
        expect(subject).to receive(:commits).and_return(commits)

        expect(commits)
          .to receive(:committers)
          .with(
            with_merge_commits: true,
            lazy: false,
            include_author_when_signed: false
          )
          .and_return(committers)

        expect(subject.committers(with_merge_commits: true)).to eq(committers)
      end
    end

    context 'when given lazy true' do
      it 'calls committers on the commits object with the expected param' do
        expect(subject).to receive(:commits).and_return(commits)

        expect(commits)
          .to receive(:committers)
          .with(
            with_merge_commits: false,
            lazy: true,
            include_author_when_signed: false
          )
          .and_return(committers)

        expect(subject.committers(lazy: true)).to eq(committers)
      end
    end

    context 'when given include_author_when_signed true' do
      it 'calls committers on the commits object with the expected param' do
        expect(subject).to receive(:commits).and_return(commits)

        expect(commits)
          .to receive(:committers)
          .with(
            with_merge_commits: false,
            lazy: false,
            include_author_when_signed: true
          )
          .and_return(committers)

        expect(subject.committers(include_author_when_signed: true)).to eq(committers)
      end
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

  it_behaves_like 'a time trackable' do
    let(:trackable) { create(:merge_request, :simple, source_project: create(:project, :repository)) }
    let(:timelog) { create(:merge_request_timelog, merge_request: trackable) }
  end

  it_behaves_like 'an editable mentionable' do
    subject { create(:merge_request, :simple, source_project: create(:project, :repository)) }

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
          expect(subject.commit_shas(limit: 2)).to eq(
            %w[b83d6e391c22777fca1ed3012fce84f633d7fed0 498214de67004b1da3d820901307bed2a68a8ef6])
        end
      end

      context 'without a limit' do
        it 'returns all commit shas of the merge request diff' do
          expect(subject.commit_shas.size).to eq(29)
        end
      end
    end

    context 'new merge request' do
      let_it_be(:project) { create(:project, :repository) }

      subject { build(:merge_request, source_project: project) }

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

    describe '#diff_head_pipeline' do
      it 'returns nil for MR with old pipeline' do
        pipeline = create(:ci_empty_pipeline, sha: 'notlatestsha')
        subject.update_attribute(:head_pipeline_id, pipeline.id)

        expect(subject.diff_head_pipeline).to be_nil
      end

      it 'returns the pipeline for MR with recent pipeline' do
        pipeline = create(:ci_empty_pipeline, sha: diff_head_sha)
        subject.update_attribute(:head_pipeline_id, pipeline.id)

        expect(subject.diff_head_pipeline).to eq(subject.head_pipeline)
        expect(subject.diff_head_pipeline).to eq(pipeline)
      end

      it 'returns the pipeline for MR with recent merge request pipeline' do
        pipeline = create(:ci_empty_pipeline, sha: 'merge-sha', source_sha: diff_head_sha)
        subject.update_attribute(:head_pipeline_id, pipeline.id)

        expect(subject.diff_head_pipeline).to eq(subject.head_pipeline)
        expect(subject.diff_head_pipeline).to eq(pipeline)
      end

      it 'returns nil when source project does not exist' do
        allow(subject).to receive(:source_project).and_return(nil)

        expect(subject.diff_head_pipeline).to be_nil
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
      end

      context 'and merged_commit_sha is present' do
        before do
          subject.update_attribute(:merged_commit_sha, pipeline.sha)
        end

        it 'returns the pipeline associated with that merge request' do
          expect(subject.merge_pipeline).to eq(pipeline)
        end
      end

      context 'and there is a merge commit' do
        before do
          subject.update_attribute(:merge_commit_sha, pipeline.sha)
        end

        it 'returns the pipeline associated with that merge request' do
          expect(subject.merge_pipeline).to eq(pipeline)
        end
      end

      context 'and there is no merge commit, but there is a diff head' do
        before do
          allow(subject).to receive(:diff_head_sha).and_return(pipeline.sha)
        end

        it 'returns the pipeline associated with that merge request' do
          expect(subject.merge_pipeline).to eq(pipeline)
        end
      end

      context 'and there is no merge commit, but there is a squash commit' do
        before do
          subject.update_attribute(:squash_commit_sha, pipeline.sha)
        end

        it 'returns the pipeline associated with that merge request' do
          expect(subject.merge_pipeline).to eq(pipeline)
        end
      end
    end
  end

  describe '#has_ci?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    context 'has ci' do
      it 'returns true if MR has head_pipeline_id and commits' do
        allow(merge_request).to receive_message_chain(:source_project, :ci_integration) { nil }
        allow(merge_request).to receive(:head_pipeline_id) { double }
        allow(merge_request).to receive(:has_no_commits?) { false }

        expect(merge_request.has_ci?).to be(true)
      end

      it 'returns true if MR has any pipeline and commits' do
        allow(merge_request).to receive_message_chain(:source_project, :ci_integration) { nil }
        allow(merge_request).to receive(:head_pipeline_id) { nil }
        allow(merge_request).to receive(:has_no_commits?) { false }
        allow(merge_request).to receive(:all_pipelines) { [double] }

        expect(merge_request.has_ci?).to be(true)
      end

      it 'returns true if MR has CI integration and commits' do
        allow(merge_request).to receive_message_chain(:source_project, :ci_integration) { double }
        allow(merge_request).to receive(:head_pipeline_id) { nil }
        allow(merge_request).to receive(:has_no_commits?) { false }
        allow(merge_request).to receive(:all_pipelines) { [] }

        expect(merge_request.has_ci?).to be(true)
      end
    end

    context 'has no ci' do
      it 'returns false if MR has no CI integration nor pipeline, and no commits' do
        allow(merge_request).to receive_message_chain(:source_project, :ci_integration) { nil }
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
        create(
          :ci_empty_pipeline,
          project: merge_request.project,
          sha: merge_request.diff_head_sha,
          ref: merge_request.source_branch
        )
      end

      it 'updates the head pipeline' do
        expect { subject }
          .to change { merge_request.reload.head_pipeline }
          .from(nil).to(pipeline)
      end

      context 'when MR was retargeted' do
        before do
          merge_request.update!(retargeted: true)
        end

        it 'sets retargeted to false' do
          expect { subject }
            .to change { merge_request.reload.retargeted }
            .from(true).to(false)
        end
      end

      context 'when merge request has already had head pipeline' do
        before do
          merge_request.update!(head_pipeline: pipeline)
        end

        context 'when failed to find an actual head pipeline' do
          before do
            allow(merge_request).to receive(:find_diff_head_pipeline) {}
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
        create(
          :ci_pipeline,
          source: :merge_request_event,
          project: merge_request.source_project,
          ref: merge_request.ref_path,
          sha: sha,
          merge_request: merge_request
        )
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

    context 'when head pipeline has test reports' do
      let(:merge_request) { create(:merge_request, :with_test_reports) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have test reports' do
      let(:merge_request) { create(:merge_request) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_accessibility_reports?' do
    subject { merge_request.has_accessibility_reports? }

    context 'when head pipeline has an accessibility reports' do
      let(:merge_request) { create(:merge_request, :with_accessibility_reports) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have accessibility reports' do
      let(:merge_request) { create(:merge_request) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_coverage_reports?' do
    subject { merge_request.has_coverage_reports? }

    context 'when head pipeline has coverage reports' do
      let(:merge_request) { create(:merge_request, :with_coverage_reports) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have coverage reports' do
      let(:merge_request) { create(:merge_request) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_codequality_mr_diff_report?' do
    subject { merge_request.has_codequality_mr_diff_report? }

    context 'when head pipeline has codequality mr diff report' do
      let(:merge_request) { create(:merge_request, :with_codequality_mr_diff_reports) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have codeqquality mr diff report' do
      let(:merge_request) { create(:merge_request) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_codequality_reports?' do
    subject { merge_request.has_codequality_reports? }

    let(:project) { create(:project, :repository) }

    context 'when head pipeline has a codequality report' do
      let(:merge_request) { create(:merge_request, :with_codequality_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have a codequality report' do
      let(:merge_request) { create(:merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_terraform_reports?' do
    context 'when head pipeline has terraform reports' do
      it 'returns true' do
        merge_request = create(:merge_request, :with_terraform_reports)

        expect(merge_request.has_terraform_reports?).to be_truthy
      end
    end

    context 'when head pipeline does not have terraform reports' do
      it 'returns false' do
        merge_request = create(:merge_request)

        expect(merge_request.has_terraform_reports?).to be_falsey
      end
    end

    context 'when head pipeline is not finished and has terraform reports' do
      before do
        stub_feature_flags(mr_show_reports_immediately: false)
      end

      it 'returns true' do
        merge_request = create(:merge_request, :with_terraform_reports)
        merge_request.diff_head_pipeline.update!(status: :running)

        expect(merge_request.has_terraform_reports?).to be_truthy
      end
    end
  end

  describe '#has_sast_reports?' do
    subject { merge_request.has_sast_reports? }

    let(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(sast: true)
    end

    context 'when head pipeline has sast reports' do
      let(:merge_request) { create(:merge_request, :with_sast_reports, source_project: project) }

      it { is_expected.to be_truthy }

      context 'when head pipeline is blocked by manual jobs' do
        before do
          merge_request.diff_head_pipeline.block!
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when head pipeline does not have sast reports' do
      let(:merge_request) { create(:merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_secret_detection_reports?' do
    subject { merge_request.has_secret_detection_reports? }

    let(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(secret_detection: true)
    end

    context 'when head pipeline has secret detection reports' do
      let(:merge_request) { create(:merge_request, :with_secret_detection_reports, source_project: project) }

      it { is_expected.to be_truthy }

      context 'when head pipeline is blocked by manual jobs' do
        before do
          merge_request.diff_head_pipeline.block!
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when head pipeline does not have secrets detection reports' do
      let(:merge_request) { create(:merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#calculate_reactive_cache' do
    let(:merge_request) { create(:merge_request) }

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

  describe '#find_coverage_reports' do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, :with_coverage_reports, source_project: project) }
    let(:pipeline) { merge_request.head_pipeline }

    subject { merge_request.find_coverage_reports }

    context 'when head pipeline has coverage reports' do
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
            merge_request.update!(head_pipeline: nil)
          end

          it 'returns an error message' do
            expect(subject[:status]).to eq(:error)
          end
        end

        context 'when cached results is not latest' do
          before do
            allow_next_instance_of(Ci::GenerateCoverageReportsService) do |service|
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

  describe '#find_codequality_mr_diff_reports' do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, :with_codequality_mr_diff_reports, source_project: project, id: 123456789) }
    let(:pipeline) { merge_request.head_pipeline }

    subject(:mr_diff_report) { merge_request.find_codequality_mr_diff_reports }

    context 'when head pipeline has coverage reports' do
      context 'when reactive cache worker is parsing results asynchronously' do
        it 'returns status' do
          expect(mr_diff_report[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect(mr_diff_report[:status]).to eq(:parsed)
        end

        context 'when an error occurrs' do
          before do
            merge_request.update!(head_pipeline: nil)
          end

          it 'returns an error message' do
            expect(mr_diff_report[:status]).to eq(:error)
          end
        end

        context 'when cached results is not latest' do
          before do
            allow_next_instance_of(Ci::GenerateCodequalityMrDiffReportService) do |service|
              allow(service).to receive(:latest?).and_return(false)
            end
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { mr_diff_report }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
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
      create(
        :ci_pipeline,
        :with_test_reports,
        project: project,
        ref: merge_request.target_branch,
        sha: merge_request.diff_base_sha
      )
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has test reports' do
      let!(:head_pipeline) do
        create(
          :ci_pipeline,
          :with_test_reports,
          project: project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha
        )
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
        create(
          :ci_pipeline,
          project: project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha
        )
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to eq('This merge request does not have test reports')
      end
    end
  end

  describe '#compare_accessibility_reports' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request, reload: true) { create(:merge_request, :with_accessibility_reports, source_project: project) }
    let_it_be(:pipeline) { merge_request.head_pipeline }

    subject { merge_request.compare_accessibility_reports }

    context 'when head pipeline has accessibility reports' do
      let(:job) do
        create(:ci_build, options: { artifacts: { reports: { pa11y: ['accessibility.json'] } } }, pipeline: pipeline)
      end

      let(:artifacts_metadata) { create(:ci_job_artifact, :metadata, job: job) }

      context 'when reactive cache worker is parsing results asynchronously' do
        it 'returns parsing status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns parsed status' do
          expect(subject[:status]).to eq(:parsed)
          expect(subject[:data]).to be_present
        end

        context 'when an error occurrs' do
          before do
            merge_request.update!(head_pipeline: nil)
          end

          it 'returns an error status' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:status_reason]).to eq("This merge request does not have accessibility reports")
          end
        end

        context 'when cached result is not latest' do
          before do
            allow_next_instance_of(Ci::CompareAccessibilityReportsService) do |service|
              allow(service).to receive(:latest?).and_return(false)
            end
          end

          it 'raises an InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_codequality_reports' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request, reload: true) { create(:merge_request, :with_codequality_reports, source_project: project) }
    let_it_be(:pipeline) { merge_request.head_pipeline }

    subject { merge_request.compare_codequality_reports }

    context 'when head pipeline has codequality report' do
      let(:job) do
        create(:ci_build, options: { artifacts: { reports: { codeclimate: ['codequality.json'] } } }, pipeline: pipeline)
      end

      let(:artifacts_metadata) { create(:ci_job_artifact, :metadata, job: job) }

      context 'when reactive cache worker is parsing results asynchronously' do
        it 'returns parsing status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns parsed status' do
          expect(subject[:status]).to eq(:parsed)
          expect(subject[:data]).to be_present
        end

        context 'when an error occurrs' do
          before do
            merge_request.update!(head_pipeline: nil)
          end

          it 'returns an error status' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:status_reason]).to eq("This merge request does not have codequality reports")
          end
        end

        context 'when cached result is not latest' do
          before do
            allow_next_instance_of(Ci::CompareCodequalityReportsService) do |service|
              allow(service).to receive(:latest?).and_return(false)
            end
          end

          it 'raises an InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
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
          subject.update!(target_branch: 'csv')
        end

        it_behaves_like 'returning all SHA'
      end

      context 'with a branch having no difference' do
        before do
          subject.update!(target_branch: 'branch-merged')
          subject.reload # make sure commits were not cached
        end

        it_behaves_like 'returning all SHA'
      end
    end

    context 'when merge request is not persisted' do
      let_it_be(:project) { create(:project, :repository) }

      context 'when compare commits are set in the service' do
        let(:commit) { spy('commit') }

        subject do
          build(:merge_request, source_project: project, compare_commits: [commit, commit])
        end

        it 'returns commits from compare commits temporary data' do
          expect(subject.all_commit_shas).to eq [commit, commit]
        end
      end

      context 'when compare commits are not set in the service' do
        subject { build(:merge_request, source_project: project) }

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

  describe '#merged_commit_sha' do
    it 'returns nil when not merged' do
      expect(subject.merged_commit_sha).to be_nil
    end

    context 'when the MR is merged' do
      let(:sha) { 'f7ce827c314c9340b075657fd61c789fb01cf74d' }

      before do
        subject.mark_as_merged!
      end

      it 'returns merged_commit_sha when there is a merged_commit_sha' do
        subject.update_attribute(:merged_commit_sha, sha)

        expect(subject.merged_commit_sha).to eq(sha)
      end

      it 'returns merge_commit_sha when there is a merge_commit_sha' do
        subject.update_attribute(:merge_commit_sha, sha)

        expect(subject.merged_commit_sha).to eq(sha)
      end

      it 'returns squash_commit_sha when there is a squash_commit_sha' do
        subject.update_attribute(:squash_commit_sha, sha)

        expect(subject.merged_commit_sha).to eq(sha)
      end

      it 'returns diff_head_sha when there are no merge_commit_sha and squash_commit_sha' do
        allow(subject).to receive(:diff_head_sha).and_return(sha)

        expect(subject.merged_commit_sha).to eq(sha)
      end
    end
  end

  describe '#short_merged_commit_sha' do
    context 'when merged_commit_sha is nil' do
      before do
        allow(subject).to receive(:merged_commit_sha).and_return(nil)
      end

      it 'returns nil' do
        expect(subject.short_merged_commit_sha).to be_nil
      end
    end

    context 'when merged_commit_sha is present' do
      before do
        allow(subject).to receive(:merged_commit_sha).and_return('f7ce827c314c9340b075657fd61c789fb01cf74d')
      end

      it 'returns shortened merged_commit_sha' do
        expect(subject.short_merged_commit_sha).to eq('f7ce827c')
      end
    end
  end

  describe '#can_be_reverted?' do
    subject { create(:merge_request, source_project: create(:project, :repository)) }

    context 'when there is no merge_commit for the MR' do
      before do
        subject.metrics.update!(merged_at: Time.current.utc)
      end

      it 'returns false' do
        expect(subject.can_be_reverted?(nil)).to be_falsey
      end
    end

    context 'when the MR has been merged' do
      before do
        MergeRequests::MergeService
          .new(project: subject.target_project, current_user: subject.author, params: { sha: subject.diff_head_sha })
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

          ProcessCommitWorker.new.perform(
            project.id,
            current_user.id,
            project.commit(revert_commit_id).to_hash,
            project.default_branch == branch
          )
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

    context 'when no metrics or merge event exists' do
      let(:user) { create(:user) }
      let(:merge_request) { create(:merge_request, :merged) }

      before do
        merge_request.metrics.destroy!
      end

      context 'when resource event for the merge exists' do
        before do
          SystemNoteService.change_status(
            merge_request,
            merge_request.target_project,
            user,
            merge_request.state,
            nil
          )
        end

        it 'returns the resource event creation date' do
          expect(merge_request.reload.metrics).to be_nil
          expect(merge_request.merge_event).to be_nil
          expect(merge_request.resource_state_events.count).to eq(1)
          expect(merge_request.merged_at).to eq(merge_request.resource_state_events.first.created_at)
        end
      end

      context 'when system note for the merge exists' do
        before do
          # We do not create these system notes anymore but we need this to work for existing MRs
          # that used system notes instead of resource state events
          create(:note, :system, noteable: merge_request, note: 'merged')
        end

        it 'returns the merging note creation date' do
          expect(merge_request.reload.metrics).to be_nil
          expect(merge_request.merge_event).to be_nil
          expect(merge_request.notes.count).to eq(1)
          expect(merge_request.merged_at).to eq(merge_request.notes.first.created_at)
        end
      end
    end
  end

  describe '#participants' do
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

      allow(MergeWorker).to receive(:with_status).and_return(MergeWorker)

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

    before do
      allow(RebaseWorker).to receive(:with_status).and_return(RebaseWorker)
    end

    it 'atomically enqueues a RebaseWorker job and updates rebase_jid' do
      expect(RebaseWorker)
        .to receive(:perform_async)
        .with(merge_request.id, user_id, false)
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
    subject { build_stubbed(:merge_request) }

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

    it 'return true if #mergeable_state? is true and the MR #can_be_merged? is false' do
      allow(subject).to receive(:mergeable_state?) { true }
      expect(subject).to receive(:check_mergeability)
      expect(subject).to receive(:can_be_merged?) { false }

      expect(subject.mergeable?).to be_falsey
    end

    context 'with skip_ci_check option' do
      before do
        allow(subject.project).to receive(:only_allow_merge_if_pipeline_succeeds?).and_return(true)
        allow(subject).to receive_messages(check_mergeability: nil, can_be_merged?: true, has_no_commits?: false)
      end

      where(:mergeable_ci_state, :skip_ci_check, :expected_mergeable) do
        false | false | false
        false | true  | true
        true  | false | true
        true  | true  | true
      end

      with_them do
        it 'overrides mergeable_ci_state?' do
          allow_next_instance_of(MergeRequests::Mergeability::CheckCiStatusService) do |check|
            allow(check).to receive(:mergeable_ci_state?).and_return(mergeable_ci_state)
          end

          expect(subject.mergeable?(skip_ci_check: skip_ci_check)).to eq(expected_mergeable)
        end
      end
    end

    context 'with skip_discussions_check option' do
      before do
        allow(subject.project).to receive(:only_allow_merge_if_all_discussions_are_resolved?).and_return(true)

        allow(subject).to receive_messages(
          mergeable_ci_state?: true,
          check_mergeability: nil,
          can_be_merged?: true,
          has_no_commits?: false
        )
      end

      where(:mergeable_discussions_state, :skip_discussions_check, :expected_mergeable) do
        false | false | false
        false | true  | true
        true  | false | true
        true  | true  | true
      end

      with_them do
        it 'overrides mergeable_discussions_state?' do
          allow(subject).to receive(:mergeable_discussions_state?) { mergeable_discussions_state }

          expect(subject.mergeable?(skip_discussions_check: skip_discussions_check)).to eq(expected_mergeable)
        end
      end
    end

    context 'with check_mergeability_retry_lease option' do
      it 'call check_mergeability with sync_retry_lease' do
        allow(subject).to receive(:mergeable_state?) { true }
        expect(subject).to receive(:check_mergeability).with(sync_retry_lease: true)

        subject.mergeable?(check_mergeability_retry_lease: true)
      end
    end

    context 'with skip_rebase_check option' do
      before do
        allow(subject.project).to receive(:ff_merge_must_be_possible?).and_return(true)

        allow(subject).to receive_messages(
          mergeable_state?: true,
          check_mergeability: nil,
          can_be_merged?: true
        )
      end

      where(:should_be_rebased, :skip_rebase_check, :expected_mergeable) do
        false | false | true
        false | true  | true
        true  | false | false
        true  | true  | true
      end

      with_them do
        it 'overrides should_be_rebased?' do
          allow(subject).to receive(:should_be_rebased?) { should_be_rebased }

          expect(subject.mergeable?(skip_rebase_check: skip_rebase_check)).to eq(expected_mergeable)
        end
      end
    end
  end

  describe '#skipped_mergeable_checks' do
    subject { build_stubbed(:merge_request).skipped_mergeable_checks(options) }

    let(:feature_flag) { true }

    where(:options, :skip_ci_check) do
      {}                              | false
      { auto_merge_requested: false } | false
      { auto_merge_requested: true }  | true
    end
    with_them do
      it { is_expected.to include(skip_ci_check: skip_ci_check) }
    end

    context 'when auto_merge_requested is true' do
      let(:options) { { auto_merge_requested: true, auto_merge_strategy: auto_merge_strategy } }

      where(:auto_merge_strategy, :skip_checks) do
        ''                                                      | false
        AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS       | true
      end

      with_them do
        it do
          is_expected.to include(skip_approved_check: skip_checks, skip_draft_check: skip_checks,
            skip_blocked_check: skip_checks, skip_discussions_check: skip_checks,
            skip_external_status_check: skip_checks, skip_requested_changes_check: skip_checks,
            skip_jira_check: skip_checks, skip_security_policy_check: skip_checks,
            skip_merge_time_check: skip_checks)
        end
      end
    end
  end

  describe '#check_mergeability' do
    let(:mergeability_service) { double }

    subject { create(:merge_request, merge_status: 'unchecked') }

    before do
      allow(MergeRequests::MergeabilityCheckService).to receive(:new) do
        mergeability_service
      end
    end

    shared_examples_for 'method that executes MergeabilityCheckService' do
      it 'executes MergeabilityCheckService' do
        expect(mergeability_service).to receive(:execute)

        subject.check_mergeability
      end

      context 'when sync_retry_lease is true' do
        it 'executes MergeabilityCheckService' do
          expect(mergeability_service).to receive(:execute).with(retry_lease: true)

          subject.check_mergeability(sync_retry_lease: true)
        end
      end

      context 'when async is true' do
        it 'executes MergeabilityCheckService asynchronously' do
          expect(mergeability_service).to receive(:async_execute)

          subject.check_mergeability(async: true)
        end
      end
    end

    context 'if the merge status is unchecked' do
      it_behaves_like 'method that executes MergeabilityCheckService'
    end

    context 'if the merge status is checking' do
      before do
        subject.mark_as_checking!
      end

      it_behaves_like 'method that executes MergeabilityCheckService'
    end

    context 'if the merge status is checked' do
      before do
        subject.mark_as_mergeable!
      end

      it 'does not call MergeabilityCheckService' do
        expect(MergeRequests::MergeabilityCheckService).not_to receive(:new)

        subject.check_mergeability
      end
    end
  end

  shared_examples 'for mergeable_state' do
    subject { create(:merge_request) }

    it 'checks if merge request can be merged' do
      allow_next_instance_of(MergeRequests::Mergeability::CheckCiStatusService) do |check|
        allow(check).to receive(:mergeable_ci_state?).and_return(true)
      end
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
        subject.title = '[Draft] MR'
      end

      it 'returns false' do
        expect(subject.mergeable_state?).to be_falsey
      end

      it 'returns true when skipping draft check' do
        expect(subject.mergeable_state?(skip_draft_check: true)).to be(true)
      end
    end

    context 'when has no commits' do
      before do
        allow(subject).to receive(:has_no_commits?) { true }
      end

      it 'returns false' do
        expect(subject.mergeable_state?).to be_falsey
      end
    end

    context 'when failed' do
      context 'when #mergeable_ci_state? is false' do
        before do
          allow(subject.project).to receive(:only_allow_merge_if_pipeline_succeeds?) { true }
          allow_next_instance_of(MergeRequests::Mergeability::CheckCiStatusService) do |check|
            allow(check).to receive(:mergeable_ci_state?).and_return(false)
          end
        end

        it 'returns false' do
          expect(subject.mergeable_state?).to be_falsey
        end

        it 'returns true when skipping ci check' do
          expect(subject.mergeable_state?(skip_ci_check: true)).to be(true)
        end
      end

      context 'when #mergeable_discussions_state? is false' do
        before do
          allow(subject.project).to receive(:only_allow_merge_if_all_discussions_are_resolved?) { true }
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

  describe '#mergeable_state?' do
    it_behaves_like 'for mergeable_state'
  end

  describe "#public_merge_status" do
    using RSpec::Parameterized::TableSyntax
    subject { build(:merge_request, merge_status: status) }

    where(:status, :public_status) do
      'cannot_be_merged_rechecking' | 'checking'
      'preparing'                   | 'checking'
      'checking'                    | 'checking'
      'cannot_be_merged'            | 'cannot_be_merged'
    end

    with_them do
      it { expect(subject.public_merge_status).to eq(public_status) }
    end
  end

  describe "#head_pipeline_active? " do
    context 'when project lacks a head_pipeline relation' do
      before do
        subject.head_pipeline = nil
      end

      it 'returns false' do
        expect(subject.head_pipeline_active?).to be false
      end
    end

    context 'when project has a head_pipeline relation' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      before do
        allow(subject).to receive(:head_pipeline) { pipeline }
      end

      it 'accesses the value from the head_pipeline' do
        expect(subject.head_pipeline)
          .to receive(:active?)

        subject.head_pipeline_active?
      end
    end
  end

  describe "#diff_head_pipeline_success? " do
    context 'when project lacks an diff_head_pipeline relation' do
      before do
        allow(subject).to receive(:diff_head_pipeline) { nil }
      end

      it 'returns false' do
        expect(subject.diff_head_pipeline_success?).to be false
      end
    end

    context 'when project has a diff_head_pipeline relation' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      before do
        allow(subject).to receive(:diff_head_pipeline) { pipeline }
      end

      it 'accesses the value from the diff_head_pipeline' do
        expect(subject.diff_head_pipeline)
          .to receive(:success?)

        subject.diff_head_pipeline_success?
      end
    end
  end

  describe "#diff_head_pipeline_active? " do
    context 'when project lacks an diff_head_pipeline relation' do
      before do
        allow(subject).to receive(:diff_head_pipeline) { nil }
      end

      it 'returns false' do
        expect(subject.diff_head_pipeline_active?).to be false
      end
    end

    context 'when project has a diff_head_pipeline relation' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      before do
        allow(subject).to receive(:diff_head_pipeline) { pipeline }
      end

      it 'accesses the value from the diff_head_pipeline' do
        expect(subject.diff_head_pipeline)
          .to receive(:active?)

        subject.diff_head_pipeline_active?
      end
    end
  end

  describe '#has_ci_enabled?', :clean_gitlab_redis_shared_state do
    let_it_be(:mr) { create(:merge_request, source_project: project) }
    let_it_be(:project) { create(:project, :auto_devops, only_allow_merge_if_pipeline_succeeds: false) }
    let(:mr_ci) { true }

    before do
      allow(mr).to receive(:has_ci?).and_return(mr_ci)
    end

    context 'when MR has_ci? is true' do
      context 'when pipeline has a creation request' do
        before do
          Ci::PipelineCreation::Requests.start_for_merge_request(mr)
        end

        it 'returns true' do
          expect(mr.has_ci_enabled?).to eq(true)
        end
      end

      context 'when pipeline has no creation request' do
        it 'returns true' do
          expect(mr.has_ci_enabled?).to eq(true)
        end
      end

      context 'when change_ci_enabled_hurestic is disabled and project does not have ci' do
        before do
          stub_feature_flags(change_ci_enabled_hurestic: false)
          allow(mr.project).to receive(:has_ci?).and_return(false)
        end

        it 'returns true' do
          expect(mr.has_ci_enabled?).to eq(true)
        end
      end
    end

    context 'when MR has_ci? is false' do
      let(:mr_ci) { false }

      context 'when pipeline has a creation request' do
        before do
          Ci::PipelineCreation::Requests.start_for_merge_request(mr)
        end

        it 'returns true' do
          expect(mr.has_ci_enabled?).to eq(true)
        end
      end

      context 'when pipeline has no creation request' do
        it 'returns false' do
          expect(mr.has_ci_enabled?).to eq(false)
        end
      end

      context 'when change_ci_enabled_hurestic is disabled' do
        before do
          stub_feature_flags(change_ci_enabled_hurestic: false)
        end

        context 'when the project has ci enabled' do
          before do
            allow(mr.project).to receive(:has_ci?).and_return(true)
          end

          it 'returns true' do
            expect(mr.has_ci_enabled?).to eq(true)
          end
        end

        context 'when the project does not have ci enabled' do
          before do
            allow(mr.project).to receive(:has_ci?).and_return(false)
          end

          it 'returns false' do
            expect(mr.has_ci_enabled?).to eq(false)
          end
        end
      end
    end
  end

  describe '#pipeline_creating?' do
    let(:pipeline_creating) { subject.pipeline_creating? }

    before do
      allow(Ci::PipelineCreation::Requests)
        .to receive(:pipeline_creating_for_merge_request?)
        .with(subject)
        .and_return(creating)
    end

    context 'when pipeline creating request is true' do
      let(:creating) { true }

      it 'is true' do
        expect(pipeline_creating).to eq true
      end
    end

    context 'when pipeline creating request is false' do
      let(:creating) { false }

      it 'is false' do
        expect(pipeline_creating).to eq false
      end
    end
  end

  describe '#mergeable_discussions_state?' do
    let(:merge_request) { create(:merge_request_with_diff_notes, source_project: project) }

    context 'when project.only_allow_merge_if_all_discussions_are_resolved == true' do
      let_it_be(:project) { create(:project, :repository, only_allow_merge_if_all_discussions_are_resolved: true) }

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
          merge_request.notes.destroy_all # rubocop: disable Cop/DestroyAll
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
    subject { create(:merge_request, source_project: project) }

    let(:project) { create(:project, :repository) }
    let(:create_commit) { project.commit("913c66a37b4a45b9769037c55c2d238bd0942d2e") }
    let(:modify_commit) { project.commit("874797c3a73b60d2187ed6e2fcabd289ff75171e") }
    let(:edit_commit) { project.commit("570e7b2abdd848b95f2f578043fc23bd6f6fd24d") }
    let(:discussion) { create(:diff_note_on_merge_request, noteable: subject, project: project, position: old_position).to_discussion }
    let(:path) { "files/ruby/popen.rb" }
    let(:new_line) { 9 }

    let(:old_diff_refs) do
      Gitlab::Diff::DiffRefs.new(
        base_sha: create_commit.parent_id,
        head_sha: modify_commit.sha
      )
    end

    let(:new_diff_refs) do
      Gitlab::Diff::DiffRefs.new(
        base_sha: create_commit.parent_id,
        head_sha: edit_commit.sha
      )
    end

    let(:old_position) do
      Gitlab::Diff::Position.new(
        old_path: path,
        new_path: path,
        old_line: nil,
        new_line: new_line,
        diff_refs: old_diff_refs
      )
    end

    it "updates diff discussion positions" do
      expect(Discussions::UpdateDiffPositionService).to receive(:new).with(
        subject.project,
        subject.author,
        old_diff_refs: old_diff_refs,
        new_diff_refs: new_diff_refs,
        paths: discussion.position.paths
      ).and_call_original

      expect_any_instance_of(Discussions::UpdateDiffPositionService).to receive(:execute).with(discussion).and_call_original

      subject.update_diff_discussion_positions(
        old_diff_refs: old_diff_refs,
        new_diff_refs: new_diff_refs,
        current_user: subject.author
      )
    end

    it 'does not call the resolve method' do
      expect(MergeRequests::ResolvedDiscussionNotificationService).not_to receive(:new)

      subject.update_diff_discussion_positions(
        old_diff_refs: old_diff_refs,
        new_diff_refs: new_diff_refs,
        current_user: subject.author
      )
    end

    context 'when resolve_outdated_diff_discussions is set' do
      before do
        discussion

        subject.project.update!(resolve_outdated_diff_discussions: true)
      end

      context 'when the active discussion is resolved in the update' do
        it 'calls MergeRequests::ResolvedDiscussionNotificationService' do
          expect_any_instance_of(MergeRequests::ResolvedDiscussionNotificationService)
            .to receive(:execute).with(subject)

          subject.update_diff_discussion_positions(
            old_diff_refs: old_diff_refs,
            new_diff_refs: new_diff_refs,
            current_user: subject.author
          )
        end
      end

      context 'when the active discussion does not have resolved in the update' do
        let(:new_line) { 16 }

        it 'does not call the resolve method' do
          expect(MergeRequests::ResolvedDiscussionNotificationService).not_to receive(:new)

          subject.update_diff_discussion_positions(
            old_diff_refs: old_diff_refs,
            new_diff_refs: new_diff_refs,
            current_user: subject.author
          )
        end
      end

      context 'when the active discussion was already resolved' do
        before do
          discussion.resolve!(subject.author)
        end

        it 'does not call the resolve method' do
          expect(MergeRequests::ResolvedDiscussionNotificationService).not_to receive(:new)

          subject.update_diff_discussion_positions(
            old_diff_refs: old_diff_refs,
            new_diff_refs: new_diff_refs,
            current_user: subject.author
          )
        end
      end
    end
  end

  describe '#branch_merge_base_commit' do
    let(:project) { create(:project, :repository) }

    subject { create(:merge_request, source_project: project) }

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
      let(:project) { create(:project, :repository) }

      subject { create(:merge_request, source_project: project) }

      let(:expected_diff_refs) do
        Gitlab::Diff::DiffRefs.new(
          base_sha: subject.merge_request_diff.base_commit_sha,
          start_sha: subject.merge_request_diff.start_commit_sha,
          head_sha: subject.merge_request_diff.head_commit_sha
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

  describe "#closed_or_merged_without_fork?" do
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
        expect(closed_merge_request.closed_or_merged_without_fork?).to be_falsey
      end

      it "returns true if the fork does not exist" do
        unlink_project.execute
        closed_merge_request.reload

        expect(closed_merge_request.closed_or_merged_without_fork?).to be_truthy
      end
    end

    context "when the merge request was merged" do
      let(:merged_merge_request) do
        create(:merged_merge_request,
          source_project: forked_project,
          target_project: project)
      end

      it "returns false if the fork exist" do
        expect(merged_merge_request.closed_or_merged_without_fork?).to be_falsey
      end

      it "returns true if the fork does not exist" do
        unlink_project.execute
        merged_merge_request.reload

        expect(merged_merge_request.closed_or_merged_without_fork?).to be_truthy
      end
    end

    context "when the merge request is open" do
      let(:open_merge_request) do
        create(:merge_request,
          source_project: forked_project,
          target_project: project)
      end

      it "returns false" do
        expect(open_merge_request.closed_or_merged_without_fork?).to be_falsey
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
          merge_request.update!(state: 'merged')

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

  describe '#pipeline_coverage_delta' do
    let!(:merge_request) { create(:merge_request) }

    let!(:source_pipeline) do
      create(:ci_pipeline,
        project: project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha
      )
    end

    let!(:target_pipeline) do
      create(:ci_pipeline,
        project: project,
        ref: merge_request.target_branch,
        sha: merge_request.diff_base_sha
      )
    end

    def create_build(pipeline, coverage, name)
      create(:ci_build, :success, pipeline: pipeline, coverage: coverage, name: name)
      merge_request.update_head_pipeline
    end

    context 'when both source and target branches have coverage information' do
      it 'returns the appropriate coverage delta' do
        create_build(source_pipeline, 60.2, 'test:1')
        create_build(target_pipeline, 50, 'test:2')

        expect(merge_request.pipeline_coverage_delta).to be_within(0.001).of(10.2)
      end
    end

    context 'when target branch does not have coverage information' do
      it 'returns nil' do
        create_build(source_pipeline, 50, 'test:1')

        expect(merge_request.pipeline_coverage_delta).to be_nil
      end
    end

    context 'when source branch does not have coverage information' do
      it 'returns nil for coverage_delta' do
        create_build(target_pipeline, 50, 'test:1')

        expect(merge_request.pipeline_coverage_delta).to be_nil
      end
    end

    context 'neither source nor target branch has coverage information' do
      it 'returns nil for coverage_delta' do
        expect(merge_request.pipeline_coverage_delta).to be_nil
      end
    end
  end

  describe '#use_merge_base_pipeline_for_comparison?' do
    let(:project) { create(:project, :public, :repository) }
    let(:merge_request) { create(:merge_request, :with_codequality_reports, source_project: project) }
    let(:service_class) { Ci::CompareReportsBaseService }

    subject { merge_request.use_merge_base_pipeline_for_comparison?(service_class) }

    it { is_expected.to eq(false) }
  end

  describe '#comparison_base_pipeline' do
    subject(:pipeline) { merge_request.comparison_base_pipeline(service_class) }

    let(:project) { create(:project, :public, :repository) }
    let(:merge_request) { create(:merge_request, :with_codequality_reports, source_project: project) }
    let(:service_class) { ::Ci::CompareReportsBaseService }
    let!(:base_pipeline) do
      create(:ci_pipeline,
        :with_test_reports,
        project: project,
        ref: merge_request.target_branch,
        sha: merge_request.diff_base_sha
      )
    end

    before do
      allow(merge_request).to receive(:use_merge_base_pipeline_for_comparison?)
        .with(service_class).and_return(uses_merge_base)
    end

    context 'when service class uses merge base pipeline' do
      let(:uses_merge_base) { true }

      context 'when merge request has a merge request pipeline' do
        let(:merge_request) do
          create(:merge_request, :with_merge_request_pipeline, source_project: project)
        end

        let!(:merge_base_pipeline) do
          create(:ci_pipeline, project: project, ref: merge_request.target_branch, sha: merge_request.target_branch_sha)
        end

        before do
          merge_request.update_head_pipeline
        end

        it 'returns the merge_base_pipeline' do
          expect(pipeline).to eq(merge_base_pipeline)
        end
      end

      it 'returns the base_pipeline when merge does not have a merge request pipeline' do
        expect(pipeline).to eq(base_pipeline)
      end
    end

    context 'when service_class does not use merge base pipeline' do
      let(:uses_merge_base) { false }

      it 'returns the base_pipeline' do
        expect(pipeline).to eq(base_pipeline)
      end

      context 'when merge request has a merge request pipeline' do
        let(:merge_request) do
          create(:merge_request, :with_merge_request_pipeline, source_project: project)
        end

        it 'returns the base pipeline' do
          expect(pipeline).to eq(base_pipeline)
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

  describe '#merge_base_pipeline' do
    let(:merge_request) do
      create(:merge_request, :with_merge_request_pipeline)
    end

    let(:merge_base_pipeline) do
      create(:ci_pipeline, ref: merge_request.target_branch, sha: merge_request.target_branch_sha)
    end

    before do
      merge_base_pipeline
      merge_request.update_head_pipeline
    end

    it 'returns a pipeline pointing to a commit on the target ref' do
      expect(merge_request.merge_base_pipeline).to eq(merge_base_pipeline)
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
    let(:project) { create(:project, :repository) }

    subject { create(:merge_request, importing: true, source_project: project) }

    let!(:merge_request_diff1) { subject.merge_request_diffs.create!(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
    let!(:merge_request_diff2) { subject.merge_request_diffs.create!(head_commit_sha: nil) }
    let!(:merge_request_diff3) { subject.merge_request_diffs.create!(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }

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
    let(:project) { create(:project, :repository) }

    subject { create(:merge_request, importing: true, source_project: project) }

    let!(:merge_request_diff1) { subject.merge_request_diffs.create!(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
    let!(:merge_request_diff2) { subject.merge_request_diffs.create!(head_commit_sha: nil) }
    let!(:merge_request_diff3) { subject.merge_request_diffs.create!(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }

    context 'when the diff refs are for an older merge request version' do
      let(:diff_refs) { merge_request_diff1.diff_refs }

      it 'returns the diff ID for the version to show' do
        expect(subject.version_params_for(diff_refs)).to eq(diff_id: merge_request_diff1.id)
      end
    end

    context 'when the diff refs are for a comparison between merge request versions' do
      let(:diff_refs) do
        ::MergeRequests::MergeRequestDiffComparison
          .new(merge_request_diff3)
          .compare_with(merge_request_diff1.head_commit_sha)
          .diff_refs
      end

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
    let(:project) { create(:project, :repository) }

    subject { create(:merge_request, source_project: project) }

    it 'fetches the ref and expires the ancestor cache' do
      expect { subject.target_project.repository.delete_refs(subject.ref_path) }.not_to raise_error

      expect(project.repository).to receive(:expire_ancestor_cache).with(subject.target_branch_sha, subject.diff_head_sha).and_call_original
      expect(subject).to receive(:expire_ancestor_cache).and_call_original

      subject.fetch_ref!

      expect(subject.target_project.repository.ref_exists?(subject.ref_path)).to be_truthy
    end
  end

  describe 'removing a merge request' do
    it 'refreshes the number of open merge requests of the target project' do
      project = subject.target_project

      expect do
        subject.destroy!

        BatchLoader::Executor.clear_current
      end.to change { project.open_merge_requests_count }.from(1).to(0)
    end
  end

  it_behaves_like 'throttled touch' do
    subject { create(:merge_request, updated_at: 1.hour.ago) }
  end

  context 'state machine transitions' do
    let(:project) { create(:project, :repository) }

    shared_examples_for 'transition not triggering mergeRequestMergeStatusUpdated GraphQL subscription' do
      specify do
        expect(GraphqlTriggers).not_to receive(:merge_request_merge_status_updated)

        transition!
      end
    end

    shared_examples_for 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription' do
      specify do
        expect(GraphqlTriggers).to receive(:merge_request_merge_status_updated).with(subject).and_call_original

        transition!
      end

      context 'when skip_merge_status_trigger is set to true' do
        before do
          subject.skip_merge_status_trigger = true
        end

        it_behaves_like 'transition not triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when transaction is not committed' do
        it_behaves_like 'transition not triggering mergeRequestMergeStatusUpdated GraphQL subscription' do
          def transition!
            subject

            MergeRequest.transaction do
              super

              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end

    shared_examples 'for an invalid state transition' do
      specify 'is not a valid state transition' do
        expect { transition! }.to raise_error(StateMachines::InvalidTransition)
        expect(subject.transitioning?).to be_falsey
      end
    end

    shared_examples 'for a valid state transition' do
      it 'is a valid state transition' do
        expect { transition! }
          .to change { subject.merge_status }
          .from(merge_status.to_s)
          .to(expected_merge_status)
        expect(subject.transitioning?).to be_falsey
      end
    end

    describe '#unlock_mr' do
      subject { create(:merge_request, state: 'locked', source_project: project, merge_jid: 123) }

      it 'updates merge request head pipeline and sets merge_jid to nil', :sidekiq_inline do
        pipeline = create(:ci_empty_pipeline, project: subject.project, ref: subject.source_branch, sha: subject.source_branch_sha)

        subject.unlock_mr

        subject.reload
        expect(subject.head_pipeline).to eq(pipeline)
        expect(subject.merge_jid).to be_nil
      end
    end

    describe '#mark_as_preparing' do
      subject { create(:merge_request, source_project: project, merge_status: merge_status) }

      let(:expected_merge_status) { 'preparing' }

      def transition!
        subject.mark_as_preparing!
      end

      context 'when the status is unchecked' do
        let(:merge_status) { :unchecked }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition not triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is checking' do
        let(:merge_status) { :checking }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is can_be_merged' do
        let(:merge_status) { :can_be_merged }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is cannot_be_merged_recheck' do
        let(:merge_status) { :cannot_be_merged_recheck }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is cannot_be_merged' do
        let(:merge_status) { :cannot_be_merged }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is cannot_be_merged_rechecking' do
        let(:merge_status) { :cannot_be_merged_rechecking }

        include_examples 'for an invalid state transition'
      end
    end

    describe '#mark_as_unchecked' do
      subject { create(:merge_request, source_project: project, merge_status: merge_status) }

      def transition!
        subject.mark_as_unchecked!
      end

      context 'when the status is unchecked' do
        let(:merge_status) { :unchecked }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is checking' do
        let(:merge_status) { :checking }
        let(:expected_merge_status) { 'unchecked' }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is can_be_merged' do
        let(:merge_status) { :can_be_merged }
        let(:expected_merge_status) { 'unchecked' }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is cannot_be_merged_recheck' do
        let(:merge_status) { :cannot_be_merged_recheck }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is cannot_be_merged' do
        let(:merge_status) { :cannot_be_merged }
        let(:expected_merge_status) { 'cannot_be_merged_recheck' }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is cannot_be_merged_rechecking' do
        let(:merge_status) { :cannot_be_merged_rechecking }
        let(:expected_merge_status) { 'cannot_be_merged_recheck' }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end
    end

    describe '#mark_as_checking' do
      subject { create(:merge_request, source_project: project, merge_status: merge_status) }

      def transition!
        subject.mark_as_checking!
      end

      context 'when the status is unchecked' do
        let(:merge_status) { :unchecked }
        let(:expected_merge_status) { 'checking' }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition not triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is checking' do
        let(:merge_status) { :checking }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is can_be_merged' do
        let(:merge_status) { :can_be_merged }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is cannot_be_merged_recheck' do
        let(:merge_status) { :cannot_be_merged_recheck }
        let(:expected_merge_status) { 'cannot_be_merged_rechecking' }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition not triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is cannot_be_merged' do
        let(:merge_status) { :cannot_be_merged }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is cannot_be_merged_rechecking' do
        let(:merge_status) { :cannot_be_merged_rechecking }

        include_examples 'for an invalid state transition'
      end
    end

    describe '#mark_as_mergeable' do
      subject { create(:merge_request, source_project: project, merge_status: merge_status) }

      let(:expected_merge_status) { 'can_be_merged' }

      def transition!
        subject.mark_as_mergeable!
      end

      context 'when the status is unchecked' do
        let(:merge_status) { :unchecked }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is checking' do
        let(:merge_status) { :checking }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is can_be_merged' do
        let(:merge_status) { :can_be_merged }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is cannot_be_merged_recheck' do
        let(:merge_status) { :cannot_be_merged_recheck }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is cannot_be_merged' do
        let(:merge_status) { :cannot_be_merged }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is cannot_be_merged_rechecking' do
        let(:merge_status) { :cannot_be_merged_rechecking }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end
    end

    describe '#mark_as_unmergeable' do
      subject { create(:merge_request, source_project: project, merge_status: merge_status) }

      let(:expected_merge_status) { 'cannot_be_merged' }

      def transition!
        subject.mark_as_unmergeable!
      end

      context 'when the status is unchecked' do
        let(:merge_status) { :unchecked }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is checking' do
        let(:merge_status) { :checking }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is can_be_merged' do
        let(:merge_status) { :can_be_merged }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is cannot_be_merged_recheck' do
        let(:merge_status) { :cannot_be_merged_recheck }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end

      context 'when the status is cannot_be_merged' do
        let(:merge_status) { :cannot_be_merged }

        include_examples 'for an invalid state transition'
      end

      context 'when the status is cannot_be_merged_rechecking' do
        let(:merge_status) { :cannot_be_merged_rechecking }

        include_examples 'for a valid state transition'
        it_behaves_like 'transition triggering mergeRequestMergeStatusUpdated GraphQL subscription'
      end
    end

    describe 'transition to closed' do
      context 'with merge error' do
        subject { create(:merge_request, source_project: project, merge_error: 'merge error') }

        it 'clears merge error' do
          subject.close!

          expect(subject.reload.merge_error).to eq(nil)
        end
      end
    end

    describe 'transition to merged' do
      it 'resets the merge error' do
        subject.update!(merge_error: 'temp')

        expect { subject.mark_as_merged }.to change { subject.merge_error.present? }
          .from(true)
          .to(false)
      end

      context 'when it is a first contribution' do
        let(:new_user) { create(:user) }

        before do
          subject.update!(author: new_user)
        end

        it 'sets first_contribution' do
          subject.mark_as_merged

          expect(subject.state).to eq('merged')
          expect(subject.reload.first_contribution?).to be_truthy
        end

        it "doesn't set first_contribution not first contribution" do
          create(:merged_merge_request, source_project: project, author: new_user)

          subject.mark_as_merged

          expect(subject.first_contribution?).to be_falsey
        end
      end
    end

    describe 'transition to cannot_be_merged' do
      let(:notification_service) { double(:notification_service) }
      let(:todo_service) { double(:todo_service) }

      subject { create(:merge_request, state, source_project: project, merge_status: :unchecked) }

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

            subject.mark_as_unmergeable!

            subject.mark_as_unchecked!
            subject.mark_as_unmergeable!
          end

          it 'notifies conflict, but does not notify again if rechecking still results in cannot_be_merged with async mergeability check' do
            expect(notification_service).to receive(:merge_request_unmergeable).with(subject).once
            expect(todo_service).to receive(:merge_request_became_unmergeable).with(subject).once

            subject.mark_as_checking!
            subject.mark_as_unmergeable!

            subject.mark_as_unchecked!
            subject.mark_as_checking!
            subject.mark_as_unmergeable!
          end

          it 'notifies conflict, whenever newly unmergeable' do
            expect(notification_service).to receive(:merge_request_unmergeable).with(subject).twice
            expect(todo_service).to receive(:merge_request_became_unmergeable).with(subject).twice

            subject.mark_as_unmergeable!

            subject.mark_as_unchecked!
            subject.mark_as_mergeable!

            subject.mark_as_unchecked!
            subject.mark_as_unmergeable!
          end

          it 'notifies conflict, whenever newly unmergeable with async mergeability check' do
            expect(notification_service).to receive(:merge_request_unmergeable).with(subject).twice
            expect(todo_service).to receive(:merge_request_became_unmergeable).with(subject).twice

            subject.mark_as_checking!
            subject.mark_as_unmergeable!

            subject.mark_as_unchecked!
            subject.mark_as_checking!
            subject.mark_as_mergeable!

            subject.mark_as_unchecked!
            subject.mark_as_checking!
            subject.mark_as_unmergeable!
          end

          it 'does not notify whenever merge request is newly unmergeable due to other reasons' do
            allow(subject.project.repository).to receive(:can_be_merged?).and_return(true)

            expect(notification_service).not_to receive(:merge_request_unmergeable)
            expect(todo_service).not_to receive(:merge_request_became_unmergeable)

            subject.mark_as_unmergeable!
          end
        end
      end

      [:closed, :merged].each do |state|
        context state do
          let(:state) { state }

          it 'does not notify' do
            expect(notification_service).not_to receive(:merge_request_unmergeable)
            expect(todo_service).not_to receive(:merge_request_became_unmergeable)

            subject.mark_as_unmergeable!
          end
        end
      end

      context 'source branch is missing' do
        subject { create(:merge_request, :invalid, :opened, source_project: project, merge_status: :unchecked, target_branch: 'master') }

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
        check_states = [:unchecked, :cannot_be_merged_recheck, :cannot_be_merged_rechecking, :checking]

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
    let(:merge_request) { build_stubbed(:merge_request) }

    subject { merge_request.should_be_rebased? }

    context 'when the same source and target branches' do
      let(:merge_request) { build_stubbed(:merge_request, source_project: project, target_project: project) }

      it { is_expected.to be_falsey }
    end

    context 'when the project is using ff merge method' do
      before do
        allow(merge_request.target_project).to receive(:ff_merge_must_be_possible?).and_return(true)
      end

      context 'when the mr needs to be rebased to merge' do
        before do
          allow(merge_request).to receive(:ff_merge_possible?).and_return(false)
        end

        it { is_expected.to be_truthy }
      end

      context 'when the MR can be merged without rebase' do
        before do
          allow(merge_request).to receive(:ff_merge_possible?).and_return(true)
        end

        it { is_expected.to be_falsey }
      end
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
      let(:merge_request) { build_stubbed(:merge_request) }

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
      create(:merge_request, source_project: source_project, source_branch: 'fixes', target_project: target_project)
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
      expect(subject.merge_participants).to contain_exactly(subject.author)
    end

    describe 'when merge_when_pipeline_succeeds? is true' do
      describe 'when merge user is author' do
        let(:user) { create(:user) }

        subject do
          create(:merge_request, merge_when_pipeline_succeeds: true, merge_user: user, author: user)
        end

        context 'author is not a project member' do
          it 'is empty' do
            expect(subject.merge_participants).to be_empty
          end
        end

        context 'author is a project member' do
          before do
            subject.project.team.add_reporter(user)
          end

          it 'contains author only' do
            expect(subject.merge_participants).to contain_exactly(subject.author)
          end
        end
      end

      describe 'when merge user and author are different users' do
        let(:merge_user) { create(:user) }

        subject do
          create(:merge_request, merge_when_pipeline_succeeds: true, merge_user: merge_user)
        end

        before do
          subject.project.team.add_reporter(subject.author)
        end

        context 'merge user is not a member' do
          it 'contains author only' do
            expect(subject.merge_participants).to contain_exactly(subject.author)
          end
        end

        context 'both author and merge users are project members' do
          before do
            subject.project.team.add_reporter(merge_user)
          end

          it 'contains author and merge user' do
            expect(subject.merge_participants).to contain_exactly(subject.author, merge_user)
          end
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

  describe '#in_locked_state', :clean_gitlab_redis_shared_state do
    let(:merge_request) { create(:merge_request, :opened) }

    context 'when the merge request does not change state' do
      it 'returns to previous state and has no errors on the object' do
        expect(merge_request.opened?).to eq(true)

        merge_request.in_locked_state do
          expect(merge_request.locked?).to eq(true)
          expect(Gitlab::MergeRequests::LockedSet.all).to eq([merge_request.id.to_s])
        end

        expect(merge_request.opened?).to eq(true)
        expect(merge_request.errors).to be_empty
        expect(Gitlab::MergeRequests::LockedSet.all).to be_empty
      end
    end

    context 'when the merge request is merged while locked' do
      it 'becomes merged and has no errors on the object' do
        expect(merge_request.opened?).to eq(true)

        merge_request.in_locked_state do
          expect(merge_request.locked?).to eq(true)
          expect(Gitlab::MergeRequests::LockedSet.all).to eq([merge_request.id.to_s])
          merge_request.mark_as_merged!
        end

        expect(merge_request.merged?).to eq(true)
        expect(merge_request.errors).to be_empty
        expect(Gitlab::MergeRequests::LockedSet.all).to be_empty
      end
    end

    context 'when adding to locked set fails' do
      before do
        allow(merge_request)
          .to receive(:add_to_locked_set)
          .and_raise(Redis::BaseConnectionError)
      end

      it 'does not lock MR' do
        expect do
          merge_request.in_locked_state do
            # Do nothing
          end
        end.to raise_error(Redis::BaseConnectionError)

        expect(merge_request).not_to be_locked
        expect(Gitlab::MergeRequests::LockedSet.all).to be_empty
      end
    end
  end

  describe '#schedule_cleanup_refs' do
    subject { merge_request.schedule_cleanup_refs(only: :train) }

    let(:merge_request) { build(:merge_request, source_project: create(:project, :repository)) }

    it 'deletes refs asynchronously' do
      expect(merge_request.target_project.repository)
        .to receive(:async_delete_refs)
        .with(merge_request.train_ref_path)

      subject
    end

    context 'when merge_request_delete_gitaly_refs_in_batches is disabled' do
      before do
        stub_feature_flags(merge_request_delete_gitaly_refs_in_batches: false)
      end

      it 'does schedule MergeRequests::CleanupRefWorker' do
        expect(MergeRequests::CleanupRefWorker).to receive(:perform_async).with(merge_request.id, 'train')

        subject
      end

      context 'when merge_request_cleanup_ref_worker_async is disabled' do
        before do
          stub_feature_flags(merge_request_delete_gitaly_refs_in_batches: false)
          stub_feature_flags(merge_request_cleanup_ref_worker_async: false)
        end

        it 'deletes all refs from the target project' do
          expect(merge_request.target_project.repository)
            .to receive(:delete_refs)
            .with(merge_request.train_ref_path)

          subject
        end
      end
    end
  end

  describe '#cleanup_refs' do
    subject { merge_request.cleanup_refs(only: only) }

    let(:merge_request) { build(:merge_request, source_project: create(:project, :repository)) }

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
      create(
        :merge_request,
        :merge_when_checks_pass,
        target_project: project,
        target_branch: 'master',
        source_project: project,
        source_branch: 'feature-1'
      )
    end

    let!(:merge_request4) do
      create(
        :merge_request,
        target_project: project,
        target_branch: 'master',
        source_project: fork,
        source_branch: 'fork-feature-2'
      )
    end

    let(:query) { described_class.with_auto_merge_enabled }

    it { expect(query).to contain_exactly(merge_request1) }
  end

  it_behaves_like 'versioned description'

  describe '#commits' do
    context 'persisted merge request' do
      context 'with a limit' do
        it 'returns a limited number of commits' do
          expect(subject.commits(limit: 2).map(&:sha)).to eq(
            %w[
              b83d6e391c22777fca1ed3012fce84f633d7fed0
              498214de67004b1da3d820901307bed2a68a8ef6
            ])
          expect(subject.commits(limit: 3).map(&:sha)).to eq(
            %w[
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

      context 'with a page' do
        it 'returns a limited number of commits for page' do
          expect(subject.commits(limit: 1, page: 1).map(&:sha)).to eq(
            %w[
              b83d6e391c22777fca1ed3012fce84f633d7fed0
            ])
          expect(subject.commits(limit: 1, page: 2).map(&:sha)).to eq(
            %w[
              498214de67004b1da3d820901307bed2a68a8ef6
            ])
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
      expect(subject.recent_commits.map(&:sha)).to eq(
        %w[
          b83d6e391c22777fca1ed3012fce84f633d7fed0 498214de67004b1da3d820901307bed2a68a8ef6
        ])
    end
  end

  describe '#recent_visible_deployments' do
    let(:merge_request) { create(:merge_request) }

    it 'returns visible deployments' do
      envs = create_list(:environment, 3, project: merge_request.target_project)

      created = create(
        :deployment,
        :created,
        project: merge_request.target_project,
        environment: envs[0]
      )

      success = create(
        :deployment,
        :success,
        project: merge_request.target_project,
        environment: envs[1]
      )

      failed = create(
        :deployment,
        :failed,
        project: merge_request.target_project,
        environment: envs[2]
      )

      merge_request_relation = described_class.where(id: merge_request.id)
      created.link_merge_requests(merge_request_relation)
      success.link_merge_requests(merge_request_relation)
      failed.link_merge_requests(merge_request_relation)

      expect(merge_request.recent_visible_deployments).to eq([failed, success])
    end

    it 'only returns a limited number of deployments' do
      20.times do
        environment = create(:environment, project: merge_request.target_project)
        deploy = create(
          :deployment,
          :success,
          project: merge_request.target_project,
          environment: environment
        )

        deploy.link_merge_requests(MergeRequest.where(id: merge_request.id))
      end

      expect(merge_request.recent_visible_deployments.count).to eq(10)
    end
  end

  describe '#diffable_merge_ref?' do
    let(:merge_request) { create(:merge_request) }

    context 'merge request can be merged' do
      context 'merge_head diff is not created' do
        it 'returns true' do
          expect(merge_request.diffable_merge_ref?).to eq(false)
        end
      end

      context 'merge_head diff is created' do
        before do
          create(:merge_request_diff, :merge_head, merge_request: merge_request)
        end

        it 'returns true' do
          expect(merge_request.diffable_merge_ref?).to eq(true)
        end

        context 'merge request is merged' do
          before do
            merge_request.mark_as_merged!
          end

          it 'returns false' do
            expect(merge_request.diffable_merge_ref?).to eq(false)
          end
        end

        context 'merge request cannot be merged' do
          before do
            merge_request.mark_as_unchecked!
          end

          it 'returns false' do
            expect(merge_request.diffable_merge_ref?).to eq(false)
          end
        end
      end
    end
  end

  describe '#predefined_variables' do
    let(:merge_request) { create(:merge_request) }

    it 'caches all SQL-sourced data on the first call' do
      control = ActiveRecord::QueryRecorder.new { merge_request.predefined_variables }.count

      expect(control).to be > 0

      count = ActiveRecord::QueryRecorder.new { merge_request.predefined_variables }.count

      expect(count).to eq(0)
    end
  end

  describe 'banzai_render_context' do
    let(:project) { build(:project_empty_repo) }
    let(:merge_request) { build :merge_request, target_project: project, source_project: project }

    subject(:context) { merge_request.banzai_render_context(:title) }

    it 'sets the label_url_method in the context' do
      expect(context[:label_url_method]).to eq(:project_merge_requests_url)
    end
  end

  describe '#head_pipeline_builds_with_coverage' do
    it 'delegates to head_pipeline' do
      expect(subject)
        .to delegate_method(:builds_with_coverage)
        .to(:head_pipeline)
        .with_prefix
        .allow_nil
    end
  end

  describe '#merge_ref_head' do
    let(:merge_request) { create(:merge_request) }

    context 'when merge_ref_sha is not present' do
      let!(:result) do
        MergeRequests::MergeToRefService
          .new(project: merge_request.project, current_user: merge_request.author)
          .execute(merge_request)
      end

      it 'returns the commit based on merge ref path' do
        expect(merge_request.merge_ref_head.id).to eq(result[:commit_id])
      end
    end

    context 'when merge_ref_sha is present' do
      before do
        merge_request.update!(merge_ref_sha: merge_request.project.repository.commit.id)
      end

      it 'returns the commit based on cached merge_ref_sha' do
        expect(merge_request.merge_ref_head.id).to eq(merge_request.merge_ref_sha)
      end
    end
  end

  describe '#allows_reviewers?' do
    it 'returns true' do
      merge_request = build_stubbed(:merge_request)

      expect(merge_request.allows_reviewers?).to be(true)
    end
  end

  describe '#update_and_mark_in_progress_merge_commit_sha' do
    let(:ref) { subject.target_project.repository.commit.id }

    before do
      expect(subject.target_project.sticking).to receive(:stick)
        .with(:project, subject.target_project.id)
    end

    it 'updates commit ID' do
      expect { subject.update_and_mark_in_progress_merge_commit_sha(ref) }
        .to change { subject.in_progress_merge_commit_sha }
        .from(nil).to(ref)
    end
  end

  describe '#enabled_reports' do
    let(:project) { create(:project, :repository) }

    where(:report_type, :with_reports, :feature) do
      :sast                | :with_sast_reports                | :sast
      :secret_detection    | :with_secret_detection_reports    | :secret_detection
    end

    with_them do
      subject { merge_request.enabled_reports[report_type] }

      before do
        stub_licensed_features({ feature => true })
      end

      context "when head pipeline has reports" do
        let(:merge_request) { create(:merge_request, with_reports, source_project: project) }

        it { is_expected.to be_truthy }
      end

      context "when head pipeline does not have reports" do
        let(:merge_request) { create(:merge_request, source_project: project) }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#includes_ci_config?' do
    let(:merge_request) { build(:merge_request) }
    let(:project) { merge_request.project }

    subject(:result) { merge_request.includes_ci_config? }

    before do
      allow(merge_request).to receive(:diff_stats).and_return(diff_stats)
    end

    context 'when diff_stats is nil' do
      let(:diff_stats) {}

      it { is_expected.to eq(false) }
    end

    context 'when diff_stats does not include the ci config path of the project' do
      let(:diff_stats) { [double(path: 'abc.txt')] }

      it { is_expected.to eq(false) }
    end

    context 'when diff_stats includes the ci config path of the project' do
      let(:diff_stats) { [double(path: '.gitlab-ci.yml')] }

      it { is_expected.to eq(true) }
    end
  end

  describe '.from_fork' do
    let!(:project) { create(:project, :repository) }
    let!(:forked_project) { fork_project(project) }
    let!(:fork_mr) { create(:merge_request, source_project: forked_project, target_project: project) }
    let!(:regular_mr) { create(:merge_request, source_project: project) }

    it 'returns merge requests from forks only' do
      expect(described_class.from_fork).to eq([fork_mr])
    end
  end

  it_behaves_like 'it has loose foreign keys' do
    let(:factory_name) { :merge_request }
  end

  context 'loose foreign key on merge_requests.head_pipeline_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:ci_pipeline) }
      let!(:model) { create(:merge_request, head_pipeline: parent) }
    end
  end

  describe '#merge_blocked_by_other_mrs?' do
    it 'returns false when there is no blocking merge requests' do
      expect(subject.merge_blocked_by_other_mrs?).to be_falsy
    end
  end

  describe '#merge_request_reviewers_with' do
    let_it_be(:reviewer1) { create(:user) }
    let_it_be(:reviewer2) { create(:user) }

    before do
      subject.update!(reviewers: [reviewer1, reviewer2])
    end

    it 'returns reviewers' do
      reviewers = subject.merge_request_reviewers_with([reviewer1.id])

      expect(reviewers).to match_array([subject.merge_request_reviewers[0]])
    end
  end

  describe '#merge_request_assignees_with' do
    let_it_be(:assignee1) { create(:user) }
    let_it_be(:assignee2) { create(:user) }

    before do
      subject.update!(assignees: [assignee1, assignee2])
    end

    it 'returns assignees' do
      assignees = subject.merge_request_assignees_with([assignee1.id])

      expect(assignees).to match_array([subject.merge_request_assignees[0]])
    end
  end

  describe '#recent_diff_head_shas' do
    let_it_be(:merge_request_with_diffs) do
      params = {
        target_project: project,
        source_project: project,
        target_branch: 'master',
        source_branch: 'feature'
      }

      create(:merge_request, params).tap do |mr|
        4.times { mr.merge_request_diffs.create! }
        mr.create_merge_head_diff
      end
    end

    let(:shas) do
      # re-find to avoid caching the association
      described_class.find(merge_request_with_diffs.id).merge_request_diffs.order(id: :desc).pluck(:head_commit_sha)
    end

    shared_examples 'correctly sorted and limited diff_head_shas' do
      it 'has up to MAX_RECENT_DIFF_HEAD_SHAS, ordered most recent first' do
        stub_const('MergeRequest::MAX_RECENT_DIFF_HEAD_SHAS', 3)

        expect(subject.recent_diff_head_shas).to eq(shas.first(3))
      end

      it 'supports limits' do
        expect(subject.recent_diff_head_shas(2)).to eq(shas.first(2))
      end
    end

    context 'when the association is not loaded' do
      subject(:mr) { merge_request_with_diffs }

      include_examples 'correctly sorted and limited diff_head_shas'
    end

    context 'when the association is loaded' do
      subject(:mr) do
        described_class.where(id: merge_request_with_diffs.id).preload(:merge_request_diffs).first
      end

      include_examples 'correctly sorted and limited diff_head_shas'

      it 'does not issue any queries' do
        expect(subject).to be_a(described_class) # preload here

        expect { subject.recent_diff_head_shas }.not_to exceed_query_limit(0)
      end
    end
  end

  describe '#target_default_branch?' do
    let_it_be(:merge_request) { build(:merge_request, project: project) }

    it 'returns false' do
      expect(merge_request.target_default_branch?).to be false
    end

    context 'with target_branch equal project default branch' do
      before do
        merge_request.target_branch = "master"
      end

      it 'returns false' do
        expect(merge_request.target_default_branch?).to be true
      end
    end
  end

  describe '#can_suggest_reviewers?' do
    let_it_be(:merge_request) { build(:merge_request, :opened, project: project) }

    subject(:can_suggest_reviewers) { merge_request.can_suggest_reviewers? }

    it 'returns false' do
      expect(can_suggest_reviewers).to be(false)
    end
  end

  describe '#suggested_reviewer_users' do
    let_it_be(:merge_request) { build(:merge_request, project: project) }

    subject(:suggested_reviewer_users) { merge_request.suggested_reviewer_users }

    it { is_expected.to be_empty }
  end

  describe '#hidden?', feature_category: :insider_threat do
    let_it_be(:author) { create(:user) }
    let(:merge_request) { build_stubbed(:merge_request, author: author) }

    subject { merge_request.hidden? }

    it { is_expected.to eq(false) }

    context 'when the author is banned' do
      let_it_be(:author) { create(:user, :banned) }

      it { is_expected.to eq(true) }

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(hide_merge_requests_from_banned_users: false)
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#diffs_batch_cache_with_max_age?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    subject(:diffs_batch_cache_with_max_age?) { merge_request.diffs_batch_cache_with_max_age? }

    it 'returns true' do
      expect(diffs_batch_cache_with_max_age?).to be_truthy
    end

    context 'when diffs_batch_cache_with_max_age is disabled' do
      before do
        stub_feature_flags(diffs_batch_cache_with_max_age: false)
      end

      it 'returns false' do
        expect(diffs_batch_cache_with_max_age?).to be_falsey
      end
    end
  end

  describe '#prepared?' do
    subject(:merge_request) { build_stubbed(:merge_request, prepared_at: prepared_at) }

    context 'when prepared_at is nil' do
      let(:prepared_at) { nil }

      it 'returns false' do
        expect(merge_request.prepared?).to be_falsey
      end
    end

    context 'when prepared_at is not nil' do
      let(:prepared_at) { Time.current }

      it 'returns true' do
        expect(merge_request.prepared?).to be_truthy
      end
    end
  end

  describe 'prepare' do
    it 'calls NewMergeRequestWorker' do
      expect(NewMergeRequestWorker).to receive(:perform_async)
        .with(subject.id, subject.author_id)

      subject.prepare
    end
  end

  describe '#check_for_spam?' do
    let_it_be(:project) { create(:project, :public) }
    let(:merge_request) { build_stubbed(:merge_request, source_project: project) }

    subject { merge_request.check_for_spam? }

    before do
      merge_request.title = 'New title'
    end

    it { is_expected.to eq(true) }

    context 'when project is private' do
      let_it_be(:project) { create(:project, :private) }

      it { is_expected.to eq(false) }
    end

    context 'when no spammable attribute has changed' do
      before do
        merge_request.title = merge_request.title_was
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#supports_lock_on_merge?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    subject { merge_request.supports_lock_on_merge? }

    context 'when MR is open' do
      it { is_expected.to eq(false) }
    end

    context 'when MR is merged' do
      before do
        merge_request.state = :merged
      end

      it { is_expected.to eq(true) }

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(enforce_locked_labels_on_merge: false)
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#missing_required_squash?' do
    using RSpec::Parameterized::TableSyntax

    where(:squash, :require_squash, :expected) do
      false | true  | true
      false | false | false
      true  | true  | false
      true  | false | false
    end

    with_them do
      let(:merge_request) { build_stubbed(:merge_request, squash: squash, project: project) }

      subject { merge_request.missing_required_squash? }

      before do
        allow(project.project_setting).to receive(:squash_always?).and_return(require_squash)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#current_patch_id_sha' do
    let(:merge_request) { build_stubbed(:merge_request) }
    let(:merge_request_diff) { build_stubbed(:merge_request_diff) }
    let(:patch_id) { 'ghi789' }

    subject(:current_patch_id_sha) { merge_request.current_patch_id_sha }

    before do
      allow(merge_request).to receive(:latest_merge_request_diff).and_return(merge_request_diff)
      allow(merge_request_diff).to receive(:patch_id_sha).and_return(patch_id)
    end

    it { is_expected.to eq(patch_id) }
  end

  describe '#all_mergeability_checks_results' do
    let(:merge_request) { build_stubbed(:merge_request) }
    let(:result) { instance_double(ServiceResponse, payload: { results: ['result'] }) }

    it 'executes MergeRequests::Mergeability::RunChecksService with all mergeability checks' do
      expect_next_instance_of(
        MergeRequests::Mergeability::RunChecksService,
        merge_request: merge_request,
        params: {}
      ) do |svc|
        expect(svc)
          .to receive(:execute)
          .with(described_class.all_mergeability_checks, execute_all: true)
          .and_return(result)
      end

      expect(merge_request.all_mergeability_checks_results).to eq(result.payload[:results])
    end
  end

  describe '#mergeability_checks_pass?' do
    let(:merge_request) { build_stubbed(:merge_request) }
    let(:result) { instance_double(ServiceResponse, success?: { results: ['result'] }) }

    it 'executes MergeRequests::Mergeability::RunChecksService with all mergeability checks and returns a boolean' do
      expect_next_instance_of(
        MergeRequests::Mergeability::RunChecksService,
        merge_request: merge_request,
        params: {}
      ) do |svc|
        expect(svc)
          .to receive(:execute)
          .with(described_class.all_mergeability_checks, execute_all: false)
          .and_return(result)
      end

      expect(merge_request.mergeability_checks_pass?).to be_truthy
    end
  end

  describe '#only_allow_merge_if_pipeline_succeeds?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    subject(:result) { merge_request.only_allow_merge_if_pipeline_succeeds? }

    before do
      allow(merge_request.project)
        .to receive(:only_allow_merge_if_pipeline_succeeds?)
        .with(inherit_group_setting: true)
        .and_return(only_allow_merge_if_pipeline_succeeds?)
    end

    context 'when associated project only_allow_merge_if_pipeline_succeeds? returns true' do
      let(:only_allow_merge_if_pipeline_succeeds?) { true }

      it { is_expected.to eq(true) }
    end

    context 'when associated project only_allow_merge_if_pipeline_succeeds? returns false' do
      let(:only_allow_merge_if_pipeline_succeeds?) { false }

      it { is_expected.to eq(false) }
    end
  end

  describe '#only_allow_merge_if_all_discussions_are_resolved?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    subject(:result) { merge_request.only_allow_merge_if_all_discussions_are_resolved? }

    before do
      allow(merge_request.project)
        .to receive(:only_allow_merge_if_all_discussions_are_resolved?)
        .with(inherit_group_setting: true)
        .and_return(only_allow_merge_if_all_discussions_are_resolved?)
    end

    context 'when associated project only_allow_merge_if_all_discussions_are_resolved? returns true' do
      let(:only_allow_merge_if_all_discussions_are_resolved?) { true }

      it { is_expected.to eq(true) }
    end

    context 'when associated project only_allow_merge_if_all_discussions_are_resolved? returns false' do
      let(:only_allow_merge_if_all_discussions_are_resolved?) { false }

      it { is_expected.to eq(false) }
    end
  end

  describe '#allow_merge_without_pipeline?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    subject(:result) { merge_request.allow_merge_without_pipeline? }

    before do
      allow(merge_request.project)
        .to receive(:allow_merge_without_pipeline?)
        .with(inherit_group_setting: true)
        .and_return(allow_merge_without_pipeline?)
    end

    context 'when associated project allow_merge_without_pipeline? returns true' do
      let(:allow_merge_without_pipeline?) { true }

      it { is_expected.to eq(true) }
    end

    context 'when associated project allow_merge_without_pipeline? returns false' do
      let(:allow_merge_without_pipeline?) { false }

      it { is_expected.to eq(false) }
    end
  end

  describe '#temporarily_unapproved?' do
    subject(:temporarily_unapproved) { merge_request.temporarily_unapproved? }

    let(:merge_request) { build_stubbed(:merge_request) }

    it { is_expected.to eq(false) }
  end

  describe '#has_jira_issue_keys?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    subject(:has_jira_issue_keys) { merge_request.has_jira_issue_keys? }

    context 'when project has jira integration' do
      let(:jira_integration) { build(:jira_integration) }

      before do
        allow(merge_request.project).to receive(:jira_integration).and_return(jira_integration)
      end

      context 'when the merge request title has a key' do
        before do
          merge_request.title = 'PROJECT-1'
        end

        it 'returns true' do
          expect(has_jira_issue_keys).to be_truthy
        end
      end

      context 'when the merge request title has a key' do
        before do
          merge_request.description = 'PROJECT-1'
        end

        it 'returns true' do
          expect(has_jira_issue_keys).to be_truthy
        end
      end

      context 'when the merge request does not have a key' do
        it 'returns false' do
          expect(has_jira_issue_keys).to be_falsey
        end
      end
    end

    context 'when project does not have jira integration' do
      it 'returns false' do
        expect(has_jira_issue_keys).to be_falsey
      end
    end
  end

  describe '#allows_multiple_assignees?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    subject(:allows_multiple_assignees?) { merge_request.allows_multiple_assignees? }

    before do
      allow(merge_request.project)
        .to receive(:allows_multiple_merge_request_assignees?)
        .and_return(false)
    end

    it { is_expected.to eq(false) }
  end

  describe '#allows_multiple_reviewers?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    subject(:allows_multiple_reviewers?) { merge_request.allows_multiple_reviewers? }

    before do
      allow(merge_request.project)
        .to receive(:allows_multiple_merge_request_reviewers?)
        .and_return(false)
    end

    it { is_expected.to eq(false) }
  end

  describe '#previous_diff' do
    let(:merge_request) { create(:merge_request, :skip_diff_creation) }

    subject { merge_request.previous_diff }

    context 'when there is are no merge_request_diffs' do
      it { is_expected.to be_nil }
    end

    context 'when there is one merge request_diff' do
      let(:merge_request) { create(:merge_request) }

      it { is_expected.to be_nil }
    end

    context 'when there are multiple merge_request_diffs' do
      let(:oldest_merge_request_diff) { create(:merge_request_diff, merge_request: merge_request) }
      let(:second_to_last_merge_request_diff) { create(:merge_request_diff, merge_request: merge_request) }
      let(:most_recent_merge_request_diff) { create(:merge_request_diff, merge_request: merge_request) }

      before do
        oldest_merge_request_diff
        second_to_last_merge_request_diff
        most_recent_merge_request_diff
      end

      it { is_expected.to eq(second_to_last_merge_request_diff) }
    end
  end

  describe '#batch_update_reviewer_state' do
    let_it_be(:merge_request) { create(:merge_request, reviewers: create_list(:user, 2)) }

    it 'updates all reviewers' do
      user_ids = merge_request.reviewers.map(&:id)

      expect { merge_request.batch_update_reviewer_state(user_ids, :reviewed) }.to change { merge_request.merge_request_reviewers.reload.all?(&:reviewed?) }.from(false).to(true)
    end
  end

  describe '#diff_head_pipeline_considered_in_progress?' do
    let(:merge_request) { build(:merge_request, project: project) }

    subject { merge_request.diff_head_pipeline_considered_in_progress? }

    context 'when there is no pipeline' do
      it { is_expected.to be_falsy }
    end

    context 'when there is a pipeline' do
      before do
        merge_request.head_pipeline = build(:ci_pipeline, sha: merge_request.diff_head_sha, status: pipeline_status)
        allow(merge_request).to receive(:only_allow_merge_if_pipeline_succeeds?).and_return(pipelines_must_succeed)
      end

      where(:pipeline_status, :pipelines_must_succeed, :expected) do
        # completed statuses
        'success'   | false | false
        'failed'    | false | false
        'canceled'  | false | false
        'skipped'   | false | false
        # not completed, pipeline must succeed disabled
        'created'   | false | true
        'pending'   | false | true
        'running'   | false | true
        'scheduled' | false | false
        'manual'    | false | false
        # not completed, pipeline must succeed enabled
        'created'   | true  | true
        'pending'   | true  | true
        'running'   | true  | true
        'scheduled' | true  | true
        'manual'    | true  | true
      end

      with_them do
        it { is_expected.to be expected }
      end
    end
  end

  describe '#diffs_for_streaming' do
    let(:base_diff) do
      instance_double(
        MergeRequestDiff,
        diffs: ['base diff']
      )
    end

    let(:head_diff) do
      instance_double(
        MergeRequestDiff,
        diffs: ['HEAD diff']
      )
    end

    let(:merge_request) { build_stubbed(:merge_request) }
    let(:diffable_merge_ref?) { false }

    before do
      allow(merge_request)
        .to receive(:diffable_merge_ref?)
        .and_return(diffable_merge_ref?)

      allow(merge_request)
        .to receive(:merge_request_diff)
        .and_return(base_diff)

      allow(merge_request)
        .to receive(:merge_head_diff)
        .and_return(head_diff)
    end

    it 'returns diffs from base diff' do
      expect(merge_request.diffs_for_streaming).to eq(['base diff'])
    end

    context 'when HEAD diff is diffable' do
      let(:diffable_merge_ref?) { true }

      it 'returns diffs from HEAD diff' do
        expect(merge_request.diffs_for_streaming).to eq(['HEAD diff'])
      end
    end

    context 'when block is given' do
      let(:diff_refs) { instance_double(Gitlab::Diff::DiffRefs) }
      let(:expected_block) { proc {} }
      let(:repository) { merge_request.source_project.repository }

      before do
        allow(base_diff).to receive(:diff_refs).and_return(diff_refs)
      end

      it 'calls diffs_by_changed_paths with given offset' do
        expect(repository).to receive(:diffs_by_changed_paths).with(diff_refs, 0) do |_, &block|
          expect(block).to be(expected_block)
        end

        merge_request.diffs_for_streaming(&expected_block)
      end

      context 'when offset_index is given' do
        let(:offset) { 5 }

        it 'calls diffs_by_changed_paths with given offset' do
          expect(repository).to receive(:diffs_by_changed_paths).with(diff_refs, offset) do |_, &block|
            expect(block).to be(expected_block)
          end

          merge_request.diffs_for_streaming({ offset_index: offset }, &expected_block)
        end
      end
    end
  end

  describe '#merge_exclusive_lease' do
    let(:merge_request) { build_stubbed(:merge_request) }

    it 'returns a Gitlab::ExclusiveLease instance' do
      expect(merge_request.merge_exclusive_lease).to be_a(Gitlab::ExclusiveLease)
    end
  end

  describe '#source_and_target_branches_exist?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    before do
      allow(merge_request).to receive(:source_branch_sha).and_return(source_branch_sha)
      allow(merge_request).to receive(:target_branch_sha).and_return(target_branch_sha)
    end

    context 'when both source_branch_sha and target_branch_sha are present' do
      let(:source_branch_sha) { 'abc123' }
      let(:target_branch_sha) { 'def456' }

      it 'returns true' do
        expect(merge_request.source_and_target_branches_exist?).to eq(true)
      end
    end

    context 'when source_branch_sha is nil' do
      let(:source_branch_sha) { nil }
      let(:target_branch_sha) { 'def456' }

      it 'returns false' do
        expect(merge_request.source_and_target_branches_exist?).to eq(false)
      end
    end

    context 'when target_branch_sha is nil' do
      let(:source_branch_sha) { 'abc123' }
      let(:target_branch_sha) { nil }

      it 'returns false' do
        expect(merge_request.source_and_target_branches_exist?).to eq(false)
      end
    end
  end

  describe '#has_diffs?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    before do
      allow_next_instance_of(Gitlab::Git::Compare) do |compare|
        allow(compare).to receive(:diffs).and_return(diff_collection)
      end
    end

    context 'when Gitlab::Git::Compare#diffs returns `true` as `any?`' do
      let(:diff_collection) { instance_double(Gitlab::Git::DiffCollection, any?: true) }

      it 'returns true' do
        expect(merge_request.has_diffs?).to eq(true)
      end
    end

    context 'when Gitlab::Git::Compare#diffs returns `false` as `any?`' do
      let(:diff_collection) { instance_double(Gitlab::Git::DiffCollection, any?: false) }

      it 'returns false' do
        expect(merge_request.has_diffs?).to eq(false)
      end
    end
  end

  describe '#add_to_locked_set' do
    it 'calls Gitlab::MergeRequests::LockedSet.add' do
      expect(Gitlab::MergeRequests::LockedSet)
        .to receive(:add)
        .with(subject.id, rescue_connection_error: false)

      subject.add_to_locked_set
    end

    context 'when unstick_locked_merge_requests_redis is disabled' do
      before do
        stub_feature_flags(unstick_locked_merge_requests_redis: false)
      end

      it 'does not call Gitlab::MergeRequests::LockedSet.add' do
        expect(Gitlab::MergeRequests::LockedSet).not_to receive(:add)

        subject.add_to_locked_set
      end
    end
  end

  describe '#remove_from_locked_set' do
    it 'calls Gitlab::MergeRequests::LockedSet.remove' do
      expect(Gitlab::MergeRequests::LockedSet)
        .to receive(:remove)
        .with(subject.id)

      subject.remove_from_locked_set
    end

    context 'when unstick_locked_merge_requests_redis is disabled' do
      before do
        stub_feature_flags(unstick_locked_merge_requests_redis: false)
      end

      it 'does not call Gitlab::MergeRequests::LockedSet.remove' do
        expect(Gitlab::MergeRequests::LockedSet).not_to receive(:remove)

        subject.remove_from_locked_set
      end
    end
  end

  describe '#first_diffs_slice' do
    let_it_be(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
    let_it_be(:limit) { 5 }

    subject { merge_request.first_diffs_slice(limit) }

    it 'returns limited diffs' do
      expect(subject.count).to eq(limit)
    end
  end

  describe '#squash_on_merge?' do
    let(:merge_request) { build_stubbed(:merge_request) }

    where(:squash_always, :squash_never, :squash, :expected) do
      true  | false | false | true
      true  | false | true  | true
      false | true  | false | false
      false | true  | true  | false
      false | false | true  | true
      false | false | false | false
    end

    with_them do
      subject { merge_request.squash_on_merge? }

      before do
        allow(merge_request).to receive_messages(squash_always?: squash_always, squash_never?: squash_never, squash?: squash)
      end

      it { is_expected.to eq(expected) }
    end
  end
end
