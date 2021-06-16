# frozen_string_literal: true

RSpec.shared_examples 'a timebox' do |timebox_type|
  let(:project) { create(:project, :public) }
  let(:group) { create(:group) }
  let(:timebox_args) { [] }
  let(:timebox) { create(timebox_type, *timebox_args, project: project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }
  let(:timebox_table_name) { timebox_type.to_s.pluralize.to_sym }

  # Values implementions can override
  let(:mid_point) { Time.now.utc.to_date }
  let(:open_on_left) { nil }
  let(:open_on_right) { nil }

  describe 'modules' do
    context 'with a project' do
      it_behaves_like 'AtomicInternalId' do
        let(:internal_id_attribute) { :iid }
        let(:instance) { build(timebox_type, *timebox_args, project: create(:project), group: nil) }
        let(:scope) { :project }
        let(:scope_attrs) { { project: instance.project } }
        let(:usage) { timebox_table_name }
      end
    end

    context 'with a group' do
      it_behaves_like 'AtomicInternalId' do
        let(:internal_id_attribute) { :iid }
        let(:instance) { build(timebox_type, *timebox_args, project: nil, group: create(:group)) }
        let(:scope) { :group }
        let(:scope_attrs) { { namespace: instance.group } }
        let(:usage) { timebox_table_name }
      end
    end
  end

  describe "Validation" do
    before do
      allow(subject).to receive(:set_iid).and_return(false)
    end

    describe 'start_date' do
      it 'adds an error when start_date is greater then due_date' do
        timebox = build(timebox_type, *timebox_args, start_date: Date.tomorrow, due_date: Date.yesterday)

        expect(timebox).not_to be_valid
        expect(timebox.errors[:due_date]).to include("must be greater than start date")
      end

      it 'adds an error when start_date is greater than 9999-12-31' do
        timebox = build(timebox_type, *timebox_args, start_date: Date.new(10000, 1, 1))

        expect(timebox).not_to be_valid
        expect(timebox.errors[:start_date]).to include("date must not be after 9999-12-31")
      end
    end

    describe 'due_date' do
      it 'adds an error when due_date is greater than 9999-12-31' do
        timebox = build(timebox_type, *timebox_args, due_date: Date.new(10000, 1, 1))

        expect(timebox).not_to be_valid
        expect(timebox.errors[:due_date]).to include("date must not be after 9999-12-31")
      end
    end

    describe 'title' do
      it { is_expected.to validate_presence_of(:title) }

      it 'is invalid if title would be empty after sanitation' do
        timebox = build(timebox_type, *timebox_args, project: project, title: '<img src=x onerror=prompt(1)>')

        expect(timebox).not_to be_valid
        expect(timebox.errors[:title]).to include("can't be blank")
      end
    end

    describe '#timebox_type_check' do
      it 'is invalid if it has both project_id and group_id' do
        timebox = build(timebox_type, *timebox_args, group: group)
        timebox.project = project

        expect(timebox).not_to be_valid
        expect(timebox.errors[:project_id]).to include("#{timebox_type} should belong either to a project or a group.")
      end
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:issues) }
    it { is_expected.to have_many(:merge_requests) }
    it { is_expected.to have_many(:labels) }
  end

  describe '#timebox_name' do
    it 'returns the name of the model' do
      expect(timebox.timebox_name).to eq(timebox_type.to_s)
    end
  end

  describe '#project_timebox?' do
    context 'when project_id is present' do
      it 'returns true' do
        expect(timebox.project_timebox?).to be_truthy
      end
    end

    context 'when project_id is not present' do
      let(:timebox) { build(timebox_type, *timebox_args, group: group) }

      it 'returns false' do
        expect(timebox.project_timebox?).to be_falsey
      end
    end
  end

  describe '#group_timebox?' do
    context 'when group_id is present' do
      let(:timebox) { build(timebox_type, *timebox_args, group: group) }

      it 'returns true' do
        expect(timebox.group_timebox?).to be_truthy
      end
    end

    context 'when group_id is not present' do
      it 'returns false' do
        expect(timebox.group_timebox?).to be_falsey
      end
    end
  end

  describe '#safe_title' do
    let(:timebox) { create(timebox_type, *timebox_args, title: "<b>foo & bar -> 2.2</b>") }

    it 'normalizes the title for use as a slug' do
      expect(timebox.safe_title).to eq('foo-bar-22')
    end
  end

  describe '#resource_parent' do
    context 'when group is present' do
      let(:timebox) { build(timebox_type, *timebox_args, group: group) }

      it 'returns the group' do
        expect(timebox.resource_parent).to eq(group)
      end
    end

    context 'when project is present' do
      it 'returns the project' do
        expect(timebox.resource_parent).to eq(project)
      end
    end
  end

  describe "#title" do
    let(:timebox) { create(timebox_type, *timebox_args, title: "<b>foo & bar -> 2.2</b>") }

    it "sanitizes title" do
      expect(timebox.title).to eq("foo & bar -> 2.2")
    end
  end

  describe '#merge_requests_enabled?' do
    context "per project" do
      it "is true for projects with MRs enabled" do
        project = create(:project, :merge_requests_enabled)
        timebox = create(timebox_type, *timebox_args, project: project)

        expect(timebox.merge_requests_enabled?).to be_truthy
      end

      it "is false for projects with MRs disabled" do
        project = create(:project, :repository_enabled, :merge_requests_disabled)
        timebox = create(timebox_type, *timebox_args, project: project)

        expect(timebox.merge_requests_enabled?).to be_falsey
      end

      it "is false for projects with repository disabled" do
        project = create(:project, :repository_disabled)
        timebox = create(timebox_type, *timebox_args, project: project)

        expect(timebox.merge_requests_enabled?).to be_falsey
      end
    end

    context "per group" do
      let(:timebox) { create(timebox_type, *timebox_args, group: group) }

      it "is always true for groups, for performance reasons" do
        expect(timebox.merge_requests_enabled?).to be_truthy
      end
    end
  end

  describe '#to_ability_name' do
    it 'returns timebox' do
      timebox = build(timebox_type, *timebox_args)

      expect(timebox.to_ability_name).to eq(timebox_type.to_s)
    end
  end

  describe '.within_timeframe' do
    let(:factory) { timebox_type }
    let(:min_date) { mid_point - 10.days }
    let(:max_date) { mid_point + 10.days }

    def box(from, to)
      create(factory, *timebox_args,
             start_date: from || open_on_left,
             due_date: to || open_on_right)
    end

    it 'can find overlapping timeboxes' do
      fully_open = box(nil, nil)
      #  ----| ................     # Not overlapping
      non_overlapping_open_on_left = box(nil, min_date - 1.day)
      #   |--| ................     # Not overlapping
      non_overlapping_closed_on_left = box(min_date - 2.days, min_date - 1.day)
      #  ------|...............     # Overlapping
      overlapping_open_on_left_just = box(nil, min_date)
      #  -----------------------|   # Overlapping
      overlapping_open_on_left_fully = box(nil, max_date + 1.day)
      #  ---------|............     # Overlapping
      overlapping_open_on_left_partial = box(nil, min_date + 1.day)
      #     |-----|............     # Overlapping
      overlapping_closed_partial = box(min_date - 1.day, min_date + 1.day)
      #        |--------------|     # Overlapping
      exact_match = box(min_date, max_date)
      #     |--------------------|  # Overlapping
      larger = box(min_date - 1.day, max_date + 1.day)
      #        ...|-----|......     # Overlapping
      smaller = box(min_date + 1.day, max_date - 1.day)
      #        .........|-----|     # Overlapping
      at_end = box(max_date - 1.day, max_date)
      #        .........|---------  # Overlapping
      at_end_open = box(max_date - 1.day, nil)
      #      |--------------------  # Overlapping
      cover_from_left = box(min_date - 1.day, nil)
      #        .........|--------|  # Overlapping
      cover_from_middle_closed = box(max_date - 1.day, max_date + 1.day)
      #        ...............|--|  # Overlapping
      overlapping_at_end_just = box(max_date, max_date + 1.day)
      #        ............... |-|  # Not Overlapping
      not_overlapping_at_right_closed = box(max_date + 1.day, max_date + 2.days)
      #        ............... |--  # Not Overlapping
      not_overlapping_at_right_open = box(max_date + 1.day, nil)

      matches = described_class.within_timeframe(min_date, max_date)

      expect(matches).to include(
        overlapping_open_on_left_just,
        overlapping_open_on_left_fully,
        overlapping_open_on_left_partial,
        overlapping_closed_partial,
        exact_match,
        larger,
        smaller,
        at_end,
        at_end_open,
        cover_from_left,
        cover_from_middle_closed,
        overlapping_at_end_just
      )

      expect(matches).not_to include(
        non_overlapping_open_on_left,
        non_overlapping_closed_on_left,
        not_overlapping_at_right_closed,
        not_overlapping_at_right_open
      )

      # Whether we match the 'fully-open' range depends on whether
      # it is in fact open (i.e. whether the class allows infinite
      # ranges)
      if open_on_left.nil? && open_on_right.nil?
        expect(matches).not_to include(fully_open)
      else
        expect(matches).to include(fully_open)
      end
    end
  end
end
