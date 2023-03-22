# frozen_string_literal: true

RSpec.shared_examples 'a timebox' do |timebox_type|
  let(:timebox_args) { [] }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }
  let(:timebox_table_name) { timebox_type.to_s.pluralize.to_sym }

  # Values implementions can override
  let(:mid_point) { Time.now.utc.to_date }
  let(:open_on_left) { nil }
  let(:open_on_right) { nil }

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
  end

  describe "Associations" do
    it { is_expected.to have_many(:issues) }
    it { is_expected.to have_many(:merge_requests) }
    it { is_expected.to have_many(:labels).through(:issues) }
  end

  describe '#timebox_name' do
    it 'returns the name of the model' do
      expect(timebox.timebox_name).to eq(timebox_type.to_s)
    end
  end

  describe '#safe_title' do
    let(:timebox) { create(timebox_type, *timebox_args, title: "<b>foo & bar -> 2.2</b>") }

    it 'normalizes the title for use as a slug' do
      expect(timebox.safe_title).to eq('foo-bar-22')
    end
  end

  describe "#title" do
    let(:timebox) { create(timebox_type, *timebox_args, title: "<b>foo & bar -> 2.2</b>") }

    it "sanitizes title" do
      expect(timebox.title).to eq("foo & bar -> 2.2")
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
      create(
        factory,
        *timebox_args,
        start_date: from || open_on_left,
        due_date: to || open_on_right
      )
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
