# == Schema Information
#
# Table name: issues
#
#  id            :integer          not null, primary key
#  title         :string(255)
#  assignee_id   :integer
#  author_id     :integer
#  project_id    :integer
#  created_at    :datetime
#  updated_at    :datetime
#  position      :integer          default(0)
#  branch_name   :string(255)
#  description   :text
#  milestone_id  :integer
#  state         :string(255)
#  iid           :integer
#  updated_by_id :integer
#

require 'spec_helper'

describe Issue, models: true do
  describe "Associations" do
    it { is_expected.to belong_to(:milestone) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(InternalId) }
    it { is_expected.to include_module(Issuable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(Taskable) }
  end

  subject { create(:issue) }

  describe '#to_reference' do
    it 'returns a String reference to the object' do
      expect(subject.to_reference).to eq "##{subject.iid}"
    end

    it 'supports a cross-project reference' do
      cross = double('project')
      expect(subject.to_reference(cross)).
        to eq "#{subject.project.to_reference}##{subject.iid}"
    end
  end

  describe '#is_being_reassigned?' do
    it 'returns true if the issue assignee has changed' do
      subject.assignee = create(:user)
      expect(subject.is_being_reassigned?).to be_truthy
    end
    it 'returns false if the issue assignee has not changed' do
      expect(subject.is_being_reassigned?).to be_falsey
    end
  end

  describe '#is_being_reassigned?' do
    it 'returns issues assigned to user' do
      user = create(:user)
      create_list(:issue, 2, assignee: user)

      expect(Issue.open_for(user).count).to eq 2
    end
  end

  describe '#closed_by_merge_requests' do
    let(:project) { create(:project) }
    let(:issue)   { create(:issue, project: project, state: "opened")}
    let(:closed_issue) { build(:issue, project: project, state: "closed")}

    let(:mr) do
      opts = {
        title: 'Awesome merge_request',
        description: "Fixes #{issue.to_reference}",
        source_branch: 'feature',
        target_branch: 'master'
      }
      MergeRequests::CreateService.new(project, project.owner, opts).execute
    end

    let(:closed_mr) do
      opts = {
        title: 'Awesome merge_request 2',
        description: "Fixes #{issue.to_reference}",
        source_branch: 'feature',
        target_branch: 'master',
        state: 'closed'
      }
      MergeRequests::CreateService.new(project, project.owner, opts).execute
    end

    it 'returns the merge request to close this issue' do
      allow(mr).to receive(:closes_issue?).with(issue).and_return(true)

      expect(issue.closed_by_merge_requests).to eq([mr])
    end

    it "returns an empty array when the current issue is closed already" do
      expect(closed_issue.closed_by_merge_requests).to eq([])
    end
  end

  describe '#referenced_merge_requests' do
    it 'returns the referenced merge requests' do
      project = create(:project, :public)

      mr1 = create(:merge_request,
                   source_project: project,
                   source_branch:  'master',
                   target_branch:  'feature')

      mr2 = create(:merge_request,
                   source_project: project,
                   source_branch:  'feature',
                   target_branch:  'master')

      issue = create(:issue, description: mr1.to_reference, project: project)

      create(:note_on_issue,
             noteable:   issue,
             note:       mr2.to_reference,
             project_id: project.id)

      expect(issue.referenced_merge_requests).to eq([mr1, mr2])
    end
  end

  describe '#can_move?' do
    let(:user) { create(:user) }
    let(:issue) { create(:issue) }
    subject { issue.can_move?(user) }

    context 'user is not a member of project issue belongs to' do
      it { is_expected.to eq false}
    end

    context 'user is reporter in project issue belongs to' do
      let(:project) { create(:project) }
      let(:issue) { create(:issue, project: project) }

      before { project.team << [user, :reporter] }

      it { is_expected.to eq true }

      context 'checking destination project also' do
        subject { issue.can_move?(user, to_project) }
        let(:to_project) { create(:project) }

        context 'destination project allowed' do
          before { to_project.team << [user, :reporter] }
          it { is_expected.to eq true }
        end

        context 'destination project not allowed' do
          before { to_project.team << [user, :guest] }
          it { is_expected.to eq false }
        end
      end
    end
  end

  describe '#moved?' do
    let(:issue) { create(:issue) }
    subject { issue.moved? }

    context 'issue not moved' do
      it { is_expected.to eq false }
    end

    context 'issue already moved' do
      let(:moved_to_issue) { create(:issue) }
      let(:issue) { create(:issue, moved_to: moved_to_issue) }

      it { is_expected.to eq true }
    end
  end

  describe '#related_branches' do
    it "selects the right branches" do
      allow(subject.project.repository).to receive(:branch_names).
        and_return(["mpempe", "#{subject.iid}mepmep", subject.to_branch_name])

      expect(subject.related_branches).to eq([subject.to_branch_name])
    end
  end

  it_behaves_like 'an editable mentionable' do
    subject { create(:issue) }

    let(:backref_text) { "issue #{subject.to_reference}" }
    let(:set_mentionable_text) { ->(txt){ subject.description = txt } }
  end

  it_behaves_like 'a Taskable' do
    let(:subject) { create :issue }
  end

  describe "#to_branch_name" do
    let(:issue) { create(:issue, title: 'a' * 30) }

    it "starts with the issue iid" do
      expect(issue.to_branch_name).to match /-#{issue.iid}\z/
    end
  end
end
