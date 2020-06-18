# frozen_string_literal: true

require 'spec_helper'

describe Issue do
  include ExternalAuthorizationServiceHelpers

  describe "Associations" do
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to belong_to(:iteration) }
    it { is_expected.to belong_to(:project) }
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

    describe 'versions.most_recent' do
      it 'returns the most recent version' do
        issue = create(:issue)
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

  describe '.with_alert_management_alerts' do
    subject { described_class.with_alert_management_alerts }

    it 'gets only issues with alerts' do
      alert = create(:alert_management_alert, issue: create(:issue))
      issue = create(:issue)

      expect(subject).to contain_exactly(alert.issue)
      expect(subject).not_to include(issue)
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

  describe '.simple_sorts' do
    it 'includes all keys' do
      expect(described_class.simple_sorts.keys).to include(
        *%w(created_asc created_at_asc created_date created_desc created_at_desc
            closest_future_date closest_future_date_asc due_date due_date_asc due_date_desc
            id_asc id_desc relative_position relative_position_asc
            updated_desc updated_asc updated_at_asc updated_at_desc))
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

    it 'sets closed_at to Time.current when an issue is closed' do
      expect { issue.close }.to change { issue.closed_at }.from(nil)
    end

    it 'changes the state to closed' do
      open_state = described_class.available_states[:opened]
      closed_state = described_class.available_states[:closed]

      expect { issue.close }.to change { issue.state_id }.from(open_state).to(closed_state)
    end

    context 'when there is an associated Alert Management Alert' do
      context 'when alert can be resolved' do
        let!(:alert) { create(:alert_management_alert, project: issue.project, issue: issue) }

        it 'resolves an alert' do
          expect { issue.close }.to change { alert.reload.resolved? }.to(true)
        end
      end

      context 'when alert cannot be resolved' do
        let!(:alert) { create(:alert_management_alert, :with_validation_errors, project: issue.project, issue: issue) }

        before do
          allow(Gitlab::AppLogger).to receive(:warn).and_call_original
        end

        it 'writes a warning into the log' do
          issue.close

          expect(Gitlab::AppLogger).to have_received(:warn).with(
            message: 'Cannot resolve an associated Alert Management alert',
            issue_id: issue.id,
            alert_id: alert.id,
            alert_errors: { hosts: ['hosts array is over 255 chars'] }
          )
        end
      end
    end
  end

  describe '#reopen' do
    let(:user) { create(:user) }
    let(:issue) { create(:issue, state: 'closed', closed_at: Time.current, closed_by: user) }

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
        let(:another_namespace) { build(:namespace, path: 'another-namespace') }
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
      expect(issue.to_branch_name).to match(/\A#{issue.iid}-[A-Za-z\-]+\z/)
    end

    it "contains the issue title if not confidential" do
      expect(issue.to_branch_name).to match(/testing-issue\z/)
    end

    it "does not contain the issue title if confidential" do
      issue = create(:issue, title: 'testing-issue', confidential: true)
      expect(issue.to_branch_name).to match(/confidential-issue\z/)
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
    let(:project) { build(:project) }
    let(:issue)   { build(:issue, project: project) }
    let(:user)    { create(:user) }

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
          issue.update(project: private_project) # move issue to private project
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

  describe '.by_project_id_and_iid' do
    let_it_be(:issue_a) { create(:issue) }
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

  it_behaves_like 'throttled touch' do
    subject { create(:issue, updated_at: 1.hour.ago) }
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

  describe "#previous_updated_at" do
    let_it_be(:updated_at) { Time.zone.local(2012, 01, 06) }
    let_it_be(:issue) { create(:issue, updated_at: updated_at) }

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
    let(:issue) { create(:issue) }

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
end
