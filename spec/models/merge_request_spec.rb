# == Schema Information
#
# Table name: merge_requests
#
#  id                :integer          not null, primary key
#  target_branch     :string(255)      not null
#  source_branch     :string(255)      not null
#  source_project_id :integer          not null
#  author_id         :integer
#  assignee_id       :integer
#  title             :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  st_commits        :text(2147483647)
#  st_diffs          :text(2147483647)
#  milestone_id      :integer
#  state             :string(255)
#  merge_status      :string(255)
#  target_project_id :integer          not null
#  iid               :integer
#  description       :text
#

require 'spec_helper'

describe MergeRequest do
  describe "Validation" do
    it { should validate_presence_of(:target_branch) }
    it { should validate_presence_of(:source_branch) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:author_id) }
    it { should_not allow_mass_assignment_of(:project_id) }
  end

  describe "Respond to" do
    it { should respond_to(:unchecked?) }
    it { should respond_to(:can_be_merged?) }
    it { should respond_to(:cannot_be_merged?) }
  end

  describe 'modules' do
    it { should include_module(Issuable) }
  end

  describe "#mr_and_commit_notes" do
    let!(:merge_request) { create(:merge_request) }

    before do
      merge_request.stub(:commits) { [merge_request.source_project.repository.commit] }
      create(:note, commit_id: merge_request.commits.first.id, noteable_type: 'Commit', project: merge_request.project)
      create(:note, noteable: merge_request, project: merge_request.project)
    end

    it "should include notes for commits" do
      merge_request.commits.should_not be_empty
      merge_request.mr_and_commit_notes.count.should == 2
    end
  end

  subject { create(:merge_request) }

  describe '#is_being_reassigned?' do
    it 'returns true if the merge_request assignee has changed' do
      subject.assignee = create(:user)
      subject.is_being_reassigned?.should be_true
    end
    it 'returns false if the merge request assignee has not changed' do
      subject.is_being_reassigned?.should be_false
    end
  end

  describe '#for_fork?' do
    it 'returns true if the merge request is for a fork' do
      subject.source_project = create(:project, namespace: create(:group))
      subject.target_project = create(:project, namespace: create(:group))

      subject.for_fork?.should be_true
    end

    it 'returns false if is not for a fork' do
      subject.for_fork?.should be_false
    end
  end

  describe '#allow_source_branch_removal?' do
    it 'should not allow removal when mr is a fork' do

      subject.disallow_source_branch_removal?.should be_true
    end
    it 'should not allow removal when the mr is not a fork, but the source branch is the root reference' do
      subject.target_project = subject.source_project
      subject.source_branch = subject.source_project.repository.root_ref
      subject.disallow_source_branch_removal?.should be_true
    end

    it 'should not disallow removal when the mr is not a fork, and but source branch is not the root reference' do
      subject.target_project = subject.source_project
      subject.source_branch = "Something Different #{subject.source_project.repository.root_ref}"
      subject.for_fork?.should be_false
      subject.disallow_source_branch_removal?.should be_false
    end
  end

  describe 'detection of issues to be closed' do
    let(:issue0) { create :issue, project: subject.project }
    let(:issue1) { create :issue, project: subject.project }
    let(:commit0) { double('commit0', closes_issues: [issue0]) }
    let(:commit1) { double('commit1', closes_issues: [issue0]) }
    let(:commit2) { double('commit2', closes_issues: [issue1]) }

    before do
      subject.stub(commits: [commit0, commit1, commit2])
    end

    it 'accesses the set of issues that will be closed on acceptance' do
      subject.project.stub(default_branch: subject.target_branch)

      subject.closes_issues.should == [issue0, issue1].sort_by(&:id)
    end

    it 'only lists issues as to be closed if it targets the default branch' do
      subject.project.stub(default_branch: 'master')
      subject.target_branch = 'something-else'

      subject.closes_issues.should be_empty
    end
  end

  it_behaves_like 'an editable mentionable' do
    let(:subject) { create :merge_request, source_project: mproject, target_project: mproject }
    let(:backref_text) { "merge request !#{subject.iid}" }
    let(:set_mentionable_text) { ->(txt){ subject.title = txt } }
  end
end
