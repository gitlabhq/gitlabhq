# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestone, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:group) { create(:group) }
  let_it_be(:issue) { create(:issue, project: project) }

  describe 'modules' do
    context 'with a project' do
      it_behaves_like 'AtomicInternalId' do
        let(:internal_id_attribute) { :iid }
        let(:instance) { build(:milestone, project: create(:project), group: nil) }
        let(:scope) { :project }
        let(:scope_attrs) { { project: instance.project } }
        let(:usage) { :milestones }
      end
    end

    context 'with a group' do
      it_behaves_like 'AtomicInternalId' do
        let(:internal_id_attribute) { :iid }
        let(:instance) { build(:milestone, project: nil, group: create(:group)) }
        let(:scope) { :group }
        let(:scope_attrs) { { namespace: instance.group } }
        let(:usage) { :milestones }
      end
    end
  end

  it_behaves_like 'a timebox', :milestone do
    let(:project) { create(:project, :public) }
    let(:timebox) { create(:milestone, project: project) }
  end

  describe "#uniqueness_of_title" do
    let_it_be(:root_group) { create(:group) }
    let_it_be(:sub_group) { create(:group, parent: root_group) }
    let_it_be(:sub_sub_group) { create(:group, parent: sub_group) }
    let_it_be(:sub_sub_project) { create(:project, group: sub_sub_group) }
    let_it_be(:sub_sub_group_milestone) { create(:milestone, group: sub_sub_group) }
    let_it_be(:sub_sub_project_milestone) { create(:milestone, project: sub_sub_project) }

    context "per project" do
      it "does not accept the same title in a project twice" do
        milestone = described_class.new(project: sub_sub_project, title: sub_sub_project_milestone.title)

        expect(milestone).not_to be_valid
      end

      it "accepts the same title in another project" do
        project = create(:project, group: sub_sub_group)
        milestone = described_class.new(project: project, title: sub_sub_project_milestone.title)

        expect(milestone).to be_valid
      end
    end

    context "per group" do
      it "does not accept the same title in a group twice" do
        milestone = described_class.new(group: sub_sub_group, title: sub_sub_group_milestone.title)

        expect(milestone).not_to be_valid
      end

      it "does not accept the same title of a child project timebox" do
        milestone = described_class.new(group: sub_sub_group, title: sub_sub_project_milestone.title)

        expect(milestone).not_to be_valid
      end

      it "does not accept the same title in a descendant group" do
        new_timebox = described_class.new(group: root_group, title: sub_sub_group_milestone.title)

        expect(new_timebox).not_to be_valid
      end

      it "does not accept the same title in a descendant project" do
        new_timebox = described_class.new(group: root_group, title: sub_sub_project_milestone.title)

        expect(new_timebox).not_to be_valid
      end
    end
  end

  describe 'MilestoneStruct#serializable_hash' do
    let(:predefined_milestone) { described_class::TimeboxStruct.new('Test Milestone', '#test', 1) }

    it 'presents the predefined milestone as a hash' do
      expect(predefined_milestone.serializable_hash).to eq(
        title: predefined_milestone.title,
        name: predefined_milestone.name,
        id: predefined_milestone.id
      )
    end
  end

  describe "Validation" do
    before do
      allow(subject).to receive(:set_iid).and_return(false)
    end

    describe 'title' do
      it { is_expected.to validate_presence_of(:title) }

      it 'is invalid if title would be empty after sanitation', :aggregate_failures do
        milestone = build(:milestone, project: project, title: '<img src=x onerror=prompt(1)>')

        expect(milestone).not_to be_valid
        expect(milestone.errors[:title]).to include("can't be blank")
      end
    end

    describe 'milestone_releases' do
      let(:milestone) { build(:milestone, project: project) }

      context 'when it is tied to a release for another project' do
        it 'creates a validation error' do
          other_project = create(:project)
          milestone.releases << build(:release,
            project: other_project, author_id: other_project.members.first.user_id)
          expect(milestone).not_to be_valid
        end
      end

      context 'when it is tied to a release for the same project' do
        it 'is valid' do
          milestone.releases << build(:release,
            project: project, author_id: project.members.first.user_id)
          expect(milestone).to be_valid
        end
      end
    end

    describe '#parent_type_check' do
      let(:milestone) { build(:milestone, group: group) }

      it 'is invalid if it has both project_id and group_id' do
        milestone.project = project

        expect(milestone).not_to be_valid
        expect(milestone.errors[:project_id]).to include("milestone should belong either to a project or a group.")
      end
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:releases) }
    it { is_expected.to have_many(:milestone_releases) }
  end

  describe '.predefined_id?' do
    let_it_be(:milestone) { create(:milestone, project: project) }

    it 'returns true for a predefined Milestone ID' do
      expect(described_class.predefined_id?(described_class::Upcoming.id)).to be true
    end

    it 'returns false for a Milestone ID that is not predefined' do
      expect(described_class.predefined_id?(milestone.id)).to be false
    end
  end

  describe '.order_by_name_asc' do
    it 'sorts by name ascending' do
      milestone1 = create(:milestone, title: 'Foo')
      milestone2 = create(:milestone, title: 'Bar')

      expect(described_class.order_by_name_asc).to eq([milestone2, milestone1])
    end
  end

  describe '.reorder_by_due_date_asc' do
    it 'reorders the input relation' do
      milestone1 = create(:milestone, due_date: Date.new(2018, 9, 30))
      milestone2 = create(:milestone, due_date: Date.new(2018, 10, 20))

      expect(described_class.reorder_by_due_date_asc).to eq([milestone1, milestone2])
    end
  end

  it_behaves_like 'within_timeframe scope' do
    let_it_be(:now) { Time.current }
    let_it_be(:project) { create(:project, :empty_repo) }
    let_it_be(:resource_1) { create(:milestone, project: project, start_date: now - 1.day, due_date: now + 1.day) }
    let_it_be(:resource_2) { create(:milestone, project: project, start_date: now + 2.days, due_date: now + 3.days) }
    let_it_be(:resource_3) { create(:milestone, project: project, due_date: now) }
    let_it_be(:resource_4) { create(:milestone, project: project, start_date: now) }
  end

  describe "#percent_complete" do
    let(:milestone) { create(:milestone, project: project) }

    it "does not count open issues" do
      milestone.issues << issue
      expect(milestone.percent_complete).to eq(0)
    end

    it "counts closed issues" do
      issue.close
      milestone.issues << issue
      expect(milestone.percent_complete).to eq(100)
    end

    it "recovers from dividing by zero" do
      expect(milestone.percent_complete).to eq(0)
    end
  end

  describe '#expired? and #expired' do
    context "expired" do
      let(:milestone) { build(:milestone, project: project, due_date: Date.today.prev_year) }

      it 'returns true when due_date is in the past', :aggregate_failures do
        expect(milestone.expired?).to be_truthy
        expect(milestone.expired).to eq true
      end
    end

    context "not expired" do
      let(:milestone) { build(:milestone, project: project, due_date: Date.today.next_year) }

      it 'returns false when due_date is in the future', :aggregate_failures do
        expect(milestone.expired?).to be_falsey
        expect(milestone.expired).to eq false
      end
    end
  end

  describe '#upcoming?' do
    it 'returns true when start_date is in the future' do
      milestone = build(:milestone, start_date: Time.current + 1.month)
      expect(milestone.upcoming?).to be_truthy
    end

    it 'returns false when start_date is in the past' do
      milestone = build(:milestone, start_date: Date.today.prev_year)
      expect(milestone.upcoming?).to be_falsey
    end
  end

  describe '#can_be_closed?' do
    let_it_be(:milestone) { build(:milestone, project: project) }

    before do
      milestone = create :milestone, project: project
      create :closed_issue, milestone: milestone, project: project

      create :issue, project: project
    end

    it 'returns true if milestone active and all nested issues closed' do
      expect(milestone.can_be_closed?).to be_truthy
    end

    it 'returns false if milestone active and not all nested issues closed' do
      issue.milestone = milestone
      issue.save!

      expect(milestone.can_be_closed?).to be_falsey
    end
  end

  describe '#to_ability_name' do
    it 'returns milestone' do
      milestone = build(:milestone)

      expect(milestone.to_ability_name).to eq('milestone')
    end
  end

  describe '.search' do
    let(:milestone) { create(:milestone, title: 'foo', description: 'bar') }

    it 'returns milestones with a matching title' do
      expect(described_class.search(milestone.title)).to eq([milestone])
    end

    it 'returns milestones with a partially matching title' do
      expect(described_class.search(milestone.title[0..2])).to eq([milestone])
    end

    it 'returns milestones with a matching title regardless of the casing' do
      expect(described_class.search(milestone.title.upcase)).to eq([milestone])
    end

    it 'returns milestones with a matching description' do
      expect(described_class.search(milestone.description)).to eq([milestone])
    end

    it 'returns milestones with a partially matching description' do
      expect(described_class.search(milestone.description[0..2]))
        .to eq([milestone])
    end

    it 'returns milestones with a matching description regardless of the casing' do
      expect(described_class.search(milestone.description.upcase))
        .to eq([milestone])
    end
  end

  describe '#search_title' do
    let(:milestone) { create(:milestone, title: 'foo', description: 'bar') }

    it 'returns milestones with a matching title' do
      expect(described_class.search_title(milestone.title)).to eq([milestone])
    end

    it 'returns milestones with a partially matching title' do
      expect(described_class.search_title(milestone.title[0..2])).to eq([milestone])
    end

    it 'returns milestones with a matching title regardless of the casing' do
      expect(described_class.search_title(milestone.title.upcase))
        .to eq([milestone])
    end

    it 'searches only on the title and ignores milestones with a matching description' do
      create(:milestone, title: 'bar', description: 'foo')

      expect(described_class.search_title(milestone.title)).to eq([milestone])
    end
  end

  shared_examples '#for_projects_and_groups' do
    describe '#for_projects_and_groups' do
      let_it_be(:project) { create(:project) }
      let_it_be(:project_other) { create(:project) }
      let_it_be(:group) { create(:group) }
      let_it_be(:group_other) { create(:group) }

      before_all do
        create(:milestone, project: project)
        create(:milestone, project: project_other)
        create(:milestone, group: group)
        create(:milestone, group: group_other)
      end

      subject { described_class.for_projects_and_groups(projects, groups) }

      shared_examples 'filters by projects and groups' do
        it 'returns milestones filtered by project' do
          milestones = described_class.for_projects_and_groups(projects, [])

          expect(milestones.count).to eq(1)
          expect(milestones.first.project_id).to eq(project.id)
        end

        it 'returns milestones filtered by group' do
          milestones = described_class.for_projects_and_groups([], groups)

          expect(milestones.count).to eq(1)
          expect(milestones.first.group_id).to eq(group.id)
        end

        it 'returns milestones filtered by both project and group' do
          milestones = described_class.for_projects_and_groups(projects, groups)

          expect(milestones.count).to eq(2)
          expect(milestones).to contain_exactly(project.milestones.first, group.milestones.first)
        end
      end

      context 'ids as params' do
        let(:projects) { [project.id] }
        let(:groups) { [group.id] }

        it_behaves_like 'filters by projects and groups'
      end

      context 'relations as params' do
        let(:projects) { Project.where(id: project.id).select(:id) }
        let(:groups) { Group.where(id: group.id).select(:id) }

        it_behaves_like 'filters by projects and groups'
      end

      context 'objects as params' do
        let(:projects) { [project] }
        let(:groups) { [group] }

        it_behaves_like 'filters by projects and groups'
      end

      it 'returns no records if projects and groups are nil' do
        milestones = described_class.for_projects_and_groups(nil, nil)

        expect(milestones).to be_empty
      end
    end
  end

  it_behaves_like '#for_projects_and_groups'

  describe '.upcoming_ids' do
    let_it_be(:group_1) { create(:group) }
    let_it_be(:group_2) { create(:group) }
    let_it_be(:group_3) { create(:group) }
    let_it_be(:groups) { [group_1, group_2, group_3] }

    let!(:past_milestone_group_1) { create(:milestone, group: group_1, due_date: Time.current - 1.day) }
    let!(:current_milestone_group_1) { create(:milestone, group: group_1, due_date: Time.current + 1.day) }
    let!(:future_milestone_group_1) { create(:milestone, group: group_1, due_date: Time.current + 2.days) }

    let!(:past_milestone_group_2) { create(:milestone, group: group_2, due_date: Time.current - 1.day) }
    let!(:closed_milestone_group_2) { create(:milestone, :closed, group: group_2, due_date: Time.current + 1.day) }
    let!(:current_milestone_group_2) { create(:milestone, group: group_2, due_date: Time.current + 2.days) }

    let!(:past_milestone_group_3) { create(:milestone, group: group_3, due_date: Time.current - 1.day) }

    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_3) { create(:project) }
    let_it_be(:projects) { [project_1, project_2, project_3] }

    let!(:past_milestone_project_1) { create(:milestone, project: project_1, due_date: Time.current - 1.day) }
    let!(:current_milestone_project_1) { create(:milestone, project: project_1, due_date: Time.current + 1.day) }
    let!(:future_milestone_project_1) { create(:milestone, project: project_1, due_date: Time.current + 2.days) }

    let!(:past_milestone_project_2) { create(:milestone, project: project_2, due_date: Time.current - 1.day) }
    let!(:closed_milestone_project_2) { create(:milestone, :closed, project: project_2, due_date: Time.current + 1.day) }
    let!(:current_milestone_project_2) { create(:milestone, project: project_2, due_date: Time.current + 2.days) }

    let!(:past_milestone_project_3) { create(:milestone, project: project_3, due_date: Time.current - 1.day) }

    let(:milestone_ids) { described_class.upcoming_ids(projects, groups).map(&:id) }

    it 'returns the next upcoming open milestone ID for each project and group' do
      expect(milestone_ids).to contain_exactly(
        current_milestone_project_1.id,
        current_milestone_project_2.id,
        current_milestone_group_1.id,
        current_milestone_group_2.id
      )
    end

    context 'when the projects and groups have no open upcoming milestones' do
      let(:projects) { [project_3] }
      let(:groups) { [group_3] }

      it 'returns no results' do
        expect(milestone_ids).to be_empty
      end
    end
  end

  describe '#to_reference' do
    let(:group) { build_stubbed(:group) }
    let(:project) { build_stubbed(:project, path: 'sample-project') }
    let(:another_project) { build_stubbed(:project, path: 'another-project', namespace: project.namespace) }

    context 'for a project milestone' do
      let(:milestone) { build_stubbed(:milestone, iid: 1, project: project, name: 'milestone') }

      it 'returns a String reference to the object' do
        expect(milestone.to_reference).to eq '%"milestone"'
      end

      it 'returns a reference by name when the format is set to :name' do
        expect(milestone.to_reference(format: :name)).to eq '%"milestone"'
      end

      it 'supports a cross-project reference' do
        expect(milestone.to_reference(another_project)).to eq 'sample-project%"milestone"'
      end
    end

    context 'for a group milestone' do
      let(:milestone) { build_stubbed(:milestone, iid: 1, group: group, name: 'milestone') }

      it 'returns a group milestone reference with a default format' do
        expect(milestone.to_reference).to eq '%"milestone"'
      end

      it 'returns a reference by name when the format is set to :name' do
        expect(milestone.to_reference(format: :name)).to eq '%"milestone"'
      end

      it 'does supports cross-project references within a group' do
        expect(milestone.to_reference(another_project, format: :name)).to eq "#{group.full_path}%\"milestone\""
      end

      it 'raises an error when using iid format' do
        expect { milestone.to_reference(format: :iid) }
          .to raise_error(ArgumentError, 'Cannot refer to a group milestone by an internal id!')
      end
    end
  end

  describe '#reference_link_text' do
    let(:project) { build_stubbed(:project, name: 'sample-project') }
    let(:milestone) { build_stubbed(:milestone, iid: 1, project: project, name: 'milestone') }

    it 'returns the title with the reference prefix' do
      expect(milestone.reference_link_text).to eq '%milestone'
    end
  end

  describe '#participants' do
    let(:project) { build(:project, name: 'sample-project') }
    let(:milestone) { build(:milestone, iid: 1, project: project) }

    it 'returns participants without duplicates' do
      user = create :user
      create :issue, project: project, milestone: milestone, assignees: [user]
      create :issue, project: project, milestone: milestone, assignees: [user]

      expect(milestone.participants).to eq [user]
    end
  end

  describe '.sort_with_expired_last' do
    let_it_be(:milestone) { create(:milestone, title: 'Due today', due_date: Date.current) }
    let_it_be(:milestone_1) { create(:milestone, title: 'Current 1',  due_date: Date.current + 1.day) }
    let_it_be(:milestone_2) { create(:milestone, title: 'Current 2',  due_date: Date.current + 2.days) }
    let_it_be(:milestone_3) { create(:milestone, title: 'Without due date') }
    let_it_be(:milestone_4) { create(:milestone, title: 'Expired 1',  due_date: Date.current - 2.days) }
    let_it_be(:milestone_5) { create(:milestone, title: 'Expired 2',  due_date: Date.current - 1.day) }
    let_it_be(:milestone_6) { create(:milestone, title: 'Without due date2') }

    context 'ordering by due_date ascending' do
      it 'sorts by due date in ascending order (ties broken by id in desc order)', :aggregate_failures do
        expect(milestone_3.id).to be < (milestone_6.id)
        expect(described_class.sort_with_expired_last(:expired_last_due_date_asc))
          .to eq([milestone, milestone_1, milestone_2, milestone_6, milestone_3, milestone_4, milestone_5])
      end
    end

    context 'ordering by due_date descending' do
      it 'sorts by due date in descending order (ties broken by id in desc order)', :aggregate_failures do
        expect(milestone_3.id).to be < (milestone_6.id)
        expect(described_class.sort_with_expired_last(:expired_last_due_date_desc))
          .to eq([milestone_2, milestone_1, milestone, milestone_6, milestone_3, milestone_5, milestone_4])
      end
    end
  end

  describe '.sort_by_attribute' do
    let_it_be(:milestone_1) { create(:milestone, title: 'Foo') }
    let_it_be(:milestone_2) { create(:milestone, title: 'Bar') }
    let_it_be(:milestone_3) { create(:milestone, title: 'Zoo') }

    context 'ordering by name ascending' do
      it 'sorts by title ascending' do
        expect(described_class.sort_by_attribute('name_asc'))
          .to eq([milestone_2, milestone_1, milestone_3])
      end
    end

    context 'ordering by name descending' do
      it 'sorts by title descending' do
        expect(described_class.sort_by_attribute('name_desc'))
          .to eq([milestone_3, milestone_1, milestone_2])
      end
    end
  end

  describe '.states_count' do
    context 'when the projects have milestones' do
      before do
        project_1 = create(:project)
        project_2 = create(:project)
        group_1 = create(:group)
        group_2 = create(:group)

        create(:active_milestone, title: 'Active Group Milestone', project: project_1)
        create(:closed_milestone, title: 'Closed Group Milestone', project: project_1)
        create(:active_milestone, title: 'Active Group Milestone', project: project_2)
        create(:closed_milestone, title: 'Closed Group Milestone', project: project_2)
        create(:closed_milestone, title: 'Active Group Milestone', group: group_1)
        create(:closed_milestone, title: 'Closed Group Milestone', group: group_1)
        create(:closed_milestone, title: 'Active Group Milestone', group: group_2)
        create(:closed_milestone, title: 'Closed Group Milestone', group: group_2)
      end

      it 'returns the quantity of milestones in each possible state' do
        expected_count = { opened: 2, closed: 6, all: 8 }

        count = described_class.states_count(Project.all, Group.all)
        expect(count).to eq(expected_count)
      end
    end

    context 'when the projects do not have milestones' do
      it 'returns 0 as the quantity of global milestones in each state' do
        expected_count = { opened: 0, closed: 0, all: 0 }

        count = described_class.states_count([project])

        expect(count).to eq(expected_count)
      end
    end
  end

  describe '.reference_pattern' do
    subject { described_class.reference_pattern }

    it { is_expected.to match('gitlab-org/gitlab-ce%123') }
    it { is_expected.to match('gitlab-org/gitlab-ce%"my-milestone"') }
  end

  describe '.link_reference_pattern' do
    subject { described_class.link_reference_pattern }

    it { is_expected.to match("#{Gitlab.config.gitlab.url}/gitlab-org/gitlab-foss/milestones/123") }
    it { is_expected.to match("#{Gitlab.config.gitlab.url}/gitlab-org/gitlab-foss/-/milestones/123") }
    it { is_expected.not_to match("#{Gitlab.config.gitlab.url}/gitlab-org/gitlab-foss/issues/123") }
    it { is_expected.not_to match("gitlab-org/gitlab-ce/milestones/123") }
  end

  describe '#merge_requests_enabled?' do
    context "per project" do
      it "is true for projects with MRs enabled" do
        project = create(:project, :merge_requests_enabled)
        milestone = build(:milestone, project: project)

        expect(milestone.merge_requests_enabled?).to be_truthy
      end

      it "is false for projects with MRs disabled" do
        project = create(:project, :repository_enabled, :merge_requests_disabled)
        milestone = build(:milestone, project: project)

        expect(milestone.merge_requests_enabled?).to be_falsey
      end

      it "is false for projects with repository disabled" do
        project = create(:project, :repository_disabled)
        milestone = build(:milestone, project: project)

        expect(milestone.merge_requests_enabled?).to be_falsey
      end
    end

    context "per group" do
      let(:milestone) { build(:milestone, group: group) }

      it "is always true for groups, for performance reasons" do
        expect(milestone.merge_requests_enabled?).to be_truthy
      end
    end
  end

  describe '#resource_parent' do
    context 'when group is present' do
      let(:milestone) { build(:milestone, group: group) }

      it 'returns the group' do
        expect(milestone.resource_parent).to eq(group)
      end
    end

    context 'when project is present' do
      let(:milestone) { build(:milestone, project: project) }

      it 'returns the project' do
        expect(milestone.resource_parent).to eq(project)
      end
    end
  end

  describe '#parent' do
    context 'with group' do
      it 'returns the expected parent' do
        group = create(:group)

        expect(build(:milestone, group: group).parent).to eq(group)
      end
    end

    context 'with project' do
      it 'returns the expected parent' do
        project = create(:project)

        expect(build(:milestone, project: project).parent).to eq(project)
      end
    end
  end

  describe '#subgroup_milestone' do
    context 'parent is subgroup' do
      it 'returns true' do
        group = create(:group)
        subgroup = create(:group, :private, parent: group)

        expect(build(:milestone, group: subgroup).subgroup_milestone?).to eq(true)
      end
    end

    context 'parent is not subgroup' do
      it 'returns false' do
        group = create(:group)

        expect(build(:milestone, group: group).subgroup_milestone?).to eq(false)
      end
    end
  end

  describe '#project_milestone?' do
    context 'when project_id is present' do
      let(:milestone) { build(:milestone, project: project) }

      it 'returns true' do
        expect(milestone.project_milestone?).to be_truthy
      end
    end

    context 'when project_id is not present' do
      let(:milestone) { build(:milestone, group: group) }

      it 'returns false' do
        expect(milestone.project_milestone?).to be_falsey
      end
    end
  end

  describe '#group_milestone?' do
    context 'when group_id is present' do
      let(:milestone) { build(:milestone, group: group) }

      it 'returns true' do
        expect(milestone.group_milestone?).to be_truthy
      end
    end

    context 'when group_id is not present' do
      let(:milestone) { build(:milestone, project: project) }

      it 'returns false' do
        expect(milestone.group_milestone?).to be_falsey
      end
    end
  end

  describe '#lock_version' do
    let_it_be(:milestone) { create(:milestone, project: project) }

    it 'ensures that lock_version and optimistic locking is enabled' do
      expect(milestone.lock_version).to be_present
    end
  end

  describe '#check_for_spam?' do
    let_it_be(:milestone) { build_stubbed(:milestone, project: project) }

    subject { milestone.check_for_spam? }

    context 'when spammable attribute title has changed' do
      before do
        milestone.title = 'New title'
      end

      it { is_expected.to eq(true) }
    end

    context 'when spammable attribute description has changed' do
      before do
        milestone.description = 'New description'
      end

      it { is_expected.to eq(true) }
    end

    context 'when spammable attribute has changed but parent is private' do
      before do
        milestone.title = 'New title'
        milestone.parent.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      it { is_expected.to eq(false) }
    end

    context 'when no spammable attribute has changed' do
      before do
        milestone.title = milestone.title_was
        milestone.description = milestone.description_was
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '.with_ids_or_title' do
    subject(:milestones) { described_class.with_ids_or_title(ids: ids, title: title) }

    let_it_be(:milestone1) { create(:milestone, title: 'Foo') }
    let_it_be(:milestone2) { create(:milestone) }

    let(:ids) { [milestone1.id] }
    let(:title) { milestone2.title }

    before do
      # Milestones below should not be returned
      create(:milestone, title: 'Bar')
      create(:milestone, id: 10)
    end

    it 'returns milestones with matching id or title' do
      expect(milestones).to contain_exactly(milestone1, milestone2)
    end
  end
end
