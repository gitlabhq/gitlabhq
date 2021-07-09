# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issue do
  include ExternalAuthorizationServiceHelpers

  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:reusable_project) { create(:project) }

  describe "Associations" do
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to belong_to(:iteration) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:namespace).through(:project) }
    it { is_expected.to belong_to(:moved_to).class_name('Issue') }
    it { is_expected.to have_one(:moved_from).class_name('Issue') }
    it { is_expected.to belong_to(:duplicated_to).class_name('Issue') }
    it { is_expected.to belong_to(:closed_by).class_name('User') }
    it { is_expected.to have_many(:assignees) }
    it { is_expected.to have_many(:user_mentions).class_name("IssueUserMention") }
    it { is_expected.to have_many(:designs) }
    it { is_expected.to have_many(:design_versions) }
    it { is_expected.to have_one(:sentry_issue) }
    it { is_expected.to have_one(:alert_management_alert) }
    it { is_expected.to have_many(:resource_milestone_events) }
    it { is_expected.to have_many(:resource_state_events) }
    it { is_expected.to have_and_belong_to_many(:prometheus_alert_events) }
    it { is_expected.to have_and_belong_to_many(:self_managed_prometheus_alert_events) }
    it { is_expected.to have_many(:prometheus_alerts) }
    it { is_expected.to have_many(:issue_email_participants) }

    describe 'versions.most_recent' do
      it 'returns the most recent version' do
        issue = create(:issue, project: reusable_project)
        create_list(:design_version, 2, issue: issue)
        last_version = create(:design_version, issue: issue)

        expect(issue.design_versions.most_recent).to eq(last_version)
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
      let(:instance) { build(:issue) }
      let(:scope) { :project }
      let(:scope_attrs) { { project: instance.project } }
      let(:usage) { :issues }
    end
  end

  describe 'validations' do
    subject { issue.valid? }

    describe 'issue_type' do
      let(:issue) { build(:issue, issue_type: issue_type) }

      context 'when a valid type' do
        let(:issue_type) { :issue }

        it { is_expected.to eq(true) }
      end

      context 'empty type' do
        let(:issue_type) { nil }

        it { is_expected.to eq(false) }
      end
    end
  end

  subject { create(:issue, project: reusable_project) }

  describe 'callbacks' do
    describe '#ensure_metrics' do
      it 'creates metrics after saving' do
        expect(subject.metrics).to be_persisted
        expect(Issue::Metrics.count).to eq(1)
      end

      it 'does not create duplicate metrics for an issue' do
        subject.close!

        expect(subject.metrics).to be_persisted
        expect(Issue::Metrics.count).to eq(1)
      end

      it 'records current metrics' do
        expect_any_instance_of(Issue::Metrics).to receive(:record!)

        create(:issue, project: reusable_project)
      end

      context 'when metrics record is missing' do
        before do
          subject.metrics.delete
          subject.reload
          subject.metrics # make sure metrics association is cached (currently nil)
        end

        it 'creates the metrics record' do
          subject.update!(title: 'title')

          expect(subject.metrics).to be_present
        end
      end
    end

    describe '#record_create_action' do
      it 'records the creation action after saving' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_created_action)

        create(:issue)
      end
    end
  end

  describe '.with_alert_management_alerts' do
    subject { described_class.with_alert_management_alerts }

    it 'gets only issues with alerts' do
      alert = create(:alert_management_alert, project: reusable_project, issue: create(:issue, project: reusable_project))
      issue = create(:issue, project: reusable_project)

      expect(subject).to contain_exactly(alert.issue)
      expect(subject).not_to include(issue)
    end
  end

  describe '.simple_sorts' do
    it 'includes all keys' do
      expect(described_class.simple_sorts.keys).to include(
        *%w(created_asc created_at_asc created_date created_desc created_at_desc
            closest_future_date closest_future_date_asc due_date due_date_asc due_date_desc
            id_asc id_desc relative_position relative_position_asc
            updated_desc updated_asc updated_at_asc updated_at_desc))
    end
  end

  describe '.with_issue_type' do
    let_it_be(:issue) { create(:issue, project: reusable_project) }
    let_it_be(:incident) { create(:incident, project: reusable_project) }

    it 'gives issues with the given issue type' do
      expect(described_class.with_issue_type('issue'))
        .to contain_exactly(issue)
    end

    it 'gives issues with the given issue type' do
      expect(described_class.with_issue_type(%w(issue incident)))
        .to contain_exactly(issue, incident)
    end
  end

  describe '.order_severity' do
    let_it_be(:issue_high_severity) { create(:issuable_severity, severity: :high).issue }
    let_it_be(:issue_low_severity) { create(:issuable_severity, severity: :low).issue }
    let_it_be(:issue_no_severity) { create(:incident) }

    context 'sorting ascending' do
      subject { described_class.order_severity_asc }

      it { is_expected.to eq([issue_no_severity, issue_low_severity, issue_high_severity]) }
    end

    context 'sorting descending' do
      subject { described_class.order_severity_desc }

      it { is_expected.to eq([issue_high_severity, issue_low_severity, issue_no_severity]) }
    end
  end

  describe '#order_by_position_and_priority' do
    let(:project) { reusable_project }
    let(:p1) { create(:label, title: 'P1', project: project, priority: 1) }
    let(:p2) { create(:label, title: 'P2', project: project, priority: 2) }
    let!(:issue1) { create(:labeled_issue, project: project, labels: [p1]) }
    let!(:issue2) { create(:labeled_issue, project: project, labels: [p2]) }
    let!(:issue3) { create(:issue, project: project, relative_position: -200) }
    let!(:issue4) { create(:issue, project: project, relative_position: -100) }

    it 'returns ordered list' do
      expect(project.issues.order_by_position_and_priority)
        .to match [issue3, issue4, issue1, issue2]
    end
  end

  describe '#sort' do
    let(:project) { reusable_project }

    context "by relative_position" do
      let!(:issue)  { create(:issue, project: project, relative_position: nil) }
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
    subject(:issue) { create(:issue, project: reusable_project, state: 'opened') }

    it 'sets closed_at to Time.current when an issue is closed' do
      expect { issue.close }.to change { issue.closed_at }.from(nil)
    end

    it 'changes the state to closed' do
      open_state = described_class.available_states[:opened]
      closed_state = described_class.available_states[:closed]

      expect { issue.close }.to change { issue.state_id }.from(open_state).to(closed_state)
    end

    context 'when an argument is provided' do
      context 'and the argument is a User' do
        it 'changes closed_by to the given user' do
          expect { issue.close(user) }.to change { issue.closed_by }.from(nil).to(user)
        end
      end

      context 'and the argument is a not a User' do
        it 'does not change closed_by' do
          expect { issue.close("test") }.not_to change { issue.closed_by }
        end
      end
    end

    context 'when an argument is not provided' do
      it 'does not change closed_by' do
        expect { issue.close }.not_to change { issue.closed_by }
      end
    end
  end

  describe '#reopen' do
    let(:issue) { create(:issue, project: reusable_project, state: 'closed', closed_at: Time.current, closed_by: user) }

    it 'sets closed_at to nil when an issue is reopened' do
      expect { issue.reopen }.to change { issue.closed_at }.to(nil)
    end

    it 'sets closed_by to nil when an issue is reopened' do
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

    context 'when nil argument' do
      it 'returns issue id' do
        expect(issue.to_reference).to eq "#1"
      end

      it 'returns complete path to the issue with full: true' do
        expect(issue.to_reference(full: true)).to eq 'sample-namespace/sample-project#1'
      end
    end

    context 'when argument is a project' do
      context 'when same project' do
        it 'returns issue id' do
          expect(issue.to_reference(project)).to eq("#1")
        end

        it 'returns full reference with full: true' do
          expect(issue.to_reference(project, full: true)).to eq 'sample-namespace/sample-project#1'
        end
      end

      context 'when cross-project in same namespace' do
        let(:another_project) do
          build(:project, name: 'another-project', namespace: project.namespace)
        end

        it 'returns a cross-project reference' do
          expect(issue.to_reference(another_project)).to eq "sample-project#1"
        end
      end

      context 'when cross-project in different namespace' do
        let(:another_namespace) { build(:namespace, id: non_existing_record_id, path: 'another-namespace') }
        let(:another_namespace_project) { build(:project, path: 'another-project', namespace: another_namespace) }

        it 'returns complete path to the issue' do
          expect(issue.to_reference(another_namespace_project)).to eq 'sample-namespace/sample-project#1'
        end
      end
    end

    context 'when argument is a namespace' do
      context 'when same as issue' do
        it 'returns path to the issue with the project name' do
          expect(issue.to_reference(namespace)).to eq 'sample-project#1'
        end

        it 'returns full reference with full: true' do
          expect(issue.to_reference(namespace, full: true)).to eq 'sample-namespace/sample-project#1'
        end
      end

      context 'when different to issue namespace' do
        let(:group) { build(:group, name: 'Group', path: 'sample-group') }

        it 'returns full path to the issue with full: true' do
          expect(issue.to_reference(group)).to eq 'sample-namespace/sample-project#1'
        end
      end
    end
  end

  describe '#assignee_or_author?' do
    let(:issue) { create(:issue, project: reusable_project) }

    it 'returns true for a user that is assigned to an issue' do
      issue.assignees << user

      expect(issue.assignee_or_author?(user)).to be_truthy
    end

    it 'returns true for a user that is the author of an issue' do
      issue.update!(author: user)

      expect(issue.assignee_or_author?(user)).to be_truthy
    end

    it 'returns false for a user that is not the assignee or author' do
      expect(issue.assignee_or_author?(user)).to be_falsey
    end
  end

  describe '#related_issues' do
    let_it_be(:authorized_project) { create(:project) }
    let_it_be(:authorized_project2) { create(:project) }
    let_it_be(:unauthorized_project) { create(:project) }

    let_it_be(:authorized_issue_a) { create(:issue, project: authorized_project) }
    let_it_be(:authorized_issue_b) { create(:issue, project: authorized_project) }
    let_it_be(:authorized_issue_c) { create(:issue, project: authorized_project2) }

    let_it_be(:unauthorized_issue) { create(:issue, project: unauthorized_project) }

    let_it_be(:issue_link_a) { create(:issue_link, source: authorized_issue_a, target: authorized_issue_b) }
    let_it_be(:issue_link_b) { create(:issue_link, source: authorized_issue_a, target: unauthorized_issue) }
    let_it_be(:issue_link_c) { create(:issue_link, source: authorized_issue_a, target: authorized_issue_c) }

    before_all do
      authorized_project.add_developer(user)
      authorized_project2.add_developer(user)
    end

    it 'returns only authorized related issues for given user' do
      expect(authorized_issue_a.related_issues(user))
        .to contain_exactly(authorized_issue_b, authorized_issue_c)
    end

    it 'returns issues with valid issue_link_type' do
      link_types = authorized_issue_a.related_issues(user).map(&:issue_link_type)

      expect(link_types).not_to be_empty
      expect(link_types).not_to include(nil)
    end

    it 'returns issues including the link creation time' do
      dates = authorized_issue_a.related_issues(user).map(&:issue_link_created_at)

      expect(dates).not_to be_empty
      expect(dates).not_to include(nil)
    end

    it 'returns issues including the link update time' do
      dates = authorized_issue_a.related_issues(user).map(&:issue_link_updated_at)

      expect(dates).not_to be_empty
      expect(dates).not_to include(nil)
    end

    describe 'when a user cannot read cross project' do
      it 'only returns issues within the same project' do
        expect(Ability).to receive(:allowed?).with(user, :read_all_resources, :global).at_least(:once).and_call_original
        expect(Ability).to receive(:allowed?).with(user, :read_cross_project).and_return(false)

        expect(authorized_issue_a.related_issues(user))
          .to contain_exactly(authorized_issue_b)
      end
    end
  end

  describe '#can_move?' do
    let(:issue) { create(:issue) }

    subject { issue.can_move?(user) }

    context 'user is not a member of project issue belongs to' do
      it { is_expected.to eq false}
    end

    context 'user is reporter in project issue belongs to' do
      let(:issue) { create(:issue, project: reusable_project) }

      before_all do
        reusable_project.add_reporter(user)
      end

      it { is_expected.to eq true }

      context 'issue not persisted' do
        let(:issue) { build(:issue, project: reusable_project) }

        it { is_expected.to eq false }
      end

      context 'checking destination project also' do
        subject { issue.can_move?(user, to_project) }

        let_it_be(:to_project) { create(:project) }

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
    context 'when issue has not been moved' do
      subject { build_stubbed(:issue) }

      it { is_expected.not_to be_moved }
    end

    context 'when issue has already been moved' do
      subject { build_stubbed(:issue, moved_to: build_stubbed(:issue)) }

      it { is_expected.to be_moved }
    end
  end

  describe '#duplicated?' do
    let(:issue) { create(:issue, project: reusable_project) }

    subject { issue.duplicated? }

    context 'issue not duplicated' do
      it { is_expected.to eq false }
    end

    context 'issue already duplicated' do
      let(:duplicated_to_issue) { create(:issue, project: reusable_project) }
      let(:issue) { create(:issue, duplicated_to: duplicated_to_issue) }

      it { is_expected.to eq true }
    end
  end

  describe '#from_service_desk?' do
    subject { issue.from_service_desk? }

    context 'when issue author is support bot' do
      let(:issue) { create(:issue, project: reusable_project, author: ::User.support_bot) }

      it { is_expected.to be_truthy }
    end

    context 'when issue author is not support bot' do
      let(:issue) { create(:issue, project: reusable_project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#suggested_branch_name' do
    let(:repository) { double }

    subject { build(:issue) }

    before do
      allow(subject.project).to receive(:repository).and_return(repository)
    end

    describe '#to_branch_name does not exists' do
      before do
        allow(repository).to receive(:branch_exists?).and_return(false)
      end

      it 'returns #to_branch_name' do
        expect(subject.suggested_branch_name).to eq(subject.to_branch_name)
      end
    end

    describe '#to_branch_name exists not ending with -index' do
      before do
        allow(repository).to receive(:branch_exists?).and_return(true)
        allow(repository).to receive(:branch_exists?).with(/#{subject.to_branch_name}-\d/).and_return(false)
      end

      it 'returns #to_branch_name ending with -2' do
        expect(subject.suggested_branch_name).to eq("#{subject.to_branch_name}-2")
      end
    end

    describe '#to_branch_name exists ending with -index' do
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
    let(:issue) { create(:issue, project: reusable_project, title: "Blue Bell Knoll") }

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
    let_it_be(:issue) { create(:issue, project: reusable_project, title: 'testing-issue') }

    it 'starts with the issue iid' do
      expect(issue.to_branch_name).to match(/\A#{issue.iid}-[A-Za-z\-]+\z/)
    end

    it "contains the issue title if not confidential" do
      expect(issue.to_branch_name).to match(/testing-issue\z/)
    end

    it "does not contain the issue title if confidential" do
      issue = create(:issue, project: reusable_project, title: 'testing-issue', confidential: true)
      expect(issue.to_branch_name).to match(/confidential-issue\z/)
    end

    context 'issue title longer than 100 characters' do
      let_it_be(:issue) { create(:issue, project: reusable_project, iid: 999, title: 'Lorem ipsum dolor sit amet consectetur adipiscing elit Mauris sit amet ipsum id lacus custom fringilla convallis') }

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
      let_it_be(:issue) { create(:issue, project: reusable_project) }

      let!(:note1) do
        create(:note_on_issue, noteable: issue, project: reusable_project, note: 'a')
      end

      let!(:note2) do
        create(:note_on_issue, noteable: issue, project: reusable_project, note: 'b')
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
        issue = create(:issue, project: project)
        user = create(:user)

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
      issue = create(:issue, assignees: [user1], project: reusable_project)
      reusable_project.add_developer(user1)
      reusable_project.add_developer(user2)

      expect(user1.assigned_open_issues_count).to eq(1)
      expect(user2.assigned_open_issues_count).to eq(0)

      issue.assignees = [user2]
      issue.save!

      expect(user1.assigned_open_issues_count).to eq(0)
      expect(user2.assigned_open_issues_count).to eq(1)
    end
  end

  describe '#visible_to_user?' do
    let(:project) { reusable_project }
    let(:issue)   { build(:issue, project: project) }

    subject { issue.visible_to_user?(user) }

    context 'with a project' do
      it 'returns false when feature is disabled' do
        project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

        is_expected.to eq(false)
      end

      it 'returns false when restricted for members' do
        project.project_feature.update_attribute(:issues_access_level, ProjectFeature::PRIVATE)

        is_expected.to eq(false)
      end
    end

    context 'without a user' do
      let(:user) { nil }

      before do
        project.project_feature.update_attribute(:issues_access_level, ProjectFeature::PUBLIC)
      end

      it 'returns true when the issue is publicly visible' do
        expect(issue).to receive(:publicly_visible?).and_return(true)

        is_expected.to eq(true)
      end

      it 'returns false when the issue is not publicly visible' do
        expect(issue).to receive(:publicly_visible?).and_return(false)

        is_expected.to eq(false)
      end
    end

    context 'with a user' do
      shared_examples 'issue readable by user' do
        it { is_expected.to eq(true) }
      end

      shared_examples 'issue not readable by user' do
        it { is_expected.to eq(false) }
      end

      shared_examples 'confidential issue readable by user' do
        specify do
          issue.confidential = true

          is_expected.to eq(true)
        end
      end

      shared_examples 'confidential issue not readable by user' do
        specify do
          issue.confidential = true

          is_expected.to eq(false)
        end
      end

      context 'with an admin user' do
        let(:user) { build(:admin) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it_behaves_like 'issue readable by user'
          it_behaves_like 'confidential issue readable by user'
        end

        context 'when admin mode is disabled' do
          it_behaves_like 'issue not readable by user'
          it_behaves_like 'confidential issue not readable by user'
        end
      end

      context 'with an owner' do
        before do
          project.add_maintainer(user)
        end

        it_behaves_like 'issue readable by user'
        it_behaves_like 'confidential issue readable by user'
      end

      context 'with a reporter user' do
        before do
          project.add_reporter(user)
        end

        it_behaves_like 'issue readable by user'
        it_behaves_like 'confidential issue readable by user'
      end

      context 'with a guest user' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'issue readable by user'
        it_behaves_like 'confidential issue not readable by user'

        context 'when user is an assignee' do
          before do
            issue.update!(assignees: [user])
          end

          it_behaves_like 'issue readable by user'
          it_behaves_like 'confidential issue readable by user'
        end

        context 'when user is the author' do
          before do
            issue.update!(author: user)
          end

          it_behaves_like 'issue readable by user'
          it_behaves_like 'confidential issue readable by user'
        end
      end

      context 'with a user that is not a member' do
        context 'using a public project' do
          let(:project) { build(:project, :public) }

          it_behaves_like 'issue readable by user'
          it_behaves_like 'confidential issue not readable by user'
        end

        context 'using an internal project' do
          let(:project) { build(:project, :internal) }

          context 'using an internal user' do
            before do
              allow(user).to receive(:external?).and_return(false)
            end

            it_behaves_like 'issue readable by user'
            it_behaves_like 'confidential issue not readable by user'
          end

          context 'using an external user' do
            before do
              allow(user).to receive(:external?).and_return(true)
            end

            it_behaves_like 'issue not readable by user'
            it_behaves_like 'confidential issue not readable by user'
          end
        end

        context 'using an external user' do
          before do
            allow(user).to receive(:external?).and_return(true)
          end

          it_behaves_like 'issue not readable by user'
          it_behaves_like 'confidential issue not readable by user'
        end
      end

      context 'with an external authentication service' do
        before do
          enable_external_authorization_service_check
        end

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

        context 'with an admin' do
          context 'when admin mode is enabled', :enable_admin_mode do
            it 'does not check the external webservice' do
              issue = build(:issue)
              user = build(:admin)

              expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

              issue.visible_to_user?(user)
            end
          end

          context 'when admin mode is disabled' do
            it 'checks the external service to determine if an issue is readable by the admin' do
              project = build(:project, :public,
                              external_authorization_classification_label: 'a-label')
              issue = build(:issue, project: project)
              user = build(:admin)

              expect(::Gitlab::ExternalAuthorization).to receive(:access_allowed?).with(user, 'a-label') { false }
              expect(issue.visible_to_user?(user)).to be_falsy
            end
          end
        end
      end

      context 'when issue is moved to a private project' do
        let(:private_project) { build(:project, :private)}

        before do
          issue.update!(project: private_project) # move issue to private project
        end

        shared_examples 'issue visible if user has guest access' do
          context 'when user is not a member' do
            it_behaves_like 'issue not readable by user'
            it_behaves_like 'confidential issue not readable by user'
          end

          context 'when user is a guest' do
            before do
              private_project.add_guest(user)
            end

            it_behaves_like 'issue readable by user'
            it_behaves_like 'confidential issue readable by user'
          end
        end

        context 'when user is the author of the original issue' do
          before do
            issue.update!(author: user)
          end

          it_behaves_like 'issue visible if user has guest access'
        end

        context 'when user is an assignee in the original issue' do
          before do
            issue.update!(assignees: [user])
          end

          it_behaves_like 'issue visible if user has guest access'
        end

        context 'when user is not the author or an assignee in original issue' do
          context 'when user is a guest' do
            before do
              private_project.add_guest(user)
            end

            it_behaves_like 'issue readable by user'
            it_behaves_like 'confidential issue not readable by user'
          end

          context 'when user is a reporter' do
            before do
              private_project.add_reporter(user)
            end

            it_behaves_like 'issue readable by user'
            it_behaves_like 'confidential issue readable by user'
          end
        end
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
    let_it_be(:support_bot) { ::User.support_bot }

    where(:support_bot?, :visibility_level, :confidential, :new_attributes, :check_for_spam?) do
      ### non-support-bot cases
      # spammable attributes changing
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { description: 'new' } | true
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { title: 'new' } | true
      # confidential to non-confidential
      false | Gitlab::VisibilityLevel::PUBLIC   | true  | { confidential: false } | true
      # non-confidential to confidential
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { confidential: true } | false
      # spammable attributes changing on confidential
      false | Gitlab::VisibilityLevel::PUBLIC   | true  | { description: 'new' } | false
      # spammable attributes changing while changing to confidential
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { title: 'new', confidential: true } | false
      # spammable attribute not changing
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { description: 'original description' } | false
      # non-spammable attribute changing
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { weight: 3 } | false
      # spammable attributes changing on non-public
      false | Gitlab::VisibilityLevel::INTERNAL | false | { description: 'new' } | false
      false | Gitlab::VisibilityLevel::PRIVATE  | false | { description: 'new' } | false

      ### support-bot cases
      # confidential to non-confidential
      true | Gitlab::VisibilityLevel::PUBLIC    | true  | { confidential: false } | true
      # non-confidential to confidential
      true | Gitlab::VisibilityLevel::PUBLIC    | false | { confidential: true } | false
      # spammable attributes changing on confidential
      true  | Gitlab::VisibilityLevel::PUBLIC   | true  | { description: 'new' } | true
      # spammable attributes changing while changing to confidential
      true  | Gitlab::VisibilityLevel::PUBLIC   | false | { title: 'new', confidential: true } | true
      # spammable attributes changing on non-public
      true  | Gitlab::VisibilityLevel::INTERNAL | false | { description: 'new' } | true
      true  | Gitlab::VisibilityLevel::PRIVATE  | false | { title: 'new' } | true
      # spammable attribute not changing
      true  | Gitlab::VisibilityLevel::PUBLIC   | false | { description: 'original description' } | false
      # non-spammable attribute changing
      true  | Gitlab::VisibilityLevel::PRIVATE  | true  | { weight: 3 } | false
    end

    with_them do
      it 'checks for spam when necessary' do
        author = support_bot? ? support_bot : user
        project = reusable_project
        project.update!(visibility_level: visibility_level)
        issue = create(:issue, project: project, confidential: confidential, description: 'original description', author: author)

        issue.assign_attributes(new_attributes)

        expect(issue.check_for_spam?).to eq(check_for_spam?)
      end
    end
  end

  describe 'removing an issue' do
    it 'refreshes the number of open issues of the project' do
      project = subject.project

      expect { subject.destroy! }
        .to change { project.open_issues_count }.from(1).to(0)
    end
  end

  describe '.public_only' do
    it 'only returns public issues' do
      public_issue = create(:issue, project: reusable_project)
      create(:issue, project: reusable_project, confidential: true)

      expect(described_class.public_only).to eq([public_issue])
    end
  end

  describe '.confidential_only' do
    it 'only returns confidential_only issues' do
      create(:issue, project: reusable_project)
      confidential_issue = create(:issue, project: reusable_project, confidential: true)

      expect(described_class.confidential_only).to eq([confidential_issue])
    end
  end

  describe '.by_project_id_and_iid' do
    let_it_be(:issue_a) { create(:issue, project: reusable_project) }
    let_it_be(:issue_b) { create(:issue, iid: issue_a.iid) }
    let_it_be(:issue_c) { create(:issue, project: issue_a.project) }
    let_it_be(:issue_d) { create(:issue, project: issue_a.project) }

    it_behaves_like 'a where_composite scope', :by_project_id_and_iid do
      let(:all_results) { [issue_a, issue_b, issue_c, issue_d] }
      let(:first_result) { issue_a }

      let(:composite_ids) do
        all_results.map { |issue| { project_id: issue.project_id, iid: issue.iid } }
      end
    end
  end

  describe '.service_desk' do
    it 'returns the service desk issue' do
      service_desk_issue = create(:issue, project: reusable_project, author: ::User.support_bot)
      regular_issue = create(:issue, project: reusable_project)

      expect(described_class.service_desk).to include(service_desk_issue)
      expect(described_class.service_desk).not_to include(regular_issue)
    end
  end

  it_behaves_like 'throttled touch' do
    subject { create(:issue, updated_at: 1.hour.ago) }
  end

  describe "#labels_hook_attrs" do
    let(:label) { create(:label) }
    let(:issue) { create(:labeled_issue, project: reusable_project, labels: [label]) }

    it "returns a list of label hook attributes" do
      expect(issue.labels_hook_attrs).to eq([label.hook_attrs])
    end
  end

  context "relative positioning" do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue1) { create(:issue, project: project, relative_position: nil) }
    let_it_be(:issue2) { create(:issue, project: project, relative_position: nil) }

    it_behaves_like "a class that supports relative positioning" do
      let_it_be(:project) { reusable_project }
      let(:factory) { :issue }
      let(:default_params) { { project: project } }
    end

    it 'is not blocked for repositioning by default' do
      expect(issue1.blocked_for_repositioning?).to eq(false)
    end

    context 'when block_issue_repositioning flag is enabled for group' do
      before do
        stub_feature_flags(block_issue_repositioning: group)
      end

      it 'is blocked for repositioning' do
        expect(issue1.blocked_for_repositioning?).to eq(true)
      end

      it 'does not move issues with null position' do
        payload = [issue1, issue2]

        expect { described_class.move_nulls_to_end(payload) }.to raise_error(Gitlab::RelativePositioning::IssuePositioningDisabled)
        expect { described_class.move_nulls_to_start(payload) }.to raise_error(Gitlab::RelativePositioning::IssuePositioningDisabled)
      end
    end
  end

  it_behaves_like 'versioned description'

  describe "#previous_updated_at" do
    let_it_be(:updated_at) { Time.zone.local(2012, 01, 06) }
    let_it_be(:issue) { create(:issue, project: reusable_project, updated_at: updated_at) }

    it 'returns updated_at value if updated_at did not change at all' do
      allow(issue).to receive(:previous_changes).and_return({})

      expect(issue.previous_updated_at).to eq(updated_at)
    end

    it 'returns updated_at value if `previous_changes` has nil value for `updated_at`' do
      allow(issue).to receive(:previous_changes).and_return({ 'updated_at' => nil })

      expect(issue.previous_updated_at).to eq(updated_at)
    end

    it 'returns updated_at value if previous updated_at value is not present' do
      allow(issue).to receive(:previous_changes).and_return({ 'updated_at' => [nil, Time.zone.local(2013, 02, 06)] })

      expect(issue.previous_updated_at).to eq(updated_at)
    end

    it 'returns previous updated_at when present' do
      allow(issue).to receive(:previous_changes).and_return({ 'updated_at' => [Time.zone.local(2013, 02, 06), Time.zone.local(2013, 03, 06)] })

      expect(issue.previous_updated_at).to eq(Time.zone.local(2013, 02, 06))
    end
  end

  describe '#design_collection' do
    it 'returns a design collection' do
      issue = build(:issue)
      collection = issue.design_collection

      expect(collection).to be_a(DesignManagement::DesignCollection)
      expect(collection.issue).to eq(issue)
    end
  end

  describe 'current designs' do
    let(:issue) { create(:issue, project: reusable_project) }

    subject { issue.designs.current }

    context 'an issue has no designs' do
      it { is_expected.to be_empty }
    end

    context 'an issue only has current designs' do
      let!(:design_a) { create(:design, :with_file, issue: issue) }
      let!(:design_b) { create(:design, :with_file, issue: issue) }
      let!(:design_c) { create(:design, :with_file, issue: issue) }

      it { is_expected.to include(design_a, design_b, design_c) }
    end

    context 'an issue only has deleted designs' do
      let!(:design_a) { create(:design, :with_file, issue: issue, deleted: true) }
      let!(:design_b) { create(:design, :with_file, issue: issue, deleted: true) }
      let!(:design_c) { create(:design, :with_file, issue: issue, deleted: true) }

      it { is_expected.to be_empty }
    end

    context 'an issue has a mixture of current and deleted designs' do
      let!(:design_a) { create(:design, :with_file, issue: issue) }
      let!(:design_b) { create(:design, :with_file, issue: issue, deleted: true) }
      let!(:design_c) { create(:design, :with_file, issue: issue) }

      it { is_expected.to contain_exactly(design_a, design_c) }
    end
  end

  describe '.with_label_attributes' do
    subject { described_class.with_label_attributes(label_attributes) }

    let(:label_attributes) { { title: 'hello world', description: 'hi' } }

    it 'gets issues with given label attributes' do
      label = create(:label, **label_attributes)
      labeled_issue = create(:labeled_issue, project: label.project, labels: [label])

      expect(subject).to include(labeled_issue)
    end

    it 'excludes issues without given label attributes' do
      label = create(:label, title: 'GitLab', description: 'tanuki')
      labeled_issue = create(:labeled_issue, project: label.project, labels: [label])

      expect(subject).not_to include(labeled_issue)
    end
  end

  describe 'banzai_render_context' do
    let(:project) { build(:project_empty_repo) }
    let(:issue) { build :issue, project: project }

    subject(:context) { issue.banzai_render_context(:title) }

    it 'sets the label_url_method in the context' do
      expect(context[:label_url_method]).to eq(:project_issues_url)
    end
  end

  describe 'scheduling rebalancing' do
    before do
      allow_next_instance_of(RelativePositioning::Mover) do |mover|
        allow(mover).to receive(:move) { raise ActiveRecord::QueryCanceled }
      end
    end

    shared_examples 'schedules issues rebalancing' do
      let(:issue) { build_stubbed(:issue, relative_position: 100, project: project) }

      it 'schedules rebalancing if we time-out when moving' do
        lhs = build_stubbed(:issue, relative_position: 99, project: project)
        to_move = build(:issue, project: project)
        expect(IssueRebalancingWorker).to receive(:perform_async).with(nil, project_id, namespace_id)

        expect { to_move.move_between(lhs, issue) }.to raise_error(ActiveRecord::QueryCanceled)
      end
    end

    context 'when project in user namespace' do
      let(:project) { build_stubbed(:project_empty_repo) }
      let(:project_id) { project.id }
      let(:namespace_id) { nil }

      it_behaves_like 'schedules issues rebalancing'
    end

    context 'when project in a group namespace' do
      let(:group) { create(:group) }
      let(:project) { build_stubbed(:project_empty_repo, group: group) }
      let(:project_id) { nil }
      let(:namespace_id) { group.id }

      it_behaves_like 'schedules issues rebalancing'
    end
  end

  describe '#allows_reviewers?' do
    it 'returns false as we do not support reviewers on issues yet' do
      issue = build_stubbed(:issue)

      expect(issue.allows_reviewers?).to be(false)
    end
  end

  describe '#issue_type_supports?' do
    let_it_be(:issue) { create(:issue) }

    it 'raises error when feature is invalid' do
      expect { issue.issue_type_supports?(:unkown_feature) }.to raise_error(ArgumentError)
    end
  end

  describe '#supports_time_tracking?' do
    let_it_be(:project) { create(:project) }
    let_it_be_with_refind(:issue) { create(:incident, project: project) }

    where(:issue_type, :supports_time_tracking) do
      :issue | true
      :incident | true
    end

    with_them do
      before do
        issue.update!(issue_type: issue_type)
      end

      it do
        expect(issue.supports_time_tracking?).to eq(supports_time_tracking)
      end
    end
  end

  describe '#email_participants_emails' do
    let_it_be(:issue) { create(:issue) }

    it 'returns a list of emails' do
      participant1 = issue.issue_email_participants.create!(email: 'a@gitlab.com')
      participant2 = issue.issue_email_participants.create!(email: 'b@gitlab.com')

      expect(issue.email_participants_emails).to contain_exactly(participant1.email, participant2.email)
    end
  end

  describe '#email_participants_downcase' do
    it 'returns a list of emails with all uppercase letters replaced with their lowercase counterparts' do
      participant = create(:issue_email_participant, email: 'SomEoNe@ExamPLe.com')

      expect(participant.issue.email_participants_emails_downcase).to match([participant.email.downcase])
    end
  end
end
