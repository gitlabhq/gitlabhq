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
#  created_at        :datetime
#  updated_at        :datetime
#  milestone_id      :integer
#  state             :string(255)
#  merge_status      :string(255)
#  target_project_id :integer          not null
#  iid               :integer
#  description       :text
#  position          :integer          default(0)
#  locked_at         :datetime
#  updated_by_id     :integer
#

require 'spec_helper'

describe MergeRequest do
  subject { create(:merge_request) }

  describe 'associations' do
    it { is_expected.to belong_to(:target_project).with_foreign_key(:target_project_id).class_name('Project') }
    it { is_expected.to belong_to(:source_project).with_foreign_key(:source_project_id).class_name('Project') }

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
  end

  describe 'respond to' do
    it { is_expected.to respond_to(:unchecked?) }
    it { is_expected.to respond_to(:can_be_merged?) }
    it { is_expected.to respond_to(:cannot_be_merged?) }
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
    let(:commit0) { double('commit0', closes_issues: [issue0]) }
    let(:commit1) { double('commit1', closes_issues: [issue0]) }
    let(:commit2) { double('commit2', closes_issues: [issue1]) }

    before do
      allow(subject).to receive(:commits).and_return([commit0, commit1, commit2])
    end

    it 'accesses the set of issues that will be closed on acceptance' do
      allow(subject.project).to receive(:default_branch).
        and_return(subject.target_branch)

      expect(subject.closes_issues).to eq([issue0, issue1].sort_by(&:id))
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

    it "doesn't detect WIP for words starting with WIP" do
      subject.title = "Wipwap #{subject.title}"
      expect(subject).not_to be_work_in_progress
    end

    it "doesn't detect WIP by default" do
      expect(subject).not_to be_work_in_progress
    end
  end

  describe "#hook_attrs" do
    it "has all the required keys" do
      attrs = subject.hook_attrs
      attrs = attrs.to_h
      expect(attrs).to include(:source)
      expect(attrs).to include(:target)
      expect(attrs).to include(:last_commit)
      expect(attrs).to include(:work_in_progress)
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
end
