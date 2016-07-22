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

  describe "act_as_paranoid" do
    it { is_expected.to have_db_column(:deleted_at) }
    it { is_expected.to have_db_index(:deleted_at) }
  end

  describe 'visible_to_user' do
    let(:user) { create(:user) }
    let(:authorized_user) { create(:user) }
    let(:project) { create(:project, namespace: authorized_user.namespace) }
    let!(:public_issue) { create(:issue, project: project) }
    let!(:confidential_issue) { create(:issue, project: project, confidential: true) }

    it 'returns non confidential issues for nil user' do
      expect(Issue.visible_to_user(nil).count).to be(1)
    end

    it 'returns non confidential issues for user not authorized for the issues projects' do
      expect(Issue.visible_to_user(user).count).to be(1)
    end

    it 'returns all issues for user authorized for the issues projects' do
      expect(Issue.visible_to_user(authorized_user).count).to be(2)
    end
  end

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

      context 'issue not persisted' do
        let(:issue) { build(:issue, project: project) }
        it { is_expected.to eq false }
      end

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
    let(:user) { build(:admin) }

    before do
      allow(subject.project.repository).to receive(:branch_names).
                                            and_return(["mpempe", "#{subject.iid}mepmep", subject.to_branch_name, "#{subject.iid}-branch"])

      # Without this stub, the `create(:merge_request)` above fails because it can't find
      # the source branch. This seems like a reasonable compromise, in comparison with
      # setting up a full repo here.
      allow_any_instance_of(MergeRequest).to receive(:create_merge_request_diff)
    end

    it "selects the right branches when there are no referenced merge requests" do
      expect(subject.related_branches(user)).to eq([subject.to_branch_name, "#{subject.iid}-branch"])
    end

    it "selects the right branches when there is a referenced merge request" do
      merge_request = create(:merge_request, { description: "Closes ##{subject.iid}",
                                               source_project: subject.project,
                                               source_branch: "#{subject.iid}-branch" })
      merge_request.create_cross_references!(user)
      expect(subject.referenced_merge_requests).not_to be_empty
      expect(subject.related_branches(user)).to eq([subject.to_branch_name])
    end

    it 'excludes stable branches from the related branches' do
      allow(subject.project.repository).to receive(:branch_names).
        and_return(["#{subject.iid}-0-stable"])

      expect(subject.related_branches(user)).to eq []
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
    let(:issue) { create(:issue, title: 'testing-issue') }

    it 'starts with the issue iid' do
      expect(issue.to_branch_name).to match /\A#{issue.iid}-[A-Za-z\-]+\z/
    end

    it "contains the issue title if not confidential" do
      expect(issue.to_branch_name).to match /testing-issue\z/
    end

    it "does not contain the issue title if confidential" do
      issue = create(:issue, title: 'testing-issue', confidential: true)
      expect(issue.to_branch_name).to match /confidential-issue\z/
    end
  end

  describe '#participants' do
    context 'using a public project' do
      let(:project) { create(:project, :public) }
      let(:issue) { create(:issue, project: project) }

      let!(:note1) do
        create(:note_on_issue, noteable: issue, project: project, note: 'a')
      end

      let!(:note2) do
        create(:note_on_issue, noteable: issue, project: project, note: 'b')
      end

      it 'includes the issue author' do
        expect(issue.participants).to include(issue.author)
      end

      it 'includes the authors of the notes' do
        expect(issue.participants).to include(note1.author, note2.author)
      end
    end

    context 'using a private project' do
      it 'does not include mentioned users that do not have access to the project' do
        project = create(:project)
        user = create(:user)
        issue = create(:issue, project: project)

        create(:note_on_issue,
               noteable: issue,
               project: project,
               note: user.to_reference)

        expect(issue.participants).not_to include(user)
      end
    end
  end

  describe 'cached counts' do
    it 'updates when assignees change' do
      user1 = create(:user)
      user2 = create(:user)
      issue = create(:issue, assignee: user1)

      expect(user1.assigned_open_issues_count).to eq(1)
      expect(user2.assigned_open_issues_count).to eq(0)

      issue.assignee = user2
      issue.save

      expect(user1.assigned_open_issues_count).to eq(0)
      expect(user2.assigned_open_issues_count).to eq(1)
    end
  end
end
