# frozen_string_literal: true

require 'spec_helper'

describe Issue do
  include ExternalAuthorizationServiceHelpers

  describe "Associations" do
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:moved_to).class_name('Issue') }
    it { is_expected.to belong_to(:duplicated_to).class_name('Issue') }
    it { is_expected.to belong_to(:closed_by).class_name('User') }
    it { is_expected.to have_many(:assignees) }
    it { is_expected.to have_many(:user_mentions).class_name("IssueUserMention") }
    it { is_expected.to have_one(:sentry_issue) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Issuable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(Taskable) }

    it_behaves_like 'AtomicInternalId' do
      let(:internal_id_attribute) { :iid }
      let(:instance) { build(:issue) }
      let(:scope) { :project }
      let(:scope_attrs) { { project: instance.project } }
      let(:usage) { :issues }
    end
  end

  subject { create(:issue) }

  describe 'callbacks' do
    describe '#ensure_metrics' do
      it 'creates metrics after saving' do
        issue = create(:issue)

        expect(issue.metrics).to be_persisted
        expect(Issue::Metrics.count).to eq(1)
      end

      it 'does not create duplicate metrics for an issue' do
        issue = create(:issue)

        issue.close!

        expect(issue.metrics).to be_persisted
        expect(Issue::Metrics.count).to eq(1)
      end

      it 'records current metrics' do
        expect_any_instance_of(Issue::Metrics).to receive(:record!)

        create(:issue)
      end
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
      it 'works when an issue has a NULL lock_version' do
        issue = create(:issue)

        described_class.where(id: issue.id).update_all('lock_version = NULL')

        issue.update!(lock_version: lock_version, title: 'locking test')

        expect(issue.reload.title).to eq('locking test')
      end
    end
  end

  describe '#order_by_position_and_priority' do
    let(:project) { create :project }
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

  describe '#sort' do
    let(:project) { create(:project) }

    context "by relative_position" do
      let!(:issue)  { create(:issue, project: project) }
      let!(:issue2) { create(:issue, project: project, relative_position: 2) }
      let!(:issue3) { create(:issue, project: project, relative_position: 1) }

      it "sorts asc with nulls at the end" do
        issues = project.issues.sort_by_attribute('relative_position')
        expect(issues).to eq([issue3, issue2, issue])
      end
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

  describe '#close' do
    subject(:issue) { create(:issue, state: 'opened') }

    it 'sets closed_at to Time.now when an issue is closed' do
      expect { issue.close }.to change { issue.closed_at }.from(nil)
    end

    it 'changes the state to closed' do
      open_state = described_class.available_states[:opened]
      closed_state = described_class.available_states[:closed]

      expect { issue.close }.to change { issue.state_id }.from(open_state).to(closed_state)
    end
  end

  describe '#reopen' do
    let(:user) { create(:user) }
    let(:issue) { create(:issue, state: 'closed', closed_at: Time.now, closed_by: user) }

    it 'sets closed_at to nil when an issue is reopend' do
      expect { issue.reopen }.to change { issue.closed_at }.to(nil)
    end

    it 'sets closed_by to nil when an issue is reopend' do
      expect { issue.reopen }.to change { issue.closed_by }.from(user).to(nil)
    end

    it 'changes the state to opened' do
      expect { issue.reopen }.to change { issue.state_id }.from(described_class.available_states[:closed]).to(described_class.available_states[:opened])
    end
  end

  describe '#to_reference' do
    let(:namespace) { build(:namespace, path: 'sample-namespace') }
    let(:project)   { build(:project, name: 'sample-project', namespace: namespace) }
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
      let(:another_namespace_project) { create(:project, name: 'another-project') }

      it 'returns complete path to the issue' do
        expect(issue.to_reference(another_namespace_project)).to eq 'sample-namespace/sample-project#1'
      end
    end

    it 'supports a cross-project reference' do
      another_project = build(:project, name: 'another-project', namespace: project.namespace)
      expect(issue.to_reference(another_project)).to eq "sample-project#1"
    end

    context 'when same namespace / cross-project argument' do
      let(:another_project) { create(:project, namespace: namespace) }

      it 'returns path to the issue with the project name' do
        expect(issue.to_reference(another_project)).to eq 'sample-project#1'
      end
    end

    context 'when different namespace / cross-project argument' do
      let(:another_namespace) { create(:namespace, path: 'another-namespace') }
      let(:another_project)   { create(:project, path: 'another-project', namespace: another_namespace) }

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

      before do
        project.add_reporter(user)
      end

      it { is_expected.to eq true }

      context 'issue not persisted' do
        let(:issue) { build(:issue, project: project) }
        it { is_expected.to eq false }
      end

      context 'checking destination project also' do
        subject { issue.can_move?(user, to_project) }

        let(:to_project) { create(:project) }

        context 'destination project allowed' do
          before do
            to_project.add_reporter(user)
          end

          it { is_expected.to eq true }
        end

        context 'destination project not allowed' do
          before do
            to_project.add_guest(user)
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

  describe '#duplicated?' do
    let(:issue) { create(:issue) }
    subject { issue.duplicated? }

    context 'issue not duplicated' do
      it { is_expected.to eq false }
    end

    context 'issue already duplicated' do
      let(:duplicated_to_issue) { create(:issue) }
      let(:issue) { create(:issue, duplicated_to: duplicated_to_issue) }

      it { is_expected.to eq true }
    end
  end

  describe '#suggested_branch_name' do
    let(:repository) { double }

    subject { build(:issue) }

    before do
      allow(subject.project).to receive(:repository).and_return(repository)
    end

    context '#to_branch_name does not exists' do
      before do
        allow(repository).to receive(:branch_exists?).and_return(false)
      end

      it 'returns #to_branch_name' do
        expect(subject.suggested_branch_name).to eq(subject.to_branch_name)
      end
    end

    context '#to_branch_name exists not ending with -index' do
      before do
        allow(repository).to receive(:branch_exists?).and_return(true)
        allow(repository).to receive(:branch_exists?).with(/#{subject.to_branch_name}-\d/).and_return(false)
      end

      it 'returns #to_branch_name ending with -2' do
        expect(subject.suggested_branch_name).to eq("#{subject.to_branch_name}-2")
      end
    end

    context '#to_branch_name exists ending with -index' do
      before do
        allow(repository).to receive(:branch_exists?).and_return(true)
        allow(repository).to receive(:branch_exists?).with("#{subject.to_branch_name}-3").and_return(false)
      end

      it 'returns #to_branch_name ending with max index + 1' do
        expect(subject.suggested_branch_name).to eq("#{subject.to_branch_name}-3")
      end
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
    let(:set_mentionable_text) { ->(txt) { subject.description = txt } }
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

    context 'issue title longer than 100 characters' do
      let(:issue) { create(:issue, iid: 999, title: 'Lorem ipsum dolor sit amet consectetur adipiscing elit Mauris sit amet ipsum id lacus custom fringilla convallis') }

      it "truncates branch name to at most 100 characters" do
        expect(issue.to_branch_name.length).to be <= 100
      end

      it "truncates dangling parts of the branch name" do
        # 100 characters would've got us "999-lorem...lacus-custom-fri".
        expect(issue.to_branch_name).to eq("999-lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit-mauris-sit-amet-ipsum-id-lacus-custom")
      end
    end
  end

  describe '#can_be_worked_on?' do
    let(:project) { build(:project) }
    subject { build(:issue, :opened, project: project) }

    context 'is closed' do
      subject { build(:issue, :closed) }

      it { is_expected.not_to be_can_be_worked_on }
    end

    context 'project is forked' do
      before do
        allow(project).to receive(:forked?).and_return(true)
      end

      it { is_expected.not_to be_can_be_worked_on }
    end

    it { is_expected.to be_can_be_worked_on }
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
      project = create(:project)
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
        let(:project) { create(:project, :public) }

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
        let(:project) { create(:project, :internal) }

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
        let(:project) { create(:project, :private) }

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
            project.add_maintainer(user)
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
      let(:project) { create(:project, :public) }

      context 'using a public project' do
        before do
          project.add_developer(user)
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
        let(:project) { create(:project, :internal) }

        before do
          project.add_developer(user)
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
        let(:project) { create(:project, :private) }

        before do
          project.add_developer(user)
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
      let(:project) { create(:project) }
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
      let(:project) { create(:project, :public) }

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
      let(:project) { create(:project, :internal) }

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
      let(:project) { create(:project, :private) }

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
    it 'delegates to Gitlab::HookData::IssueBuilder#build' do
      builder = double

      expect(Gitlab::HookData::IssueBuilder)
        .to receive(:new).with(subject).and_return(builder)
      expect(builder).to receive(:build)

      subject.hook_attrs
    end
  end

  describe '#check_for_spam?' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :confidential, :new_attributes, :check_for_spam?) do
      Gitlab::VisibilityLevel::PUBLIC   | false | { description: 'woo' } | true
      Gitlab::VisibilityLevel::PUBLIC   | false | { title: 'woo' } | true
      Gitlab::VisibilityLevel::PUBLIC   | true  | { confidential: false } | true
      Gitlab::VisibilityLevel::PUBLIC   | true  | { description: 'woo' } | false
      Gitlab::VisibilityLevel::PUBLIC   | false | { title: 'woo', confidential: true } | false
      Gitlab::VisibilityLevel::PUBLIC   | false | { description: 'original description' } | false
      Gitlab::VisibilityLevel::INTERNAL | false | { description: 'woo' } | false
      Gitlab::VisibilityLevel::PRIVATE  | false | { description: 'woo' } | false
    end

    with_them do
      it 'checks for spam on issues that can be seen anonymously' do
        project = create(:project, visibility_level: visibility_level)
        issue = create(:issue, project: project, confidential: confidential, description: 'original description')

        issue.assign_attributes(new_attributes)

        expect(issue.check_for_spam?).to eq(check_for_spam?)
      end
    end
  end

  describe 'removing an issue' do
    it 'refreshes the number of open issues of the project' do
      project = subject.project

      expect { subject.destroy }
        .to change { project.open_issues_count }.from(1).to(0)
    end
  end

  describe '.public_only' do
    it 'only returns public issues' do
      public_issue = create(:issue)
      create(:issue, confidential: true)

      expect(described_class.public_only).to eq([public_issue])
    end
  end

  describe '.confidential_only' do
    it 'only returns confidential_only issues' do
      create(:issue)
      confidential_issue = create(:issue, confidential: true)

      expect(described_class.confidential_only).to eq([confidential_issue])
    end
  end

  it_behaves_like 'throttled touch' do
    subject { create(:issue, updated_at: 1.hour.ago) }
  end

  context 'when an external authentication service' do
    before do
      enable_external_authorization_service_check
    end

    describe '#visible_to_user?' do
      it 'is `false` when an external authorization service is enabled' do
        issue = build(:issue, project: build(:project, :public))

        expect(issue).not_to be_visible_to_user
      end

      it 'checks the external service to determine if an issue is readable by a user' do
        project = build(:project, :public,
                        external_authorization_classification_label: 'a-label')
        issue = build(:issue, project: project)
        user = build(:user)

        expect(::Gitlab::ExternalAuthorization).to receive(:access_allowed?).with(user, 'a-label') { false }
        expect(issue.visible_to_user?(user)).to be_falsy
      end

      it 'does not check the external service if a user does not have access to the project' do
        project = build(:project, :private,
                        external_authorization_classification_label: 'a-label')
        issue = build(:issue, project: project)
        user = build(:user)

        expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)
        expect(issue.visible_to_user?(user)).to be_falsy
      end

      it 'does not check the external webservice for admins' do
        issue = build(:issue)
        user = build(:admin)

        expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

        issue.visible_to_user?(user)
      end
    end
  end

  describe "#labels_hook_attrs" do
    let(:label) { create(:label) }
    let(:issue) { create(:labeled_issue, labels: [label]) }

    it "returns a list of label hook attributes" do
      expect(issue.labels_hook_attrs).to eq([label.hook_attrs])
    end
  end

  context "relative positioning" do
    it_behaves_like "a class that supports relative positioning" do
      let(:project) { create(:project) }
      let(:factory) { :issue }
      let(:default_params) { { project: project } }
    end
  end

  it_behaves_like 'versioned description'
end
