# frozen_string_literal: true

require 'spec_helper'

describe Milestone do
  it_behaves_like 'a timebox', :milestone

  describe 'MilestoneStruct#serializable_hash' do
    let(:predefined_milestone) { described_class::MilestoneStruct.new('Test Milestone', '#test', 1) }

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

    describe 'milestone_releases' do
      let(:milestone) { build(:milestone, project: project) }

      context 'when it is tied to a release for another project' do
        it 'creates a validation error' do
          other_project = create(:project)
          milestone.releases << build(:release, project: other_project)
          expect(milestone).not_to be_valid
        end
      end

      context 'when it is tied to a release for the same project' do
        it 'is valid' do
          milestone.releases << build(:release, project: project)
          expect(milestone).to be_valid
        end
      end
    end
  end

  describe "Associations" do
    it { is_expected.to have_many(:releases) }
    it { is_expected.to have_many(:milestone_releases) }
  end

  let(:project) { create(:project, :public) }
  let(:milestone) { create(:milestone, project: project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  describe '.predefined_id?' do
    it 'returns true for a predefined Milestone ID' do
      expect(Milestone.predefined_id?(described_class::Upcoming.id)).to be true
    end

    it 'returns false for a Milestone ID that is not predefined' do
      expect(Milestone.predefined_id?(milestone.id)).to be false
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
    let_it_be(:now) { Time.now }
    let_it_be(:project) { create(:project, :empty_repo) }
    let_it_be(:resource_1) { create(:milestone, project: project, start_date: now - 1.day, due_date: now + 1.day) }
    let_it_be(:resource_2) { create(:milestone, project: project, start_date: now + 2.days, due_date: now + 3.days) }
    let_it_be(:resource_3) { create(:milestone, project: project, due_date: now) }
    let_it_be(:resource_4) { create(:milestone, project: project, start_date: now) }
  end

  describe "#percent_complete" do
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

  describe '#expired?' do
    context "expired" do
      before do
        allow(milestone).to receive(:due_date).and_return(Date.today.prev_year)
      end

      it 'returns true when due_date is in the past' do
        expect(milestone.expired?).to be_truthy
      end
    end

    context "not expired" do
      before do
        allow(milestone).to receive(:due_date).and_return(Date.today.next_year)
      end

      it 'returns false when due_date is in the future' do
        expect(milestone.expired?).to be_falsey
      end
    end
  end

  describe '#upcoming?' do
    it 'returns true when start_date is in the future' do
      milestone = build(:milestone, start_date: Time.now + 1.month)
      expect(milestone.upcoming?).to be_truthy
    end

    it 'returns false when start_date is in the past' do
      milestone = build(:milestone, start_date: Date.today.prev_year)
      expect(milestone.upcoming?).to be_falsey
    end
  end

  describe '#can_be_closed?' do
    it { expect(milestone.can_be_closed?).to be_truthy }
  end

  describe '#can_be_closed?' do
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
      issue.save

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
      expect(described_class.search_title(milestone.title)) .to eq([milestone])
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

      expect(described_class.search_title(milestone.title)) .to eq([milestone])
    end
  end

  describe '#for_projects_and_groups' do
    let(:project) { create(:project) }
    let(:project_other) { create(:project) }
    let(:group) { create(:group) }
    let(:group_other) { create(:group) }

    before do
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

  describe '.upcoming_ids' do
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:group_3) { create(:group) }
    let(:groups) { [group_1, group_2, group_3] }

    let!(:past_milestone_group_1) { create(:milestone, group: group_1, due_date: Time.now - 1.day) }
    let!(:current_milestone_group_1) { create(:milestone, group: group_1, due_date: Time.now + 1.day) }
    let!(:future_milestone_group_1) { create(:milestone, group: group_1, due_date: Time.now + 2.days) }

    let!(:past_milestone_group_2) { create(:milestone, group: group_2, due_date: Time.now - 1.day) }
    let!(:closed_milestone_group_2) { create(:milestone, :closed, group: group_2, due_date: Time.now + 1.day) }
    let!(:current_milestone_group_2) { create(:milestone, group: group_2, due_date: Time.now + 2.days) }

    let!(:past_milestone_group_3) { create(:milestone, group: group_3, due_date: Time.now - 1.day) }

    let(:project_1) { create(:project) }
    let(:project_2) { create(:project) }
    let(:project_3) { create(:project) }
    let(:projects) { [project_1, project_2, project_3] }

    let!(:past_milestone_project_1) { create(:milestone, project: project_1, due_date: Time.now - 1.day) }
    let!(:current_milestone_project_1) { create(:milestone, project: project_1, due_date: Time.now + 1.day) }
    let!(:future_milestone_project_1) { create(:milestone, project: project_1, due_date: Time.now + 2.days) }

    let!(:past_milestone_project_2) { create(:milestone, project: project_2, due_date: Time.now - 1.day) }
    let!(:closed_milestone_project_2) { create(:milestone, :closed, project: project_2, due_date: Time.now + 1.day) }
    let!(:current_milestone_project_2) { create(:milestone, project: project_2, due_date: Time.now + 2.days) }

    let!(:past_milestone_project_3) { create(:milestone, project: project_3, due_date: Time.now - 1.day) }

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
    let(:project) { build_stubbed(:project, name: 'sample-project') }
    let(:another_project) { build_stubbed(:project, name: 'another-project', namespace: project.namespace) }

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
        expect(milestone.to_reference(another_project, format: :name)).to eq '%"milestone"'
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
end
