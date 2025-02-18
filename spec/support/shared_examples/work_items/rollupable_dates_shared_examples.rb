# frozen_string_literal: true

RSpec.shared_examples_for 'rollupable dates - when can_rollup is false' do
  using RSpec::Parameterized::TableSyntax

  describe '#fixed?' do
    # Rules defined on https://gitlab.com/groups/gitlab-org/-/epics/11409#rules
    where(:start_date_is_fixed, :start_date_fixed, :due_date_is_fixed, :due_date_fixed) do
      false | nil | false | nil
      false | nil | false | 2.days.from_now
      false | 2.days.ago | false | nil
      false | 2.days.ago | false | 2.days.from_now
      true | 2.days.ago | false | nil
      false | nil | true | 2.days.from_now
      true | nil | true | nil
      true | 2.days.ago | true | 2.days.from_now
    end

    with_them do
      before do
        source.assign_attributes(
          start_date: nil,
          start_date_is_fixed: start_date_is_fixed,
          start_date_fixed: start_date_fixed,
          due_date: nil,
          due_date_is_fixed: due_date_is_fixed,
          due_date_fixed: due_date_fixed
        )
      end

      # regardless of the conditions, it's always fixed.
      specify { expect(rollupable_dates.fixed?).to be(true) }
    end
  end

  describe '#start_date' do
    where(:due_date_is_fixed, :due_date_fixed, :start_date_is_fixed, :start_date, :start_date_fixed) do
      false | nil | false | nil | nil
      false | nil | false | nil | 1.day.ago.to_date
      false | nil | false | 2.days.ago.to_date | nil
      false | nil | false | 2.days.ago.to_date | 3.days.ago.to_date
      false | nil | true | 2.days.ago.to_date | nil
      false | nil | true | 2.days.ago.to_date | 3.days.ago.to_date
      true | 1.day.from_now | false | 2.days.ago.to_date | 1.day.ago.to_date
    end

    with_them do
      before do
        source.assign_attributes(
          start_date: start_date,
          start_date_fixed: start_date_fixed,
          start_date_is_fixed: start_date_is_fixed,
          due_date: nil,
          due_date_fixed: due_date_fixed,
          due_date_is_fixed: due_date_is_fixed
        )
      end

      specify { expect(rollupable_dates.start_date).to eq(start_date_fixed) }
    end
  end

  describe '#due_date' do
    where(:start_date_is_fixed, :start_date_fixed, :due_date_is_fixed, :due_date, :due_date_fixed) do
      false | nil | false | nil | nil
      false | nil | false | nil | 1.day.ago.to_date
      false | nil | false | 2.days.ago.to_date | nil
      false | nil | false | 2.days.ago.to_date | 3.days.ago.to_date
      false | nil | true | 2.days.ago.to_date | nil
      false | nil | true | 2.days.ago.to_date | 3.days.ago.to_date
      true | 1.day.from_now | false | 2.days.ago.to_date | 1.day.ago.to_date
    end

    with_them do
      before do
        source.assign_attributes(
          start_date: nil,
          start_date_fixed: start_date_fixed,
          start_date_is_fixed: start_date_is_fixed,
          due_date: due_date,
          due_date_fixed: due_date_fixed,
          due_date_is_fixed: due_date_is_fixed
        )
      end

      specify { expect(rollupable_dates.due_date).to eq(due_date_fixed) }
    end
  end

  describe '#start_date_fixed' do
    let(:date) { Time.zone.today }

    before do
      source.start_date_fixed = date
    end

    it 'delegates to the source' do
      expect(rollupable_dates.start_date_fixed).to eq(date)
    end
  end

  describe '#due_date_fixed' do
    let(:date) { Time.zone.today }

    before do
      source.due_date_fixed = date
    end

    it 'delegates to the source' do
      expect(rollupable_dates.due_date_fixed).to eq(date)
    end
  end
end

RSpec.shared_examples_for 'rollupable dates - when can_rollup is true' do
  using RSpec::Parameterized::TableSyntax

  describe '#fixed?' do
    # Rules defined on https://gitlab.com/groups/gitlab-org/-/epics/11409#rules
    where(:start_date_is_fixed, :start_date_fixed, :due_date_is_fixed, :due_date_fixed, :expected) do
      # when nothing is set, it's not fixed
      false | nil | false | nil | false
      # when dates_source dates are set, ignore work_item dates and
      # calculate based only on dates sources values
      false | nil | false | 2.days.from_now | false
      false | 2.days.ago | false | nil | false
      false | 2.days.ago | false | 2.days.from_now | false
      # if only one _is_fixed is true and has value, it's fixed
      true | 2.days.ago | false | nil | true
      false | nil | true | 2.days.from_now | true
      # if both _is_fixed is true, it's fixed
      true | nil | true | nil | true
    end

    with_them do
      before do
        source.assign_attributes(
          start_date: nil,
          start_date_is_fixed: start_date_is_fixed,
          start_date_fixed: start_date_fixed,
          due_date: nil,
          due_date_is_fixed: due_date_is_fixed,
          due_date_fixed: due_date_fixed
        )
      end

      specify { expect(rollupable_dates.fixed?).to eq(expected) }
    end
  end

  describe '#start_date' do
    where(:due_date_is_fixed, :due_date_fixed, :start_date_is_fixed, :start_date, :start_date_fixed, :expected) do
      false | nil | false | nil | nil | nil
      false | nil | false | nil | 1.day.ago.to_date | nil
      false | nil | false | 2.days.ago.to_date | nil | 2.days.ago.to_date
      false | nil | false | 2.days.ago.to_date | 3.days.ago.to_date | 2.days.ago.to_date
      false | nil | true | 2.days.ago.to_date | nil | 2.days.ago.to_date
      false | nil | true | 2.days.ago.to_date | 3.days.ago.to_date | 3.days.ago.to_date
      # If due_date_is_fixed and due_date_fixed has a value
      true | 1.day.from_now | false | 2.days.ago.to_date | 1.day.ago.to_date | 1.day.ago.to_date
    end

    with_them do
      before do
        source.assign_attributes(
          start_date: start_date,
          start_date_fixed: start_date_fixed,
          start_date_is_fixed: start_date_is_fixed,
          due_date: nil,
          due_date_fixed: due_date_fixed,
          due_date_is_fixed: due_date_is_fixed
        )
      end

      specify { expect(rollupable_dates.start_date).to eq(expected) }
    end
  end

  describe '#due_date' do
    where(:start_date_is_fixed, :start_date_fixed, :due_date_is_fixed, :due_date, :due_date_fixed, :expected) do
      false | nil | false | nil | nil | nil
      false | nil | false | nil | 1.day.ago.to_date | nil
      false | nil | false | 2.days.ago.to_date | nil | 2.days.ago.to_date
      false | nil | false | 2.days.ago.to_date | 3.days.ago.to_date | 2.days.ago.to_date
      false | nil | true | 2.days.ago.to_date | nil | 2.days.ago.to_date
      false | nil | true | 2.days.ago.to_date | 3.days.ago.to_date | 3.days.ago.to_date
      # If start_date_is_fixed and start_date_fixed has a value
      true | 1.day.from_now | false | 2.days.ago.to_date | 1.day.ago.to_date | 1.day.ago.to_date
    end

    with_them do
      before do
        source.assign_attributes(
          start_date: nil,
          start_date_fixed: start_date_fixed,
          start_date_is_fixed: start_date_is_fixed,
          due_date: due_date,
          due_date_fixed: due_date_fixed,
          due_date_is_fixed: due_date_is_fixed
        )
      end

      specify { expect(rollupable_dates.due_date).to eq(expected) }
    end
  end

  describe '#start_date_fixed' do
    let(:date) { Time.zone.today }

    before do
      source.start_date_fixed = date
    end

    it 'delegates to the source' do
      expect(rollupable_dates.start_date_fixed).to eq(date)
    end
  end

  describe '#due_date_fixed' do
    let(:date) { Time.zone.today }

    before do
      source.due_date_fixed = date
    end

    it 'delegates to the source' do
      expect(rollupable_dates.due_date_fixed).to eq(date)
    end
  end
end
