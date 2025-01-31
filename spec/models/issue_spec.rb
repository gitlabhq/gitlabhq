# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issue, feature_category: :team_planning do
  include ExternalAuthorizationServiceHelpers

  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:reusable_project) { create(:project) }

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  # TODO: Remove when issues.work_item_type_id cleanup is complete
  # https://gitlab.com/gitlab-org/gitlab/-/issues/499911
  describe 'database triggers' do
    let_it_be(:type1) { create(:work_item_type, :non_default).tap { |type| type.update!(id: -type.id) } }
    let_it_be(:type2) { create(:work_item_type, :non_default).tap { |type| type.update!(id: -type.id) } }

    context 'when creating an issue' do
      let(:basic_issue_attributes) do
        { project_id: reusable_project.id, namespace_id: reusable_project.project_namespace_id }
      end

      let(:issue) do
        id = ApplicationRecord.legacy_bulk_insert( # rubocop:disable Gitlab/BulkInsert -- Necessary for raw insert in test
          described_class.table_name,
          [basic_issue_attributes.merge(type_attributes)],
          return_ids: true
        ).first
        described_class.find(id)
      end

      context 'when only work_item_type_id is provided' do
        let(:type_attributes) { { work_item_type_id: type1.id } }

        it 'sets correct_work_item_type_id with the correct value' do
          expect(issue.work_item_type_id).to eq(type1.id)
          expect(issue.correct_work_item_type_id).to eq(type1.correct_id)
        end
      end

      context 'when only correct_work_item_type_id is provided' do
        let(:type_attributes) { { correct_work_item_type_id: type1.correct_id } }

        it 'sets correct_work_item_type_id with the correct value' do
          expect(issue.work_item_type_id).to eq(type1.id)
          expect(issue.correct_work_item_type_id).to eq(type1.correct_id)
        end
      end

      context 'when both work_item_type_id and correct_work_item_type_id are provided' do
        let(:type_attributes) { { work_item_type_id: type1.id, correct_work_item_type_id: type2.correct_id } }

        it 'does not overwrite any of the provided values' do
          expect(issue.attributes['work_item_type_id']).to eq(type1.id)
          expect(issue.correct_work_item_type_id).to eq(type2.correct_id)
        end
      end
    end

    context 'when updating an issue' do
      let_it_be_with_reload(:issue) do
        create(:issue, project: reusable_project, work_item_type: create(:work_item_type, :non_default))
      end

      context 'when only work_item_type_id is update' do
        it 'updates correct_work_item_type_id with the correct value' do
          expect do
            issue.update_columns(work_item_type_id: type1.id)
            issue.reload
          end.to change { issue.work_item_type_id }.to(type1.id).and(
            change { issue.correct_work_item_type_id }.to(type1.correct_id)
          )
        end
      end

      context 'when only correct_work_item_type_id is update' do
        it 'updates work_item_type_id with the correct value' do
          expect do
            issue.update_columns(correct_work_item_type_id: type1.correct_id)
            issue.reload
          end.to change { issue.work_item_type_id }.to(type1.id).and(
            change { issue.correct_work_item_type_id }.to(type1.correct_id)
          )
        end
      end

      context 'when both work_item_type_id correct_work_item_type_id are updated' do
        it 'updates both columns with the specified value, no overwrites by the trigger' do
          expect do
            issue.update_columns(work_item_type_id: type1.id, correct_work_item_type_id: type2.correct_id)
            issue.reload
          end.to change { issue.attributes['work_item_type_id'] }.to(type1.id).and(
            change { issue.correct_work_item_type_id }.to(type2.correct_id)
          )
        end
      end
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:work_item_type).class_name('WorkItems::Type') }
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
    it { is_expected.to have_many(:alert_management_alerts).validate(false) }
    it { is_expected.to have_many(:resource_milestone_events) }
    it { is_expected.to have_many(:resource_state_events) }
    it { is_expected.to have_many(:issue_email_participants) }
    it { is_expected.to have_one(:email) }
    it { is_expected.to have_many(:timelogs).autosave(true) }
    it { is_expected.to have_one(:incident_management_issuable_escalation_status) }
    it { is_expected.to have_many(:issue_customer_relations_contacts) }
    it { is_expected.to have_many(:customer_relations_contacts) }
    it { is_expected.to have_many(:incident_management_timeline_events) }
    it { is_expected.to have_many(:assignment_events).class_name('ResourceEvents::IssueAssignmentEvent').inverse_of(:issue) }

    describe '#assignees_by_name_and_id' do
      it 'returns users ordered by name ASC, id DESC' do
        user1 = create(:user, name: 'BBB')
        user2 = create(:user, name: 'AAA')
        user3 = create(:user, name: 'BBB')
        users = [user1, user2, user3]
        issue = create(:issue, project: reusable_project, assignees: users)

        expect(issue.assignees_by_name_and_id).to match([user2, user3, user1])
      end
    end

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
      let(:scope) { :namespace }
      let(:scope_attrs) { { namespace: instance.project.project_namespace } }
      let(:usage) { :issues }
    end
  end

  describe 'custom validations' do
    subject(:valid?) { issue.valid? }

    describe 'due_date_after_start_date' do
      let(:today) { Date.today }

      context 'when both values are not present' do
        let(:issue) { build(:issue) }

        it { is_expected.to be_truthy }
      end

      context 'when start date is present and due date is not' do
        let(:issue) { build(:work_item, start_date: today) }

        it { is_expected.to be_truthy }
      end

      context 'when due date is present and start date is not' do
        let(:issue) { build(:work_item, due_date: today) }

        it { is_expected.to be_truthy }
      end

      context 'when both date values are present' do
        context 'when due date is greater than start date' do
          let(:issue) { build(:work_item, start_date: today, due_date: 1.week.from_now) }

          it { is_expected.to be_truthy }
        end

        context 'when due date is equal to start date' do
          let(:issue) { build(:work_item, start_date: today, due_date: today) }

          it { is_expected.to be_truthy }
        end

        context 'when due date is before start date' do
          let(:issue) { build(:work_item, due_date: today, start_date: 1.week.from_now) }

          it { is_expected.to be_falsey }

          it 'adds an error message' do
            valid?

            expect(issue.errors.full_messages).to contain_exactly(
              'Due date must be greater than or equal to start date'
            )
          end
        end
      end
    end

    describe '#allowed_work_item_type_change' do
      where(:old_type, :new_type, :is_valid) do
        :issue     | :incident  | true
        :incident  | :issue     | true
        :test_case | :issue     | true
        :issue     | :test_case | true
        :issue     | :task      | false
        :test_case | :task      | false
        :incident  | :task      | false
        :task      | :issue     | false
        :task      | :incident  | false
        :task      | :test_case | false
      end

      with_them do
        it 'is possible to change type only between selected types' do
          issue = create(:issue, old_type, project: reusable_project)

          issue.assign_attributes(work_item_type: WorkItems::Type.default_by_type(new_type))

          expect(issue.valid?).to eq(is_valid)
        end
      end
    end

    describe 'confidentiality' do
      let_it_be(:project) { create(:project) }

      context 'when parent and child are confidential' do
        let_it_be(:parent) { create(:work_item, confidential: true, project: project) }
        let_it_be(:child) { create(:work_item, :task, confidential: true, project: project) }
        let_it_be(:link) { create(:parent_link, work_item: child, work_item_parent: parent) }

        it 'does not allow to make child not-confidential' do
          issue = described_class.find(child.id)
          issue.confidential = false

          expect(issue).not_to be_valid
          expect(issue.errors[:base])
            .to include(_('A non-confidential issue cannot have a confidential parent.'))
        end

        it 'allows to make parent not-confidential' do
          issue = described_class.find(parent.id)
          issue.confidential = false

          expect(issue).to be_valid
        end
      end

      context 'when parent and child are not-confidential' do
        let_it_be(:parent) { create(:work_item, project: project) }
        let_it_be(:child) { create(:work_item, :task, project: project) }
        let_it_be(:link) { create(:parent_link, work_item: child, work_item_parent: parent) }

        it 'does not allow to make parent confidential' do
          issue = described_class.find(parent.id)
          issue.confidential = true

          expect(issue).not_to be_valid
          expect(issue.errors[:base])
            .to include(_('A confidential issue must have only confidential children. Make any child items confidential and try again.'))
        end

        it 'allows to make child confidential' do
          issue = described_class.find(child.id)
          issue.confidential = true

          expect(issue).to be_valid
        end
      end
    end
  end

  subject { create(:issue, project: reusable_project) }

  describe 'callbacks' do
    describe '#ensure_metrics!' do
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
        expect(Issue::Metrics).to receive(:record!)

        create(:issue, project: reusable_project)
      end

      context 'when metrics record is missing' do
        before do
          subject.metrics.delete
          subject.reload
        end

        it 'creates the metrics record' do
          subject.update!(title: 'title')

          expect(subject.metrics).to be_present
        end
      end
    end

    describe '#ensure_work_item_type' do
      let_it_be(:issue_type) { create(:work_item_type, :issue) }
      let_it_be(:incident_type) { create(:work_item_type, :incident) }
      let_it_be(:project) { create(:project) }

      context 'when a type was already set' do
        let_it_be(:issue, refind: true) { create(:issue, project: project) }

        it 'does not fetch a work item type from the DB' do
          expect(issue.work_item_type_id).to eq(issue_type.id)
          expect(WorkItems::Type).not_to receive(:default_by_type)

          expect(issue).to be_valid
        end

        it 'does not fetch a work item type from the DB when updating the type' do
          expect(issue.work_item_type_id).to eq(issue_type.id)
          expect(WorkItems::Type).not_to receive(:default_by_type)

          issue.update!(work_item_type: incident_type)

          expect(issue.work_item_type_id).to eq(incident_type.id)
        end

        it 'ensures a work item type if updated to nil' do
          expect(issue.work_item_type_id).to eq(issue_type.id)

          expect do
            issue.update!(work_item_type: nil)
          end.to not_change(issue, :work_item_type).from(issue_type)
        end
      end

      context 'when no type was set' do
        let(:issue) { build(:issue, project: project, work_item_type: nil) }

        it 'sets a work item type before validation' do
          expect(issue.work_item_type_id).to be_nil

          issue.save!

          expect(issue.work_item_type_id).to eq(issue_type.id)
        end

        it 'does not fetch type from DB if provided during update' do
          expect(issue.work_item_type_id).to be_nil
          expect(WorkItems::Type).not_to receive(:default_by_type)

          issue.update!(work_item_type: incident_type)

          expect(issue.work_item_type_id).to eq(incident_type.id)
        end
      end
    end

    describe '#record_create_action' do
      it 'records the creation action after saving' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_created_action)

        create(:issue)
      end

      it_behaves_like 'internal event tracking' do
        let(:project) { reusable_project }
        let(:event) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_CREATED }

        subject { create(:issue, project: reusable_project, author: user) }
      end
    end

    context 'issue namespace' do
      let(:issue) { build(:issue, project: reusable_project) }

      it 'sets the namespace_id' do
        expect(issue).to be_valid
        expect(issue.namespace).to eq(reusable_project.project_namespace)
      end

      context 'when issue is created' do
        it 'sets the namespace_id' do
          issue.save!

          expect(issue.reload.namespace).to eq(reusable_project.project_namespace)
        end
      end

      context 'when existing issue is saved' do
        let(:issue) { create(:issue) }

        before do
          issue.update!(namespace_id: nil)
        end

        it 'sets the namespace id' do
          issue.update!(title: "#{issue.title} and something extra")

          expect(issue.namespace).to eq(issue.project.project_namespace)
        end
      end
    end
  end

  describe 'scopes for preloading' do
    before_all do
      create(:issue, project: reusable_project)
    end

    describe '.preload_namespace' do
      subject(:preload_namespace) { described_class.in_projects(reusable_project).preload_namespace }

      it { expect(preload_namespace.first.association(:namespace)).to be_loaded }
    end

    describe '.preload_routables' do
      subject(:preload_routables) { described_class.in_projects(reusable_project).preload_routables }

      it { expect(preload_routables.first.association(:project)).to be_loaded }
      it { expect(preload_routables.first.project.association(:route)).to be_loaded }
      it { expect(preload_routables.first.project.association(:namespace)).to be_loaded }
      it { expect(preload_routables.first.project.namespace.association(:route)).to be_loaded }
    end
  end

  describe '.in_namespaces_with_cte' do
    let_it_be(:issue) { create(:issue, project: reusable_project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:other_issue) { create(:issue, project: other_project) }

    subject(:in_namespaces_with_cte) { described_class.in_namespaces_with_cte(Namespace.where(id: issue.namespace_id)) }

    it 'returns issues from a given namespace' do
      expect(in_namespaces_with_cte).to match_array(issue)
    end

    it 'can be used with other scopes' do
      expect(in_namespaces_with_cte.with_work_item_type).to match_array(issue)
    end
  end

  context 'order by upvotes' do
    let!(:issue) { create(:issue) }
    let!(:issue2) { create(:issue) }
    let!(:award_emoji) { create(:award_emoji, :upvote, awardable: issue2) }

    describe '.order_upvotes_desc' do
      it 'orders on upvotes' do
        expect(described_class.order_upvotes_desc.to_a).to eq [issue2, issue]
      end
    end

    describe '.order_upvotes_asc' do
      it 'orders on upvotes' do
        expect(described_class.order_upvotes_asc.to_a).to eq [issue, issue2]
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

  describe '.due_before' do
    subject { described_class.due_before(Date.current) }

    let!(:issue) { create(:issue, project: reusable_project, due_date: 1.day.ago) }
    let!(:issue2) { create(:issue, project: reusable_project, due_date: 1.day.from_now) }

    it 'returns issues which are over due' do
      expect(subject).to contain_exactly(issue)
    end
  end

  describe '.due_after' do
    subject { described_class.due_after(Date.current) }

    let!(:issue) { create(:issue, project: reusable_project, due_date: 1.day.ago) }
    let!(:issue2) { create(:issue, project: reusable_project, due_date: 1.day.from_now) }

    it 'returns issues which are due in the future' do
      expect(subject).to contain_exactly(issue2)
    end
  end

  describe '.simple_sorts' do
    it 'includes all keys' do
      expect(described_class.simple_sorts.keys).to include(
        *%w[created_asc created_at_asc created_date created_desc created_at_desc
            closest_future_date closest_future_date_asc due_date due_date_asc due_date_desc
            id_asc id_desc relative_position relative_position_asc updated_desc updated_asc
            updated_at_asc updated_at_desc title_asc title_desc])
    end
  end

  describe '.in_namespaces' do
    let(:group) { create(:group) }
    let!(:group_work_item) { create(:issue, :group_level, namespace: group) }
    let!(:project_work_item) { create(:issue, project: reusable_project) }

    subject { described_class.in_namespaces(group) }

    it { is_expected.to contain_exactly(group_work_item) }
  end

  describe '.with_issue_type' do
    let_it_be(:issue) { create(:issue, project: reusable_project) }
    let_it_be(:incident) { create(:incident, project: reusable_project) }

    it 'returns issues with the given issue type' do
      expect(described_class.with_issue_type('issue'))
        .to contain_exactly(issue)
    end

    context 'when multiple issue_types are provided' do
      it 'returns issues with the given issue types' do
        expect(described_class.with_issue_type(%w[issue incident]))
          .to contain_exactly(issue, incident)
      end

      it 'joins the work_item_types table for filtering with issues.correct_work_item_type_id column' do
        expect do
          described_class.with_issue_type([:issue, :incident]).to_a
        end.to make_queries_matching(
          %r{
            INNER\sJOIN\s"work_item_types"\sON\s"work_item_types"\."correct_id"\s=\s"issues"\."correct_work_item_type_id"
            \sWHERE\s"work_item_types"\."base_type"\sIN\s\(0,\s1\)
          }x
        )
      end
    end

    context 'when a single issue_type is provided' do
      it 'uses an optimized query for a single work item type using issues.correct_work_item_type_id column' do
        expect do
          described_class.with_issue_type([:incident]).to_a
        end.to make_queries_matching(
          %r{
            WHERE\s\("issues"\."correct_work_item_type_id"\s=
            \s\(SELECT\s"work_item_types"\."correct_id"\sFROM\s"work_item_types"
            \sWHERE\s"work_item_types"\."base_type"\s=\s1
            \sLIMIT\s1\)\)
          }x
        )
      end
    end

    context 'when no types are provided' do
      it 'activerecord handles the false condition' do
        expect(described_class.with_issue_type([]).to_sql).to include('WHERE 1=0')
      end
    end
  end

  describe '.without_issue_type' do
    let_it_be(:issue) { create(:issue, project: reusable_project) }
    let_it_be(:incident) { create(:incident, project: reusable_project) }
    let_it_be(:task) { create(:issue, :task, project: reusable_project) }

    it 'returns issues without the given issue type' do
      expect(described_class.without_issue_type('issue'))
        .to contain_exactly(incident, task)
    end

    it 'returns issues without the given issue types' do
      expect(described_class.without_issue_type(%w[issue incident]))
        .to contain_exactly(task)
    end

    it 'uses the work_item_types table and issues.correct_work_item_type_id for filtering' do
      expect do
        described_class.without_issue_type(:issue).to_a
      end.to make_queries_matching(
        %r{
          INNER\sJOIN\s"work_item_types"\sON\s"work_item_types"\."correct_id"\s=\s"issues"\."correct_work_item_type_id"
          \sWHERE\s"work_item_types"\."base_type"\s!=\s0
        }x
      )
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

  describe '.order_title' do
    let_it_be(:issue1) { create(:issue, title: 'foo') }
    let_it_be(:issue2) { create(:issue, title: 'bar') }
    let_it_be(:issue3) { create(:issue, title: 'baz') }
    let_it_be(:issue4) { create(:issue, title: 'Baz 2') }

    context 'sorting ascending' do
      subject { described_class.order_title_asc }

      it { is_expected.to eq([issue2, issue3, issue4, issue1]) }
    end

    context 'sorting descending' do
      subject { described_class.order_title_desc }

      it { is_expected.to eq([issue1, issue4, issue3, issue2]) }
    end
  end

  describe '#order_by_relative_position' do
    let(:project) { reusable_project }
    let!(:issue1) { create(:issue, project: project) }
    let!(:issue2) { create(:issue, project: project) }
    let!(:issue3) { create(:issue, project: project, relative_position: -200) }
    let!(:issue4) { create(:issue, project: project, relative_position: -100) }

    it 'returns ordered list' do
      expect(project.issues.order_by_relative_position)
        .to match [issue3, issue4, issue1, issue2]
    end
  end

  context 'order by escalation status' do
    let_it_be(:triggered_incident) { create(:incident_management_issuable_escalation_status, :triggered).issue }
    let_it_be(:resolved_incident) { create(:incident_management_issuable_escalation_status, :resolved).issue }
    let_it_be(:issue_no_status) { create(:issue) }

    describe '.order_escalation_status_asc' do
      subject { described_class.order_escalation_status_asc }

      it { is_expected.to eq([triggered_incident, resolved_incident, issue_no_status]) }
    end

    describe '.order_escalation_status_desc' do
      subject { described_class.order_escalation_status_desc }

      it { is_expected.to eq([resolved_incident, triggered_incident, issue_no_status]) }
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
    let_it_be_with_reload(:issue) { create(:issue, project: reusable_project, state: 'closed', closed_at: Time.current, closed_by: user) }

    it 'sets closed_at to nil when an issue is reopened' do
      expect { issue.reopen }.to change { issue.closed_at }.to(nil)
    end

    it 'sets closed_by to nil when an issue is reopened' do
      expect { issue.reopen }.to change { issue.closed_by }.from(user).to(nil)
    end

    it 'clears moved_to_id for moved issues' do
      moved_issue = create(:issue)

      issue.update!(moved_to_id: moved_issue.id)

      expect { issue.reopen }.to change { issue.moved_to_id }.from(moved_issue.id).to(nil)
    end

    it 'clears duplicated_to_id for duplicated issues' do
      duplicate_issue = create(:issue)

      issue.update!(duplicated_to_id: duplicate_issue.id)

      expect { issue.reopen }.to change { issue.duplicated_to_id }.from(duplicate_issue.id).to(nil)
    end

    it 'changes the state to opened' do
      expect { issue.reopen }.to change { issue.state_id }.from(described_class.available_states[:closed]).to(described_class.available_states[:opened])
    end
  end

  describe '#to_reference' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project)   { create(:project, namespace: namespace) }
    let_it_be(:issue)     { create(:issue, project: project) }

    context 'when nil argument' do
      it 'returns issue id' do
        expect(issue.to_reference).to eq "##{issue.iid}"
      end

      it 'returns complete path to the issue with full: true' do
        expect(issue.to_reference(full: true)).to eq "#{project.full_path}##{issue.iid}"
      end
    end

    context 'when argument is a project' do
      context 'when same project' do
        it 'returns issue id' do
          expect(issue.to_reference(project)).to eq("##{issue.iid}")
        end

        it 'returns full reference with full: true' do
          expect(issue.to_reference(project, full: true)).to eq "#{project.full_path}##{issue.iid}"
        end
      end

      context 'when cross-project in same namespace' do
        let(:another_project) do
          create(:project, namespace: project.namespace)
        end

        it 'returns a cross-project reference' do
          expect(issue.to_reference(another_project)).to eq "#{project.path}##{issue.iid}"
        end
      end

      context 'when cross-project in different namespace' do
        let(:another_namespace) { build(:namespace, id: non_existing_record_id, path: 'another-namespace') }
        let(:another_namespace_project) { build(:project, namespace: another_namespace) }

        it 'returns complete path to the issue' do
          expect(issue.to_reference(another_namespace_project)).to eq "#{project.full_path}##{issue.iid}"
        end
      end
    end

    context 'when argument is a namespace' do
      context 'when same as issue' do
        it 'returns path to the issue with the project name' do
          expect(issue.to_reference(namespace)).to eq "#{project.path}##{issue.iid}"
        end

        it 'returns full reference with full: true' do
          expect(issue.to_reference(namespace, full: true)).to eq "#{project.full_path}##{issue.iid}"
        end
      end

      context 'when different to issue namespace' do
        let(:group) { build(:group, name: 'Group', path: 'sample-group') }

        it 'returns full path to the issue with full: true' do
          expect(issue.to_reference(group)).to eq "#{project.full_path}##{issue.iid}"
        end
      end
    end
  end

  describe '#to_reference with table syntax' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let_it_be(:user_namespace) { user.namespace }

    let_it_be(:parent) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent) }
    let_it_be(:another_group) { create(:group) }

    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:project_namespace) { project.project_namespace }
    let_it_be(:same_namespace_project) { create(:project, namespace: group) }
    let_it_be(:same_namespace_project_namespace) { same_namespace_project.project_namespace }

    let_it_be(:another_namespace_project) { create(:project) }
    let_it_be(:another_namespace_project_namespace) { another_namespace_project.project_namespace }

    let_it_be(:project_issue) { build(:issue, project: project, iid: 123) }
    let_it_be(:project_issue_full_reference) { "#{project.full_path}##{project_issue.iid}" }

    let_it_be(:group_issue) { build(:issue, namespace: group, iid: 123) }
    let_it_be(:group_issue_full_reference) { "#{group.full_path}##{group_issue.iid}" }

    # this one is just theoretically possible, not smth to be supported for real
    let_it_be(:user_issue) { build(:issue, namespace: user_namespace, iid: 123) }
    let_it_be(:user_issue_full_reference) { "#{user_namespace.full_path}##{user_issue.iid}" }

    # namespace would be group, project namespace or user namespace
    where(:issue, :full, :from, :result) do
      ref(:project_issue) | false | nil                                       | lazy { "##{issue.iid}" }
      ref(:project_issue) | true  | nil                                       | ref(:project_issue_full_reference)
      ref(:project_issue) | false | ref(:group)                               | lazy { "#{project.path}##{issue.iid}" }
      ref(:project_issue) | true  | ref(:group)                               | ref(:project_issue_full_reference)
      ref(:project_issue) | false | ref(:parent)                              | ref(:project_issue_full_reference)
      ref(:project_issue) | true  | ref(:parent)                              | ref(:project_issue_full_reference)
      ref(:project_issue) | false | ref(:project)                             | lazy { "##{issue.iid}" }
      ref(:project_issue) | true  | ref(:project)                             | ref(:project_issue_full_reference)
      ref(:project_issue) | false | ref(:project_namespace)                   | lazy { "##{issue.iid}" }
      ref(:project_issue) | true  | ref(:project_namespace)                   | ref(:project_issue_full_reference)
      ref(:project_issue) | false | ref(:same_namespace_project)              | lazy { "#{project.path}##{issue.iid}" }
      ref(:project_issue) | true  | ref(:same_namespace_project)              | ref(:project_issue_full_reference)
      ref(:project_issue) | false | ref(:same_namespace_project_namespace)    | lazy { "#{project.path}##{issue.iid}" }
      ref(:project_issue) | true  | ref(:same_namespace_project_namespace)    | ref(:project_issue_full_reference)
      ref(:project_issue) | false | ref(:another_group)                       | ref(:project_issue_full_reference)
      ref(:project_issue) | true  | ref(:another_group)                       | ref(:project_issue_full_reference)
      ref(:project_issue) | false | ref(:another_namespace_project)           | ref(:project_issue_full_reference)
      ref(:project_issue) | true  | ref(:another_namespace_project)           | ref(:project_issue_full_reference)
      ref(:project_issue) | false | ref(:another_namespace_project_namespace) | ref(:project_issue_full_reference)
      ref(:project_issue) | true  | ref(:another_namespace_project_namespace) | ref(:project_issue_full_reference)
      ref(:project_issue) | false | ref(:user_namespace)                      | ref(:project_issue_full_reference)
      ref(:project_issue) | true  | ref(:user_namespace)                      | ref(:project_issue_full_reference)

      ref(:group_issue) | false | nil                                         | lazy { "##{issue.iid}" }
      ref(:group_issue) | true  | nil                                         | ref(:group_issue_full_reference)
      ref(:group_issue) | false | ref(:user_namespace)                        | ref(:group_issue_full_reference)
      ref(:group_issue) | true  | ref(:user_namespace)                        | ref(:group_issue_full_reference)
      ref(:group_issue) | false | ref(:group)                                 | lazy { "##{issue.iid}" }
      ref(:group_issue) | true  | ref(:group)                                 | ref(:group_issue_full_reference)
      ref(:group_issue) | false | ref(:parent)                                | ref(:group_issue_full_reference)
      ref(:group_issue) | true  | ref(:parent)                                | ref(:group_issue_full_reference)
      ref(:group_issue) | false | ref(:project)                               | lazy { "#{group.path}##{issue.iid}" }
      ref(:group_issue) | true  | ref(:project)                               | ref(:group_issue_full_reference)
      ref(:group_issue) | false | ref(:project_namespace)                     | lazy { "#{group.path}##{issue.iid}" }
      ref(:group_issue) | true  | ref(:project_namespace)                     | ref(:group_issue_full_reference)
      ref(:group_issue) | false | ref(:another_group)                         | ref(:group_issue_full_reference)
      ref(:group_issue) | true  | ref(:another_group)                         | ref(:group_issue_full_reference)
      ref(:group_issue) | false | ref(:another_namespace_project)             | ref(:group_issue_full_reference)
      ref(:group_issue) | true  | ref(:another_namespace_project)             | ref(:group_issue_full_reference)
      ref(:group_issue) | false | ref(:another_namespace_project_namespace)   | ref(:group_issue_full_reference)
      ref(:group_issue) | true  | ref(:another_namespace_project_namespace)   | ref(:group_issue_full_reference)

      ref(:user_issue) | false | nil                                          | lazy { "##{issue.iid}" }
      ref(:user_issue) | true  | nil                                          | ref(:user_issue_full_reference)
      ref(:user_issue) | false | ref(:user_namespace)                         | lazy { "##{issue.iid}" }
      ref(:user_issue) | true  | ref(:user_namespace)                         | ref(:user_issue_full_reference)
      ref(:user_issue) | false | ref(:group)                                  | ref(:user_issue_full_reference)
      ref(:user_issue) | true  | ref(:group)                                  | ref(:user_issue_full_reference)
      ref(:user_issue) | false | ref(:parent)                                 | ref(:user_issue_full_reference)
      ref(:user_issue) | true  | ref(:parent)                                 | ref(:user_issue_full_reference)
      ref(:user_issue) | false | ref(:project)                                | ref(:user_issue_full_reference)
      ref(:user_issue) | true  | ref(:project)                                | ref(:user_issue_full_reference)
      ref(:user_issue) | false | ref(:project_namespace)                      | ref(:user_issue_full_reference)
      ref(:user_issue) | true  | ref(:project_namespace)                      | ref(:user_issue_full_reference)
      ref(:user_issue) | false | ref(:another_group)                          | ref(:user_issue_full_reference)
      ref(:user_issue) | true  | ref(:another_group)                          | ref(:user_issue_full_reference)
      ref(:user_issue) | false | ref(:another_namespace_project)              | ref(:user_issue_full_reference)
      ref(:user_issue) | true  | ref(:another_namespace_project)              | ref(:user_issue_full_reference)
      ref(:user_issue) | false | ref(:another_namespace_project_namespace)    | ref(:user_issue_full_reference)
      ref(:user_issue) | true  | ref(:another_namespace_project_namespace)    | ref(:user_issue_full_reference)
    end

    with_them do
      it 'returns correct reference' do
        expect(issue.to_reference(from, full: full)).to eq(result)
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

  describe '#related_issues to relate incidents and issues' do
    let_it_be(:authorized_project) { create(:project) }
    let_it_be(:authorized_project2) { create(:project) }
    let_it_be(:unauthorized_project) { create(:project) }

    let_it_be(:authorized_issue_a) { create(:issue, project: authorized_project) }
    let_it_be(:authorized_issue_b) { create(:issue, project: authorized_project) }
    let_it_be(:authorized_issue_c) { create(:issue, project: authorized_project2) }
    let_it_be(:authorized_incident_a) { create(:incident, project: authorized_project) }

    let_it_be(:unauthorized_issue) { create(:issue, project: unauthorized_project) }

    let_it_be(:issue_link_a) { create(:issue_link, source: authorized_issue_a, target: authorized_issue_b) }
    let_it_be(:issue_link_b) { create(:issue_link, source: authorized_issue_a, target: unauthorized_issue) }
    let_it_be(:issue_link_c) { create(:issue_link, source: authorized_issue_a, target: authorized_issue_c) }
    let_it_be(:issue_incident_link_a) { create(:issue_link, source: authorized_issue_a, target: authorized_incident_a) }

    before_all do
      authorized_project.add_developer(user)
      authorized_project2.add_developer(user)
    end

    it 'returns only authorized related issues for given user' do
      expect(authorized_issue_a.related_issues(user))
        .to contain_exactly(authorized_issue_b, authorized_issue_c, authorized_incident_a)
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
          .to contain_exactly(authorized_issue_b, authorized_incident_a)
      end
    end

    context 'when authorize argument is false' do
      it 'returns all related issues' do
        expect(authorized_issue_a.related_issues(authorize: false))
          .to contain_exactly(authorized_issue_b, authorized_issue_c, authorized_incident_a, unauthorized_issue)
      end
    end

    context 'when current_user argument is nil' do
      let_it_be(:public_issue) { create(:issue, project: create(:project, :public)) }

      it 'returns public linked issues only' do
        create(:issue_link, source: authorized_issue_a, target: public_issue)

        expect(authorized_issue_a.related_issues).to contain_exactly(public_issue)
      end
    end

    context 'when issue is a new record' do
      let(:new_issue) { build(:issue, project: authorized_project) }

      it { expect(new_issue.related_issues(user)).to be_empty }
    end
  end

  describe '#can_move?' do
    let(:issue) { create(:issue) }

    subject { issue.can_move?(user) }

    context 'user is not a member of project issue belongs to' do
      it { is_expected.to eq false }
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
      let(:issue) { create(:issue, project: reusable_project, author: ::Users::Internal.support_bot) }

      it { is_expected.to be_truthy }
    end

    context 'when issue author is not support bot' do
      let(:issue) { create(:issue, project: reusable_project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#autoclose_by_merged_closing_merge_request?' do
    subject { issue.autoclose_by_merged_closing_merge_request? }

    context 'when issue belongs to a group' do
      let(:issue) { build_stubbed(:issue, :group_level, namespace: build_stubbed(:group)) }

      it { is_expected.to eq(false) }
    end

    context 'when issue belongs to a project' do
      let(:issue) { build_stubbed(:issue, project: reusable_project) }

      context 'when autoclose_referenced_issues is enabled for the project' do
        it { is_expected.to eq(true) }
      end

      context 'when autoclose_referenced_issues is disabled for the project' do
        before do
          issue.project.update!(autoclose_referenced_issues: false)
        end

        it { is_expected.to eq(false) }
      end
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
      it 'returns #to_branch_name ending with max index + 1' do
        allow(repository).to receive(:branch_exists?).and_return(true)
        allow(repository).to receive(:branch_exists?).with("#{subject.to_branch_name}-3").and_return(false)

        expect(subject.suggested_branch_name).to eq("#{subject.to_branch_name}-3")
      end

      context 'when branch name still exists after 5 attempts' do
        it 'returns #to_branch_name ending with random characters' do
          allow(repository).to receive(:branch_exists?).with(subject.to_branch_name).and_return(true)
          allow(repository).to receive(:branch_exists?).with(/#{subject.to_branch_name}-\d/).and_return(true)
          allow(repository).to receive(:branch_exists?).with(/#{subject.to_branch_name}-\h{8}/).and_return(false)

          expect(subject.suggested_branch_name).to match(/#{subject.to_branch_name}-\h{8}/)
        end
      end
    end
  end

  it_behaves_like 'a time trackable' do
    let(:trackable) { create(:issue) }
    let(:timelog) { create(:issue_timelog, issue: trackable) }
  end

  it_behaves_like 'an editable mentionable' do
    subject { create(:issue, project: create(:project, :repository)) }

    let(:backref_text) { "issue #{subject.to_reference}" }
    let(:set_mentionable_text) { ->(txt) { subject.description = txt } }
  end

  it_behaves_like 'a Taskable' do
    let(:subject) { create :issue }
  end

  describe '.to_branch_name' do
    it 'parameterizes arguments and joins with dashes' do
      expect(described_class.to_branch_name(123, 'foo bar!@#$%f!o@o#b$a%r^')).to eq('123-foo-bar-f-o-o-b-a-r')
    end

    it 'preserves the case in the first argument' do
      expect(described_class.to_branch_name('ACME-!@#$-123', 'FoO BaR')).to eq('ACME-123-foo-bar')
    end

    it 'truncates branch name to at most 100 characters' do
      expect(described_class.to_branch_name('a' * 101, 'a')).to eq('a' * 100)
    end

    it 'truncates dangling parts of the branch name' do
      branch_name = described_class.to_branch_name(
        999,
        'Lorem ipsum dolor sit amet consectetur adipiscing elit Mauris sit amet ipsum id lacus custom fringilla convallis'
      )

      # 100 characters would've got us "999-lorem...lacus-custom-fri".
      expect(branch_name).to eq('999-lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit-mauris-sit-amet-ipsum-id-lacus-custom')
    end

    it 'takes issue branch template into account' do
      project = create(:project)
      project.project_setting.update!(issue_branch_template: 'feature-%{id}-%{title}')

      expect(described_class.to_branch_name(123, 'issue title', project: project)).to eq('feature-123-issue-title')
    end
  end

  describe '#to_branch_name' do
    let_it_be(:issue, reload: true) { create(:issue, project: reusable_project, iid: 123, title: 'Testing Issue') }

    it 'returns a branch name with the issue title if not confidential' do
      expect(issue.to_branch_name).to eq('123-testing-issue')
    end

    it 'returns a generic branch name if confidential' do
      issue.confidential = true
      expect(issue.to_branch_name).to eq('123-confidential-issue')
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
    it_behaves_like 'issuable participants' do
      let_it_be(:issuable_parent) { create(:project, :public) }
      let_it_be_with_refind(:issuable) { create(:issue, project: issuable_parent) }

      let(:params) { { noteable: issuable, project: issuable_parent } }
    end

    context 'using a private project' do
      it 'does not include mentioned users that do not have access to the project' do
        project = create(:project)
        issue = create(:issue, project: project)
        user = create(:user)

        create(
          :note_on_issue,
          noteable: issue,
          project: project,
          note: user.to_reference
        )

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
        project.add_developer(user)
        project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

        is_expected.to eq(false)
      end
    end

    context 'with a group level issue' do
      let_it_be(:group) { create(:group) }
      let(:issue) { build(:work_item, :group_level, namespace: group) }

      context 'when readable_by? is false' do
        it 'returns false' do
          allow(issue).to receive(:readable_by?).and_return false
          is_expected.to eq(false)
        end
      end

      context 'when readable_by? is true' do
        before do
          allow(issue).to receive(:readable_by?).and_return true
        end

        it { is_expected.to eq(true) }

        context 'when user.can_read_all_resources? is true' do
          before do
            allow(user).to receive(:can_read_all_resources?).and_return true
          end

          it { is_expected.to eq(true) }

          it 'does not check project external authorization' do
            expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

            is_expected.to eq(true)
          end
        end

        context 'when user.can_read_all_resources? is false' do
          before do
            allow(user).to receive(:can_read_all_resources?).and_return false
          end

          it { is_expected.to eq(true) }

          it 'does not check project external authorization' do
            expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

            is_expected.to eq(true)
          end
        end
      end
    end

    context 'without a user' do
      let(:user) { nil }

      context 'with issue available as public' do
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

      context 'with issues available only to team members in a public project' do
        let(:public_project) { create(:project, :public) }
        let(:issue) { build(:issue, project: public_project) }

        before do
          public_project.project_feature.update_attribute(:issues_access_level, ProjectFeature::PRIVATE)
        end

        it 'returns false' do
          is_expected.to eq(false)
        end
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

      shared_examples 'hidden issue readable by user' do
        before do
          issue.author.ban!
        end

        specify do
          is_expected.to eq(true)
        end

        after do
          issue.author.activate!
        end
      end

      shared_examples 'hidden issue not readable by user' do
        before do
          issue.author.ban!
        end

        specify do
          is_expected.to eq(false)
        end

        after do
          issue.author.activate!
        end
      end

      context 'with an admin user' do
        let(:user) { build(:admin) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it_behaves_like 'issue readable by user'
          it_behaves_like 'confidential issue readable by user'
          it_behaves_like 'hidden issue readable by user'
        end

        context 'when admin mode is disabled' do
          it_behaves_like 'issue not readable by user'
          it_behaves_like 'confidential issue not readable by user'
          it_behaves_like 'hidden issue not readable by user'
        end
      end

      # TODO update when we have multiple owners of a project
      # https://gitlab.com/gitlab-org/gitlab/-/issues/350605
      context 'with an owner' do
        before do
          project.add_maintainer(user)
        end

        it_behaves_like 'issue readable by user'
        it_behaves_like 'confidential issue readable by user'
        it_behaves_like 'hidden issue not readable by user'
      end

      context 'with a reporter user' do
        before do
          project.add_reporter(user)
        end

        it_behaves_like 'issue readable by user'
        it_behaves_like 'confidential issue readable by user'
        it_behaves_like 'hidden issue not readable by user'
      end

      context 'with a guest user' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'issue readable by user'
        it_behaves_like 'confidential issue not readable by user'
        it_behaves_like 'hidden issue not readable by user'

        context 'when user is an assignee' do
          before do
            issue.update!(assignees: [user])
          end

          it_behaves_like 'issue readable by user'
          it_behaves_like 'confidential issue readable by user'
          it_behaves_like 'hidden issue not readable by user'
        end

        context 'when user is the author' do
          before do
            issue.update!(author: user)
          end

          it_behaves_like 'issue readable by user'
          it_behaves_like 'confidential issue readable by user'
          it_behaves_like 'hidden issue not readable by user'
        end
      end

      context 'with a user that is not a member' do
        context 'using a public project' do
          let(:project) { build(:project, :public) }

          it_behaves_like 'issue readable by user'
          it_behaves_like 'confidential issue not readable by user'
          it_behaves_like 'hidden issue not readable by user'
        end

        context 'using an internal project' do
          let(:project) { build(:project, :internal) }

          context 'using an internal user' do
            before do
              allow(user).to receive(:external?).and_return(false)
            end

            it_behaves_like 'issue readable by user'
            it_behaves_like 'confidential issue not readable by user'
            it_behaves_like 'hidden issue not readable by user'
          end

          context 'using an external user' do
            before do
              allow(user).to receive(:external?).and_return(true)
            end

            it_behaves_like 'issue not readable by user'
            it_behaves_like 'confidential issue not readable by user'
            it_behaves_like 'hidden issue not readable by user'
          end
        end

        context 'using an external user' do
          before do
            allow(user).to receive(:external?).and_return(true)
          end

          it_behaves_like 'issue not readable by user'
          it_behaves_like 'confidential issue not readable by user'
          it_behaves_like 'hidden issue not readable by user'
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
          project = build(:project, :public, external_authorization_classification_label: 'a-label')
          issue = build(:issue, project: project)
          user = build(:user)

          allow(::Gitlab::ExternalAuthorization).to receive(:access_allowed?).with(user, 'a-label', project.full_path).and_call_original
          expect(::Gitlab::ExternalAuthorization).to receive(:access_allowed?).with(user, 'a-label') { false }
          expect(issue.visible_to_user?(user)).to be_falsy
        end

        it 'does not check the external service if a user does not have access to the project' do
          project = build(:project, :private, external_authorization_classification_label: 'a-label')
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
              project = build(:project, :public, external_authorization_classification_label: 'a-label')
              issue = build(:issue, project: project)
              user = build(:admin)

              allow(::Gitlab::ExternalAuthorization).to receive(:access_allowed?).with(user, 'a-label', project.full_path).and_call_original
              expect(::Gitlab::ExternalAuthorization).to receive(:access_allowed?).with(user, 'a-label') { false }
              expect(issue.visible_to_user?(user)).to be_falsy
            end
          end
        end
      end

      context 'when issue is moved to a private project' do
        let(:private_project) { build(:project, :private) }

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
    let(:project) { build(:project, project_visibility) }
    let(:issue) { build(:issue, confidential: confidential, project: project) }

    subject { issue.send(:publicly_visible?) }

    where(:project_visibility, :confidential, :expected_value) do
      :public   | false | true
      :public   | true  | false
      :internal | false | false
      :internal | true  | false
      :private  | false | false
      :private  | true  | false
    end

    with_them do
      it { is_expected.to eq(expected_value) }
    end

    context 'with group level issues' do
      let(:group) { build(:group, group_visibility) }
      let(:issue) { build(:issue, :group_level, confidential: confidential, namespace: group) }

      before do
        stub_licensed_features(epics: false)
      end

      where(:group_visibility, :confidential, :expected_value) do
        :public   | false | false
        :public   | true  | false
        :internal | false | false
        :internal | true  | false
        :private  | false | false
        :private  | true  | false
      end

      with_them do
        it { is_expected.to eq(expected_value) }
      end
    end
  end

  describe '#allow_possible_spam?' do
    let_it_be(:issue) { build(:issue) }

    subject { issue.allow_possible_spam?(issue.author) }

    context 'when the `allow_possible_spam` application setting is turned off' do
      context 'when the issue is private' do
        it { is_expected.to eq(true) }

        context 'when the user is the support bot' do
          before do
            allow(issue.author).to receive(:support_bot?).and_return(true)
          end

          it { is_expected.to eq(false) }
        end
      end

      context 'when the issue is public' do
        before do
          allow(issue).to receive(:publicly_visible?).and_return(true)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when the `allow_possible_spam` application setting is turned on' do
      before do
        stub_application_setting(allow_possible_spam: true)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#check_for_spam?' do
    let_it_be(:support_bot) { ::Users::Internal.support_bot }

    where(:support_bot?, :visibility_level, :confidential, :new_attributes, :check_for_spam?) do
      ### non-support-bot cases
      # spammable attributes changing
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { description: 'new' } | true
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { title: 'new' } | true
      # confidential to non-confidential
      false | Gitlab::VisibilityLevel::PUBLIC   | true  | { confidential: false } | false
      # non-confidential to confidential
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { confidential: true } | false
      # spammable attributes changing on confidential
      false | Gitlab::VisibilityLevel::PUBLIC   | true  | { description: 'new' } | true
      # spammable attributes changing while changing to confidential
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { title: 'new', confidential: true } | true
      # spammable attribute not changing
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { description: 'original description' } | false
      # non-spammable attribute changing
      false | Gitlab::VisibilityLevel::PUBLIC   | false | { weight: 3 } | false
      # spammable attributes changing on non-public
      false | Gitlab::VisibilityLevel::INTERNAL | false | { description: 'new' } | true
      false | Gitlab::VisibilityLevel::PRIVATE  | false | { description: 'new' } | true

      ### support-bot cases
      # confidential to non-confidential
      true | Gitlab::VisibilityLevel::PUBLIC    | true  | { confidential: false } | false
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
        active_user = support_bot? ? support_bot : user
        project = reusable_project
        project.update!(visibility_level: visibility_level)
        issue = create(:issue, project: project, confidential: confidential, description: 'original description', author: support_bot)

        issue.assign_attributes(new_attributes)

        expect(issue.check_for_spam?(user: active_user)).to eq(check_for_spam?)
      end
    end
  end

  describe 'removing an issue' do
    it 'refreshes the number of open issues of the project' do
      project = subject.project

      expect do
        subject.destroy!

        BatchLoader::Executor.clear_current
      end.to change { project.open_issues_count }.from(1).to(0)
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

  describe '.without_hidden' do
    let_it_be(:banned_user) { create(:user, :banned) }
    let_it_be(:public_issue) { create(:issue, project: reusable_project) }
    let_it_be(:hidden_issue) { create(:issue, project: reusable_project, author: banned_user) }

    it 'only returns without_hidden issues' do
      expect(described_class.without_hidden).to eq([public_issue])
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
    let_it_be(:service_desk_issue) { create(:issue, project: reusable_project, author: ::Users::Internal.support_bot) }
    let_it_be(:regular_issue) { create(:issue, project: reusable_project) }
    let_it_be(:ticket) { create(:work_item, :ticket, project: reusable_project, author: user) }

    it 'returns the service desk issue and ticket work item' do
      expect(described_class.service_desk).to contain_exactly(service_desk_issue, described_class.find(ticket.id))
      expect(described_class.service_desk).not_to include(regular_issue)
    end
  end

  it_behaves_like 'throttled touch' do
    subject { create(:issue, updated_at: 1.hour.ago) }
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
        allow(mover).to receive(:move) { raise RelativePositioning::NoSpaceLeft }
      end
    end

    shared_examples 'schedules issues rebalancing' do
      let(:issue) { build_stubbed(:issue, relative_position: 100, project: project) }

      it 'schedules rebalancing if there is no space left' do
        lhs = build_stubbed(:issue, relative_position: 99, project: project)
        to_move = build(:issue, project: project)
        expect(Issues::RebalancingWorker).to receive(:perform_async).with(nil, project_id, namespace_id)

        expect { to_move.move_between(lhs, issue) }.to raise_error(RelativePositioning::NoSpaceLeft)
      end
    end

    context 'when project in user namespace' do
      let(:project_namespace) { build_stubbed(:project_namespace) }
      let(:project) { build_stubbed(:project_empty_repo, project_namespace: project_namespace) }
      let(:project_id) { project.id }
      let(:namespace_id) { nil }

      it_behaves_like 'schedules issues rebalancing'
    end

    context 'when project in a group namespace' do
      let(:group) { create(:group) }
      let(:project_namespace) { build_stubbed(:project_namespace) }
      let(:project) { build_stubbed(:project_empty_repo, group: group, project_namespace: project_namespace) }
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

  describe '#issue_type' do
    let_it_be(:issue) { create(:issue) }

    it 'gets the type field from the work_item_types table' do
      expect(issue).to receive_message_chain(:work_item_type, :base_type)

      issue.issue_type
    end

    context 'when the issue is not persisted' do
      it 'uses the default work item type' do
        non_persisted_issue = build(:issue, work_item_type: nil)

        expect(non_persisted_issue.issue_type).to eq(described_class::DEFAULT_ISSUE_TYPE.to_s)
      end
    end
  end

  describe '#issue_type_supports?' do
    let_it_be(:issue) { create(:issue) }

    it 'raises error when feature is invalid' do
      expect { issue.issue_type_supports?(:unkown_feature) }.to raise_error(ArgumentError)
    end
  end

  describe '#supports_assignee?' do
    Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter::WIDGETS_FOR_TYPE.each_pair do |base_type, widgets|
      specify do
        issue = build(:issue, base_type)
        supports_assignee = widgets.include?(:assignees)

        expect(issue.supports_assignee?).to eq(supports_assignee)
      end
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
        issue.update!(work_item_type: WorkItems::Type.default_by_type(issue_type))
      end

      specify do
        expect(issue.supports_time_tracking?).to eq(supports_time_tracking)
      end
    end
  end

  describe '#time_estimate' do
    let_it_be(:project) { create(:project) }
    let_it_be(:issue) { create(:issue, project: project) }

    context 'when time estimate on the issue record is NULL' do
      before do
        issue.update_column(:time_estimate, nil)
      end

      it 'sets time estimate to zeor on save' do
        expect(issue.read_attribute(:time_estimate)).to be_nil

        issue.save!

        expect(issue.reload.read_attribute(:time_estimate)).to eq(0)
      end
    end
  end

  describe '#supports_move_and_clone?' do
    let_it_be(:project) { create(:project) }
    let_it_be_with_refind(:issue) { create(:incident, project: project) }

    where(:issue_type, :supports_move_and_clone) do
      :issue | true
      :incident | true
    end

    with_them do
      before do
        issue.update!(work_item_type: WorkItems::Type.default_by_type(issue_type))
      end

      specify do
        expect(issue.supports_move_and_clone?).to eq(supports_move_and_clone)
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

  describe '#escalation_status' do
    it 'returns the incident_management_issuable_escalation_status association' do
      escalation_status = create(:incident_management_issuable_escalation_status)
      issue = escalation_status.issue

      expect(issue.escalation_status).to eq(escalation_status)
    end
  end

  describe '#expire_etag_cache' do
    let_it_be(:issue) { create(:issue) }

    subject(:expire_cache) { issue.expire_etag_cache }

    it 'touches the etag cache store' do
      key = Gitlab::Routing.url_helpers.realtime_changes_project_issue_path(issue.project, issue)

      expect_next_instance_of(Gitlab::EtagCaching::Store) do |cache_store|
        expect(cache_store).to receive(:touch).with(key)
      end

      expire_cache
    end
  end

  describe '#link_reference_pattern' do
    let(:match_data) { described_class.link_reference_pattern.match(link_reference_url) }

    context 'with issue url' do
      let(:link_reference_url) { 'http://localhost/namespace/project/-/issues/1' }

      it 'matches with expected attributes' do
        expect(match_data['namespace']).to eq('namespace')
        expect(match_data['project']).to eq('project')
        expect(match_data['issue']).to eq('1')
      end
    end

    context 'with incident url' do
      let(:link_reference_url) { 'http://localhost/namespace1/project1/-/issues/incident/2' }

      it 'matches with expected attributes' do
        expect(match_data['namespace']).to eq('namespace1')
        expect(match_data['project']).to eq('project1')
        expect(match_data['issue']).to eq('2')
      end
    end
  end

  context 'order by closed_at' do
    let!(:issue_a) { create(:issue, closed_at: 1.day.ago) }
    let!(:issue_b) { create(:issue, closed_at: 5.days.ago) }
    let!(:issue_c_nil) { create(:issue, closed_at: nil) }
    let!(:issue_d) { create(:issue, closed_at: 3.days.ago) }
    let!(:issue_e_nil) { create(:issue, closed_at: nil) }

    describe '.order_closed_at_asc' do
      it 'orders on closed at' do
        expect(described_class.order_closed_at_asc.to_a).to eq([issue_b, issue_d, issue_a, issue_c_nil, issue_e_nil])
      end
    end

    describe '.order_closed_at_desc' do
      it 'orders on closed at' do
        expect(described_class.order_closed_at_desc.to_a).to eq([issue_a, issue_d, issue_b, issue_c_nil, issue_e_nil])
      end
    end
  end

  describe '#full_search' do
    context 'when searching non-english terms' do
      [
        'abc 中文語',
        '中文語cn',
        '中文語',
        'Привет'
      ].each do |term|
        it 'adds extra where clause to match partial index' do
          expect(described_class.full_search(term).to_sql).to include(
            "AND (issues.title NOT SIMILAR TO '[\\u0000-\\u02FF\\u1E00-\\u1EFF\\u2070-\\u218F]*' " \
            "OR issues.description NOT SIMILAR TO '[\\u0000-\\u02FF\\u1E00-\\u1EFF\\u2070-\\u218F]*')"
          )
        end
      end
    end
  end

  describe '#work_item_type_with_default' do
    subject { described_class.new.work_item_type_with_default }

    it { is_expected.to eq(WorkItems::Type.default_by_type(::Issue::DEFAULT_ISSUE_TYPE)) }
  end

  describe '#update_search_data!' do
    it 'copies namespace_id to search data' do
      issue = create(:issue)

      expect(issue.search_data.namespace_id).to eq(issue.namespace_id)
    end
  end

  describe '#linked_items_count' do
    let_it_be(:issue1) { create(:issue, project: reusable_project) }
    let_it_be(:issue2) { create(:issue, project: reusable_project) }
    let_it_be(:issue3) { create(:issue, project: reusable_project) }
    let_it_be(:issue4) { build(:issue, project: reusable_project) }

    it 'returns number of issues linked to the issue' do
      create(:issue_link, source: issue1, target: issue2)
      create(:issue_link, source: issue1, target: issue3)

      expect(issue1.linked_items_count).to eq(2)
      expect(issue2.linked_items_count).to eq(1)
      expect(issue3.linked_items_count).to eq(1)
      expect(issue4.linked_items_count).to eq(0)
    end
  end

  describe '#readable_by?' do
    let_it_be(:admin_user) { create(:user, :admin) }

    subject { issue_subject.readable_by?(user) }

    context 'when issue belongs directly to a project' do
      let_it_be_with_reload(:project_issue) { create(:issue, project: reusable_project) }
      let_it_be(:project_reporter) { create(:user, reporter_of: reusable_project) }
      let_it_be(:project_guest) { create(:user, guest_of: reusable_project) }

      let(:issue_subject) { project_issue }

      context 'when user is in admin mode', :enable_admin_mode do
        let(:user) { admin_user }

        it { is_expected.to be_truthy }
      end

      context 'when user is a reporter' do
        let(:user) { project_reporter }

        it { is_expected.to be_truthy }

        context 'when issues project feature is not enabled' do
          before do
            reusable_project.project_feature.update!(issues_access_level: ProjectFeature::DISABLED)
          end

          it { is_expected.to be_falsey }
        end

        context 'when issue is hidden (banned author)' do
          before do
            issue_subject.author.ban!
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'when user is a guest' do
        let(:user) { project_guest }

        context 'when issue is confidential' do
          before do
            issue_subject.update!(confidential: true)
          end

          it { is_expected.to be_falsey }

          context 'when user is assignee of the issue' do
            before do
              issue_subject.update!(assignees: [user])
            end

            it { is_expected.to be_truthy }
          end
        end
      end
    end

    context 'when issue belongs directly to the group' do
      let_it_be(:group) { create(:group) }
      let_it_be_with_reload(:group_issue) { create(:issue, :group_level, namespace: group) }
      let_it_be(:group_reporter) { create(:user, reporter_of: group) }
      let_it_be(:group_guest) { create(:user, guest_of: group) }

      let(:issue_subject) { group_issue }

      context 'when user is in admin mode', :enable_admin_mode do
        let(:user) { admin_user }

        it { is_expected.to be_truthy }
      end

      context 'when user is a reporter' do
        let(:user) { group_reporter }

        it { is_expected.to be_truthy }

        context 'when issue is hidden (banned author)' do
          before do
            issue_subject.author.ban!
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'when user is a guest' do
        let(:user) { group_guest }

        it { is_expected.to be_truthy }

        context 'when issue is confidential' do
          before do
            issue_subject.update!(confidential: true)
          end

          it { is_expected.to be_falsey }

          context 'when user is assignee of the issue' do
            before do
              issue_subject.update!(assignees: [user])
            end

            it { is_expected.to be_truthy }
          end
        end
      end
    end
  end

  describe '#gfm_reference' do
    where(:issue_type, :expected_name) do
      :issue     | 'issue'
      :incident  | 'incident'
      :test_case | 'test case'
      :task      | 'task'
    end

    with_them do
      it 'uses the issue type as the reference name' do
        issue = create(:issue, issue_type, project: reusable_project)

        expect(issue.gfm_reference).to eq("#{expected_name} #{issue.to_reference}")
      end
    end
  end

  describe '#has_widget?' do
    let_it_be(:work_item_type) { create(:work_item_type, :non_default) }
    let_it_be_with_reload(:issue) { create(:issue, project: reusable_project, work_item_type: work_item_type) }

    # Setting a fixed widget here so we don't get a licensed widget from the list as that could break the specs.
    # Using const_get in the implementation will make sure the widget exists in CE (no licenses)
    let(:widget_type) { :assignees }

    subject { issue.has_widget?(widget_type) }

    context 'when the work item does not have the widget' do
      it { is_expected.to be_falsey }
    end

    context 'when the work item has the widget' do
      before do
        create(
          :widget_definition,
          widget_type: widget_type,
          work_item_type: work_item_type
        )
      end

      it { is_expected.to be_truthy }
    end
  end

  shared_examples 'a markdown field that parses work item references' do
    shared_examples 'a html field with work item information' do
      it 'parses the work item reference' do
        html_link = Nokogiri::HTML.fragment(issue[:"#{field}_html"]).css('a').first

        expect(html_link.text).to eq(expected_link_text)
        expect(html_link[:href]).to eq(work_item_path)
      end
    end

    let_it_be(:group) { create(:group) }

    context 'when it is a group level issue', :aggregate_failures do
      let(:issue) { create(:issue, :group_level, namespace: group, field => work_item_reference) }
      let(:work_item_path) { Gitlab::UrlBuilder.build(group_work_item, only_path: true) }
      let(:expected_link_text) { group_work_item.to_reference }

      context 'when field contains a work item reference (URL)' do
        let(:work_item_path) { Gitlab::UrlBuilder.build(group_work_item) }
        let(:work_item_reference) { work_item_path }

        it_behaves_like 'a html field with work item information'
      end

      context 'when field contains a work item reference (short)' do
        let(:work_item_reference) { group_work_item.to_reference }

        it_behaves_like 'a html field with work item information'
      end

      context 'when field contains a work item reference (full)' do
        let(:work_item_reference) { group_work_item.to_reference(full: true) }

        it_behaves_like 'a html field with work item information'
      end

      context 'when field contains a project level work item reference (URL)' do
        let(:work_item_path) { Gitlab::UrlBuilder.build(project_work_item) }
        let(:work_item_reference) { work_item_path }
        let(:expected_link_text) { "#{reusable_project.full_path}##{project_work_item.iid}" }

        it_behaves_like 'a html field with work item information'
      end
    end

    context 'when it is a project level issue', :aggregate_failures do
      let(:issue) { create(:issue, :task, project: reusable_project, field => work_item_reference) }
      let(:work_item_path) { Gitlab::UrlBuilder.build(project_work_item, only_path: true) }
      let(:expected_link_text) { group_work_item.to_reference }

      context 'when field contains a work item reference (URL)' do
        let(:work_item_path) { Gitlab::UrlBuilder.build(project_work_item) }
        let(:work_item_reference) { work_item_path }
        let(:expected_link_text) { project_work_item.to_reference }

        it_behaves_like 'a html field with work item information'
      end

      context 'when field contains a work item reference (short)' do
        let(:work_item_reference) { project_work_item.to_reference }

        it_behaves_like 'a html field with work item information'
      end

      context 'when field contains a work item reference (full)' do
        let(:work_item_reference) { project_work_item.to_reference(full: true) }

        it_behaves_like 'a html field with work item information'
      end

      context 'when field contains a group level work item reference (URL)' do
        let(:work_item_path) { Gitlab::UrlBuilder.build(group_work_item) }
        let(:work_item_reference) { work_item_path }
        let(:expected_link_text) { "#{group.full_path}##{group_work_item.iid}" }

        it_behaves_like 'a html field with work item information'
      end
    end
  end

  describe '#title_html' do
    it_behaves_like 'a markdown field that parses work item references' do
      let_it_be(:group_work_item) { create(:work_item, :group_level, namespace: group) }
      let_it_be(:project_work_item) { create(:work_item, :task, project: reusable_project) }
      let(:field) { :title }
    end
  end

  describe '#description_html' do
    it_behaves_like 'a markdown field that parses work item references' do
      let_it_be(:group_work_item) { create(:work_item, :group_level, namespace: group) }
      let_it_be(:project_work_item) { create(:work_item, :task, project: reusable_project) }
      let(:field) { :description }
    end
  end

  describe '#work_item_type' do
    let_it_be_with_reload(:issue) { create(:issue, project: reusable_project) }

    it 'uses the correct_work_item_type_id column to fetch the associated type' do
      expect do
        issue.work_item_type
      end.to make_queries_matching(/FROM "work_item_types" WHERE "work_item_types"\."correct_id" =/)
    end
  end

  describe '#work_item_type_id' do
    let_it_be(:work_item_type1) { create(:work_item_type, :non_default) }
    let_it_be(:work_item_type2) { create(:work_item_type, :non_default) }
    let_it_be(:issue) { create(:issue, project: reusable_project) }

    it 'returns the correct work_item_types.id value even if the value in the column is wrong' do
      issue.update_columns(
        work_item_type_id: work_item_type2.id,
        correct_work_item_type_id: work_item_type1.correct_id
      )

      expect(issue.work_item_type_id).to eq(work_item_type1.id)
    end
  end

  describe '#work_item_type_id=', :aggregate_failures do
    let_it_be(:type1) do
      create(:work_item_type, :non_default).tap do |type|
        type.update!(old_id: type.id, id: -type.id, correct_id: type.id * 1000)
      end
    end

    it 'assigns correct values if a correct_id is passed' do
      issue = build(:issue, project: reusable_project, work_item_type: nil)

      expect(issue.work_item_type_id).to be_nil
      expect(issue.correct_work_item_type_id).to be_nil

      issue.work_item_type_id = type1.correct_id

      expect(issue.work_item_type_id).to eq(type1.id)
      expect(issue.correct_work_item_type_id).to eq(type1.correct_id)
    end

    it 'fallbacks to work_item_types.old_id if passed' do
      issue = build(:issue, project: reusable_project, work_item_type: nil)

      expect(issue.work_item_type_id).to be_nil
      expect(issue.correct_work_item_type_id).to be_nil

      issue.work_item_type_id = type1.old_id

      expect(issue.work_item_type_id).to eq(type1.id)
      expect(issue.correct_work_item_type_id).to eq(type1.correct_id)
    end

    it 'does not assign default type when only setting the correct_work_item_type_id column' do
      issue = build(:issue, project: reusable_project, work_item_type: nil)

      expect(issue.work_item_type_id).to be_nil
      expect(issue.correct_work_item_type_id).to be_nil

      issue.work_item_type_id = type1.correct_id
      issue.save!
      issue.reload

      expect(issue.work_item_type_id).to eq(type1.id)
      expect(issue.correct_work_item_type_id).to eq(type1.correct_id)
    end

    context 'when work_item_type_id does not exist in the DB' do
      it 'does not set type id values' do
        issue = build(:issue, project: reusable_project, work_item_type: nil)

        expect(issue.work_item_type_id).to be_nil
        expect(issue.correct_work_item_type_id).to be_nil

        issue.work_item_type_id = non_existing_record_id

        expect(issue.work_item_type_id).to be_nil
        expect(issue.correct_work_item_type_id).to be_nil
      end
    end
  end

  describe '#work_item_type=' do
    it 'also sets correct_work_item_type', :aggregate_failures do
      issue = build(:issue, project: reusable_project, work_item_type: nil)
      work_item_type = create(:work_item_type, :non_default)

      expect(issue.work_item_type).to be_nil
      expect(issue.correct_work_item_type).to be_nil

      issue.work_item_type = work_item_type

      expect(issue.work_item_type).to eq(work_item_type)
      expect(issue.correct_work_item_type).to eq(work_item_type)
    end
  end
end
