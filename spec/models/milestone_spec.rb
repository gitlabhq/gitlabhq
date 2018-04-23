require 'spec_helper'

describe Milestone do
  describe 'modules' do
    context 'with a project' do
      it_behaves_like 'AtomicInternalId' do
        let(:internal_id_attribute) { :iid }
        let(:instance) { build(:milestone, project: build(:project), group: nil) }
        let(:scope_attrs) { { project: instance.project } }
        let(:usage) { :milestones }
      end
    end

    context 'with a group' do
      it_behaves_like 'AtomicInternalId' do
        let(:internal_id_attribute) { :iid }
        let(:instance) { build(:milestone, project: nil, group: build(:group)) }
        let(:scope_attrs) { { namespace: instance.group } }
        let(:usage) { :milestones }
      end
    end
  end

  describe "Validation" do
    before do
      allow(subject).to receive(:set_iid).and_return(false)
    end

    describe 'start_date' do
      it 'adds an error when start_date is greated then due_date' do
        milestone = build(:milestone, start_date: Date.tomorrow, due_date: Date.yesterday)

        expect(milestone).not_to be_valid
        expect(milestone.errors[:due_date]).to include("must be greater than start date")
      end
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:issues) }
  end

  let(:project) { create(:project, :public) }
  let(:milestone) { create(:milestone, project: project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  describe "#title" do
    let(:milestone) { create(:milestone, title: "<b>foo & bar -> 2.2</b>") }

    it "sanitizes title" do
      expect(milestone.title).to eq("foo & bar -> 2.2")
    end
  end

  describe "unique milestone title" do
    context "per project" do
      it "does not accept the same title in a project twice" do
        new_milestone = described_class.new(project: milestone.project, title: milestone.title)
        expect(new_milestone).not_to be_valid
      end

      it "accepts the same title in another project" do
        project = create(:project)
        new_milestone = described_class.new(project: project, title: milestone.title)

        expect(new_milestone).to be_valid
      end
    end

    context "per group" do
      let(:group) { create(:group) }
      let(:milestone) { create(:milestone, group: group) }

      before do
        project.update(group: group)
      end

      it "does not accept the same title in a group twice" do
        new_milestone = described_class.new(group: group, title: milestone.title)

        expect(new_milestone).not_to be_valid
      end

      it "does not accept the same title of a child project milestone" do
        create(:milestone, project: group.projects.first)

        new_milestone = described_class.new(group: group, title: milestone.title)

        expect(new_milestone).not_to be_valid
      end
    end
  end

  describe "#percent_complete" do
    it "does not count open issues" do
      milestone.issues << issue
      expect(milestone.percent_complete(user)).to eq(0)
    end

    it "counts closed issues" do
      issue.close
      milestone.issues << issue
      expect(milestone.percent_complete(user)).to eq(100)
    end

    it "recovers from dividing by zero" do
      expect(milestone.percent_complete(user)).to eq(0)
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

  describe '#percent_complete' do
    before do
      allow(milestone).to receive_messages(
        closed_items_count: 3,
        total_items_count: 4
      )
    end

    it { expect(milestone.percent_complete(user)).to eq(75) }
  end

  describe '#can_be_closed?' do
    it { expect(milestone.can_be_closed?).to be_truthy }
  end

  describe '#total_items_count' do
    before do
      create :closed_issue, milestone: milestone, project: project
      create :merge_request, milestone: milestone
    end

    it 'returns total count of issues and merge requests assigned to milestone' do
      expect(milestone.total_items_count(user)).to eq 2
    end
  end

  describe '#can_be_closed?' do
    before do
      milestone = create :milestone
      create :closed_issue, milestone: milestone

      create :issue
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

  describe '.upcoming_ids_by_projects' do
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

    # The call to `#try` is because this returns a relation with a Postgres DB,
    # and an array of IDs with a MySQL DB.
    let(:milestone_ids) { described_class.upcoming_ids_by_projects(projects).map { |id| id.try(:id) || id } }

    it 'returns the next upcoming open milestone ID for each project' do
      expect(milestone_ids).to contain_exactly(current_milestone_project_1.id, current_milestone_project_2.id)
    end

    context 'when the projects have no open upcoming milestones' do
      let(:projects) { [project_3] }

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
end
