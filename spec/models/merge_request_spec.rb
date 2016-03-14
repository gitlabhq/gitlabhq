# == Schema Information
#
# Table name: merge_requests
#
#  id                        :integer          not null, primary key
#  target_branch             :string(255)      not null
#  source_branch             :string(255)      not null
#  source_project_id         :integer          not null
#  author_id                 :integer
#  assignee_id               :integer
#  title                     :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  milestone_id              :integer
#  state                     :string(255)
#  merge_status              :string(255)
#  target_project_id         :integer          not null
#  iid                       :integer
#  description               :text
#  position                  :integer          default(0)
#  locked_at                 :datetime
#  updated_by_id             :integer
#  merge_error               :string(255)
#  merge_params              :text
#  merge_when_build_succeeds :boolean          default(FALSE), not null
#  merge_user_id             :integer
#  merge_commit_sha          :string
#

require 'spec_helper'

describe MergeRequest, models: true do
  subject { create(:merge_request) }

  describe 'associations' do
    it { is_expected.to belong_to(:target_project).with_foreign_key(:target_project_id).class_name('Project') }
    it { is_expected.to belong_to(:source_project).with_foreign_key(:source_project_id).class_name('Project') }
    it { is_expected.to belong_to(:merge_user).class_name("User") }
    it { is_expected.to have_one(:merge_request_diff).dependent(:destroy) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(InternalId) }
    it { is_expected.to include_module(Issuable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(Taskable) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:target_branch) }
    it { is_expected.to validate_presence_of(:source_branch) }

    context "Validation of merge user with Merge When Build succeeds" do
      it "allows user to be nil when the feature is disabled" do
        expect(subject).to be_valid
      end

      it "is invalid without merge user" do
        subject.merge_when_build_succeeds = true
        expect(subject).not_to be_valid
      end

      it "is valid with merge user" do
        subject.merge_when_build_succeeds = true
        subject.merge_user = build(:user)

        expect(subject).to be_valid
      end
    end
  end

  describe 'respond to' do
    it { is_expected.to respond_to(:unchecked?) }
    it { is_expected.to respond_to(:can_be_merged?) }
    it { is_expected.to respond_to(:cannot_be_merged?) }
    it { is_expected.to respond_to(:merge_params) }
    it { is_expected.to respond_to(:merge_when_build_succeeds) }
  end

  describe '.in_projects' do
    it 'returns the merge requests for a set of projects' do
      expect(described_class.in_projects(Project.all)).to eq([subject])
    end
  end

  describe '#to_reference' do
    it 'returns a String reference to the object' do
      expect(subject.to_reference).to eq "!#{subject.iid}"
    end

    it 'supports a cross-project reference' do
      cross = double('project')
      expect(subject.to_reference(cross)).to eq "#{subject.source_project.to_reference}!#{subject.iid}"
    end
  end

  describe "#mr_and_commit_notes" do
    let!(:merge_request) { create(:merge_request) }

    before do
      allow(merge_request).to receive(:commits) { [merge_request.source_project.repository.commit] }
      create(:note, commit_id: merge_request.commits.first.id, noteable_type: 'Commit', project: merge_request.project)
      create(:note, noteable: merge_request, project: merge_request.project)
    end

    it "should include notes for commits" do
      expect(merge_request.commits).not_to be_empty
      expect(merge_request.mr_and_commit_notes.count).to eq(2)
    end

    it "should include notes for commits from target project as well" do
      create(:note, commit_id: merge_request.commits.first.id, noteable_type: 'Commit', project: merge_request.target_project)
      expect(merge_request.commits).not_to be_empty
      expect(merge_request.mr_and_commit_notes.count).to eq(3)
    end
  end

  describe '#is_being_reassigned?' do
    it 'returns true if the merge_request assignee has changed' do
      subject.assignee = create(:user)
      expect(subject.is_being_reassigned?).to be_truthy
    end
    it 'returns false if the merge request assignee has not changed' do
      expect(subject.is_being_reassigned?).to be_falsey
    end
  end

  describe '#for_fork?' do
    it 'returns true if the merge request is for a fork' do
      subject.source_project = create(:project, namespace: create(:group))
      subject.target_project = create(:project, namespace: create(:group))

      expect(subject.for_fork?).to be_truthy
    end

    it 'returns false if is not for a fork' do
      expect(subject.for_fork?).to be_falsey
    end
  end

  describe 'detection of issues to be closed' do
    let(:issue0) { create :issue, project: subject.project }
    let(:issue1) { create :issue, project: subject.project }

    let(:commit0) { double('commit0', safe_message: "Fixes #{issue0.to_reference}") }
    let(:commit1) { double('commit1', safe_message: "Fixes #{issue0.to_reference}") }
    let(:commit2) { double('commit2', safe_message: "Fixes #{issue1.to_reference}") }

    before do
      allow(subject).to receive(:commits).and_return([commit0, commit1, commit2])
    end

    it 'accesses the set of issues that will be closed on acceptance' do
      allow(subject.project).to receive(:default_branch).
        and_return(subject.target_branch)

      closed = subject.closes_issues

      expect(closed).to include(issue0, issue1)
    end

    it 'only lists issues as to be closed if it targets the default branch' do
      allow(subject.project).to receive(:default_branch).and_return('master')
      subject.target_branch = 'something-else'

      expect(subject.closes_issues).to be_empty
    end

    it 'detects issues mentioned in the description' do
      issue2 = create(:issue, project: subject.project)
      subject.description = "Closes #{issue2.to_reference}"
      allow(subject.project).to receive(:default_branch).
        and_return(subject.target_branch)

      expect(subject.closes_issues).to include(issue2)
    end
  end

  describe "#work_in_progress?" do
    it "detects the 'WIP ' prefix" do
      subject.title = "WIP #{subject.title}"
      expect(subject).to be_work_in_progress
    end

    it "detects the 'WIP: ' prefix" do
      subject.title = "WIP: #{subject.title}"
      expect(subject).to be_work_in_progress
    end

    it "detects the '[WIP] ' prefix" do
      subject.title = "[WIP] #{subject.title}"
      expect(subject).to be_work_in_progress
    end

    it "detects the '[WIP]' prefix" do
      subject.title = "[WIP]#{subject.title}"
      expect(subject).to be_work_in_progress
    end

    it "doesn't detect WIP for words starting with WIP" do
      subject.title = "Wipwap #{subject.title}"
      expect(subject).not_to be_work_in_progress
    end

    it "doesn't detect WIP by default" do
      expect(subject).not_to be_work_in_progress
    end
  end

  describe '#can_remove_source_branch?' do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }

    before do
      subject.source_project.team << [user, :master]

      subject.source_branch = "feature"
      subject.target_branch = "master"
      subject.save!
    end

    it "can't be removed when its a protected branch" do
      allow(subject.source_project).to receive(:protected_branch?).and_return(true)
      expect(subject.can_remove_source_branch?(user)).to be_falsey
    end

    it "cant remove a root ref" do
      subject.source_branch = "master"
      subject.target_branch = "feature"

      expect(subject.can_remove_source_branch?(user)).to be_falsey
    end

    it "is unable to remove the source branch for a project the user cannot push to" do
      expect(subject.can_remove_source_branch?(user2)).to be_falsey
    end

    it "can be removed if the last commit is the head of the source branch" do
      allow(subject.source_project).to receive(:commit).and_return(subject.last_commit)

      expect(subject.can_remove_source_branch?(user)).to be_truthy
    end

    it "cannot be removed if the last commit is not also the head of the source branch" do
      expect(subject.can_remove_source_branch?(user)).to be_falsey
    end
  end

  describe "#reset_merge_when_build_succeeds" do
    let(:merge_if_green) { create :merge_request, merge_when_build_succeeds: true, merge_user: create(:user) }

    it "sets the item to false" do
      merge_if_green.reset_merge_when_build_succeeds
      merge_if_green.reload

      expect(merge_if_green.merge_when_build_succeeds).to be_falsey
    end
  end

  describe "#hook_attrs" do
    let(:attrs_hash) { subject.hook_attrs.to_h }

    [:source, :target].each do |key|
      describe "#{key} key" do
        include_examples 'project hook data', project_key: key do
          let(:data)    { attrs_hash }
          let(:project) { subject.send("#{key}_project") }
        end
      end
    end

    it "has all the required keys" do
      expect(attrs_hash).to include(:source)
      expect(attrs_hash).to include(:target)
      expect(attrs_hash).to include(:last_commit)
      expect(attrs_hash).to include(:work_in_progress)
    end
  end

  describe '#diverged_commits_count' do
    let(:project)      { create(:project) }
    let(:fork_project) { create(:project, forked_from_project: project) }

    context 'diverged on same repository' do
      subject(:merge_request_with_divergence) { create(:merge_request, :diverged, source_project: project, target_project: project) }

      it 'counts commits that are on target branch but not on source branch' do
        expect(subject.diverged_commits_count).to eq(5)
      end
    end

    context 'diverged on fork' do
      subject(:merge_request_fork_with_divergence) { create(:merge_request, :diverged, source_project: fork_project, target_project: project) }

      it 'counts commits that are on target branch but not on source branch' do
        expect(subject.diverged_commits_count).to eq(5)
      end
    end

    context 'rebased on fork' do
      subject(:merge_request_rebased) { create(:merge_request, :rebased, source_project: fork_project, target_project: project) }

      it 'counts commits that are on target branch but not on source branch' do
        expect(subject.diverged_commits_count).to eq(0)
      end
    end

    describe 'caching' do
      before(:example) do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      end

      it 'caches the output' do
        expect(subject).to receive(:compute_diverged_commits_count).
          once.
          and_return(2)

        subject.diverged_commits_count
        subject.diverged_commits_count
      end

      it 'invalidates the cache when the source sha changes' do
        expect(subject).to receive(:compute_diverged_commits_count).
          twice.
          and_return(2)

        subject.diverged_commits_count
        allow(subject).to receive(:source_sha).and_return('123abc')
        subject.diverged_commits_count
      end

      it 'invalidates the cache when the target sha changes' do
        expect(subject).to receive(:compute_diverged_commits_count).
          twice.
          and_return(2)

        subject.diverged_commits_count
        allow(subject).to receive(:target_sha).and_return('123abc')
        subject.diverged_commits_count
      end
    end
  end

  it_behaves_like 'an editable mentionable' do
    subject { create(:merge_request) }

    let(:backref_text) { "merge request #{subject.to_reference}" }
    let(:set_mentionable_text) { ->(txt){ subject.description = txt } }
  end

  it_behaves_like 'a Taskable' do
    subject { create :merge_request, :simple }
  end

  describe '#ci_commit' do
    describe 'when the source project exists' do
      it 'returns the latest commit' do
        commit    = double(:commit, id: '123abc')
        ci_commit = double(:ci_commit)

        allow(subject).to receive(:last_commit).and_return(commit)

        expect(subject.source_project).to receive(:ci_commit).
          with('123abc').
          and_return(ci_commit)

        expect(subject.ci_commit).to eq(ci_commit)
      end
    end

    describe 'when the source project does not exist' do
      it 'returns nil' do
        allow(subject).to receive(:source_project).and_return(nil)

        expect(subject.ci_commit).to be_nil
      end
    end
  end
end
