require 'spec_helper'

describe Issue do
  describe "Associations" do
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to have_many(:assignees) }
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

  describe '#order_by_position_and_priority' do
    let(:project) { create :empty_project }
    let(:p1) { create(:label, title: 'P1', project: project, priority: 1) }
    let(:p2) { create(:label, title: 'P2', project: project, priority: 2) }
    let!(:issue1) { create(:labeled_issue, project: project, labels: [p1]) }
    let!(:issue2) { create(:labeled_issue, project: project, labels: [p2]) }
    let!(:issue3) { create(:issue, project: project, relative_position: 100) }
    let!(:issue4) { create(:issue, project: project, relative_position: 200) }

    it 'returns ordered list' do
      expect(project.issues.order_by_position_and_priority)
        .to match [issue3, issue4, issue1, issue2]
    end
  end

  describe '#card_attributes' do
    it 'includes the author name' do
      allow(subject).to receive(:author).and_return(double(name: 'Robert'))
      allow(subject).to receive(:assignees).and_return([])

      expect(subject.card_attributes)
        .to eq({ 'Author' => 'Robert', 'Assignee' => '' })
    end

    it 'includes the assignee name' do
      allow(subject).to receive(:author).and_return(double(name: 'Robert'))
      allow(subject).to receive(:assignees).and_return([double(name: 'Douwe')])

      expect(subject.card_attributes)
        .to eq({ 'Author' => 'Robert', 'Assignee' => 'Douwe' })
    end
  end

  describe '#closed_at' do
    after do
      Timecop.return
    end

    let!(:now) { Timecop.freeze(Time.now) }

    it 'sets closed_at to Time.now when issue is closed' do
      issue = create(:issue, state: 'opened')

      issue.close

      expect(issue.closed_at).to eq(now)
    end
  end

  describe '#to_reference' do
    let(:namespace) { build(:namespace, path: 'sample-namespace') }
    let(:project)   { build(:empty_project, name: 'sample-project', namespace: namespace) }
    let(:issue)     { build(:issue, iid: 1, project: project) }
    let(:group)     { create(:group, name: 'Group', path: 'sample-group') }

    context 'when nil argument' do
      it 'returns issue id' do
        expect(issue.to_reference).to eq "#1"
      end
    end

    context 'when full is true' do
      it 'returns complete path to the issue' do
        expect(issue.to_reference(full: true)).to          eq 'sample-namespace/sample-project#1'
        expect(issue.to_reference(project, full: true)).to eq 'sample-namespace/sample-project#1'
        expect(issue.to_reference(group, full: true)).to   eq 'sample-namespace/sample-project#1'
      end
    end

    context 'when same project argument' do
      it 'returns issue id' do
        expect(issue.to_reference(project)).to eq("#1")
      end
    end

    context 'when cross namespace project argument' do
      let(:another_namespace_project) { create(:empty_project, name: 'another-project') }

      it 'returns complete path to the issue' do
        expect(issue.to_reference(another_namespace_project)).to eq 'sample-namespace/sample-project#1'
      end
    end

    it 'supports a cross-project reference' do
      another_project = build(:empty_project, name: 'another-project', namespace: project.namespace)
      expect(issue.to_reference(another_project)).to eq "sample-project#1"
    end

    context 'when same namespace / cross-project argument' do
      let(:another_project) { create(:empty_project, namespace: namespace) }

      it 'returns path to the issue with the project name' do
        expect(issue.to_reference(another_project)).to eq 'sample-project#1'
      end
    end

    context 'when different namespace / cross-project argument' do
      let(:another_namespace) { create(:namespace, path: 'another-namespace') }
      let(:another_project)   { create(:empty_project, path: 'another-project', namespace: another_namespace) }

      it 'returns full path to the issue' do
        expect(issue.to_reference(another_project)).to eq 'sample-namespace/sample-project#1'
      end
    end

    context 'when argument is a namespace' do
      context 'with same project path' do
        it 'returns path to the issue with the project name' do
          expect(issue.to_reference(namespace)).to eq 'sample-project#1'
        end
      end

      context 'with different project path' do
        it 'returns full path to the issue' do
          expect(issue.to_reference(group)).to eq 'sample-namespace/sample-project#1'
        end
      end
    end
  end

  describe '#assignee_or_author?' do
    let(:user) { create(:user) }
    let(:issue) { create(:issue) }

    it 'returns true for a user that is assigned to an issue' do
      issue.assignees << user

      expect(issue.assignee_or_author?(user)).to be_truthy
    end

    it 'returns true for a user that is the author of an issue' do
      issue.update(author: user)

      expect(issue.assignee_or_author?(user)).to be_truthy
    end

    it 'returns false for a user that is not the assignee or author' do
      expect(issue.assignee_or_author?(user)).to be_falsey
    end
  end

  describe '#closed_by_merge_requests' do
    let(:project) { create(:project, :repository) }
    let(:issue) { create(:issue, project: project)}
    let(:closed_issue) { build(:issue, :closed, project: project)}

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
      mr

      expect(issue.closed_by_merge_requests(mr.author)).to eq([mr])
    end

    it "returns an empty array when the merge request is closed already" do
      closed_mr

      expect(issue.closed_by_merge_requests(closed_mr.author)).to eq([])
    end

    it "returns an empty array when the current issue is closed already" do
      expect(closed_issue.closed_by_merge_requests(closed_issue.author)).to eq([])
    end
  end

  describe '#referenced_merge_requests' do
    it 'returns the referenced merge requests' do
      project = create(:empty_project, :public)

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
      let(:project) { create(:empty_project) }
      let(:issue) { create(:issue, project: project) }

      before do
        project.team << [user, :reporter]
      end

      it { is_expected.to eq true }

      context 'issue not persisted' do
        let(:issue) { build(:issue, project: project) }
        it { is_expected.to eq false }
      end

      context 'checking destination project also' do
        subject { issue.can_move?(user, to_project) }
        let(:to_project) { create(:empty_project) }

        context 'destination project allowed' do
          before do
            to_project.team << [user, :reporter]
          end

          it { is_expected.to eq true }
        end

        context 'destination project not allowed' do
          before do
            to_project.team << [user, :guest]
          end

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
      allow(subject.project.repository).to receive(:branch_names)
                                            .and_return(["mpempe", "#{subject.iid}mepmep", subject.to_branch_name, "#{subject.iid}-branch"])

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
      expect(subject.referenced_merge_requests(user)).not_to be_empty
      expect(subject.related_branches(user)).to eq([subject.to_branch_name])
    end

    it 'excludes stable branches from the related branches' do
      allow(subject.project.repository).to receive(:branch_names)
        .and_return(["#{subject.iid}-0-stable"])

      expect(subject.related_branches(user)).to eq []
    end
  end

  describe '#related_issues' do
    let(:user) { create(:user) }
    let(:authorized_project) { create(:empty_project) }
    let(:unauthorized_project) { create(:empty_project) }

    let(:authorized_issue_a) { create(:issue, project: authorized_project) }
    let(:authorized_issue_b) { create(:issue, project: authorized_project) }
    let(:unauthorized_issue) { create(:issue, project: unauthorized_project) }

    let!(:issue_link_a) { create(:issue_link, source: authorized_issue_a, target: authorized_issue_b) }
    let!(:issue_link_b) { create(:issue_link, source: authorized_issue_a, target: unauthorized_issue) }

    before do
      authorized_project.add_developer(user)
    end

    it 'returns only authorized related issues for given user' do
      expect(authorized_issue_a.related_issues(user)).to contain_exactly(authorized_issue_b)
    end
  end

  describe '#has_related_branch?' do
    let(:issue) { create(:issue, title: "Blue Bell Knoll") }
    subject { issue.has_related_branch? }

    context 'branch found' do
      before do
        allow(issue.project.repository).to receive(:branch_names).and_return(["iceblink-luck", issue.to_branch_name])
      end

      it { is_expected.to eq true }
    end

    context 'branch not found' do
      before do
        allow(issue.project.repository).to receive(:branch_names).and_return(["lazy-calm"])
      end

      it { is_expected.to eq false }
    end
  end

  it_behaves_like 'an editable mentionable' do
    subject { create(:issue, project: create(:project, :repository)) }

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
      let(:project) { create(:empty_project, :public) }
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
        project = create(:empty_project)
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
      project = create(:empty_project)
      issue = create(:issue, assignees: [user1], project: project)
      project.add_developer(user1)
      project.add_developer(user2)

      expect(user1.assigned_open_issues_count).to eq(1)
      expect(user2.assigned_open_issues_count).to eq(0)

      issue.assignees = [user2]
      issue.save

      expect(user1.assigned_open_issues_count).to eq(0)
      expect(user2.assigned_open_issues_count).to eq(1)
    end
  end

  describe '#visible_to_user?' do
    context 'without a user' do
      let(:issue) { build(:issue) }

      it 'returns true when the issue is publicly visible' do
        expect(issue).to receive(:publicly_visible?).and_return(true)

        expect(issue.visible_to_user?).to eq(true)
      end

      it 'returns false when the issue is not publicly visible' do
        expect(issue).to receive(:publicly_visible?).and_return(false)

        expect(issue.visible_to_user?).to eq(false)
      end
    end

    context 'with a user' do
      let(:user) { create(:user) }
      let(:issue) { build(:issue) }

      it 'returns true when the issue is readable' do
        expect(issue).to receive(:readable_by?).with(user).and_return(true)

        expect(issue.visible_to_user?(user)).to eq(true)
      end

      it 'returns false when the issue is not readable' do
        expect(issue).to receive(:readable_by?).with(user).and_return(false)

        expect(issue.visible_to_user?(user)).to eq(false)
      end

      it 'returns false when feature is disabled' do
        expect(issue).not_to receive(:readable_by?)

        issue.project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

        expect(issue.visible_to_user?(user)).to eq(false)
      end

      it 'returns false when restricted for members' do
        expect(issue).not_to receive(:readable_by?)

        issue.project.project_feature.update_attribute(:issues_access_level, ProjectFeature::PRIVATE)

        expect(issue.visible_to_user?(user)).to eq(false)
      end
    end

    describe 'with a regular user that is not a team member' do
      let(:user) { create(:user) }

      context 'using a public project' do
        let(:project) { create(:empty_project, :public) }

        it 'returns true for a regular issue' do
          issue = build(:issue, project: project)

          expect(issue.visible_to_user?(user)).to eq(true)
        end

        it 'returns false for a confidential issue' do
          issue = build(:issue, project: project, confidential: true)

          expect(issue.visible_to_user?(user)).to eq(false)
        end
      end

      context 'using an internal project' do
        let(:project) { create(:empty_project, :internal) }

        context 'using an internal user' do
          it 'returns true for a regular issue' do
            issue = build(:issue, project: project)

            expect(issue.visible_to_user?(user)).to eq(true)
          end

          it 'returns false for a confidential issue' do
            issue = build(:issue, :confidential, project: project)

            expect(issue.visible_to_user?(user)).to eq(false)
          end
        end

        context 'using an external user' do
          before do
            allow(user).to receive(:external?).and_return(true)
          end

          it 'returns false for a regular issue' do
            issue = build(:issue, project: project)

            expect(issue.visible_to_user?(user)).to eq(false)
          end

          it 'returns false for a confidential issue' do
            issue = build(:issue, :confidential, project: project)

            expect(issue.visible_to_user?(user)).to eq(false)
          end
        end
      end

      context 'using a private project' do
        let(:project) { create(:empty_project, :private) }

        it 'returns false for a regular issue' do
          issue = build(:issue, project: project)

          expect(issue.visible_to_user?(user)).to eq(false)
        end

        it 'returns false for a confidential issue' do
          issue = build(:issue, :confidential, project: project)

          expect(issue.visible_to_user?(user)).to eq(false)
        end

        context 'when the user is the project owner' do
          before do
            project.team << [user, :master]
          end

          it 'returns true for a regular issue' do
            issue = build(:issue, project: project)

            expect(issue.visible_to_user?(user)).to eq(true)
          end

          it 'returns true for a confidential issue' do
            issue = build(:issue, :confidential, project: project)

            expect(issue.visible_to_user?(user)).to eq(true)
          end
        end
      end
    end

    context 'with a regular user that is a team member' do
      let(:user) { create(:user) }
      let(:project) { create(:empty_project, :public) }

      context 'using a public project' do
        before do
          project.team << [user, Gitlab::Access::DEVELOPER]
        end

        it 'returns true for a regular issue' do
          issue = build(:issue, project: project)

          expect(issue.visible_to_user?(user)).to eq(true)
        end

        it 'returns true for a confidential issue' do
          issue = build(:issue, :confidential, project: project)

          expect(issue.visible_to_user?(user)).to eq(true)
        end
      end

      context 'using an internal project' do
        let(:project) { create(:empty_project, :internal) }

        before do
          project.team << [user, Gitlab::Access::DEVELOPER]
        end

        it 'returns true for a regular issue' do
          issue = build(:issue, project: project)

          expect(issue.visible_to_user?(user)).to eq(true)
        end

        it 'returns true for a confidential issue' do
          issue = build(:issue, :confidential, project: project)

          expect(issue.visible_to_user?(user)).to eq(true)
        end
      end

      context 'using a private project' do
        let(:project) { create(:empty_project, :private) }

        before do
          project.team << [user, Gitlab::Access::DEVELOPER]
        end

        it 'returns true for a regular issue' do
          issue = build(:issue, project: project)

          expect(issue.visible_to_user?(user)).to eq(true)
        end

        it 'returns true for a confidential issue' do
          issue = build(:issue, :confidential, project: project)

          expect(issue.visible_to_user?(user)).to eq(true)
        end
      end
    end

    context 'with an admin user' do
      let(:project) { create(:empty_project) }
      let(:user) { create(:admin) }

      it 'returns true for a regular issue' do
        issue = build(:issue, project: project)

        expect(issue.visible_to_user?(user)).to eq(true)
      end

      it 'returns true for a confidential issue' do
        issue = build(:issue, :confidential, project: project)

        expect(issue.visible_to_user?(user)).to eq(true)
      end
    end
  end

  describe '#publicly_visible?' do
    context 'using a public project' do
      let(:project) { create(:empty_project, :public) }

      it 'returns true for a regular issue' do
        issue = build(:issue, project: project)

        expect(issue).to be_truthy
      end

      it 'returns false for a confidential issue' do
        issue = build(:issue, :confidential, project: project)

        expect(issue).not_to be_falsy
      end
    end

    context 'using an internal project' do
      let(:project) { create(:empty_project, :internal) }

      it 'returns false for a regular issue' do
        issue = build(:issue, project: project)

        expect(issue).not_to be_falsy
      end

      it 'returns false for a confidential issue' do
        issue = build(:issue, :confidential, project: project)

        expect(issue).not_to be_falsy
      end
    end

    context 'using a private project' do
      let(:project) { create(:empty_project, :private) }

      it 'returns false for a regular issue' do
        issue = build(:issue, project: project)

        expect(issue).not_to be_falsy
      end

      it 'returns false for a confidential issue' do
        issue = build(:issue, :confidential, project: project)

        expect(issue).not_to be_falsy
      end
    end
  end

  describe '#hook_attrs' do
    let(:attrs_hash) { subject.hook_attrs }

    it 'includes time tracking attrs' do
      expect(attrs_hash).to include(:total_time_spent)
      expect(attrs_hash).to include(:human_time_estimate)
      expect(attrs_hash).to include(:human_total_time_spent)
      expect(attrs_hash).to include('time_estimate')
    end

    it 'includes assignee_ids and deprecated assignee_id' do
      expect(attrs_hash).to include(:assignee_id)
      expect(attrs_hash).to include(:assignee_ids)
    end
  end

  describe '#check_for_spam' do
    let(:project) { create :project, visibility_level: visibility_level }
    let(:issue) { create :issue, project: project }

    subject do
      issue.assign_attributes(description: description)
      issue.check_for_spam?
    end

    context 'when project is public and spammable attributes changed' do
      let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
      let(:description) { 'woo' }

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when project is private' do
      let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
      let(:description) { issue.description }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'when spammable attributes have not changed' do
      let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
      let(:description) { issue.description }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end
end
