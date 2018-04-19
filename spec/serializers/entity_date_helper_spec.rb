require 'spec_helper'

describe EntityDateHelper do
  let(:date_helper_class) { Class.new { include EntityDateHelper }.new }

  it 'converts 0 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(0)).to eq(seconds: 0)
  end

  it 'converts 40 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(40)).to eq(seconds: 40)
  end

  it 'converts 60 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(60)).to eq(mins: 1)
  end

  it 'converts 70 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(70)).to eq(mins: 1, seconds: 10)
  end

  it 'converts 3600 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(3600)).to eq(hours: 1)
  end

  it 'converts 3750 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(3750)).to eq(hours: 1, mins: 2, seconds: 30)
  end

  it 'converts 86400 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(86400)).to eq(days: 1)
  end

  it 'converts 86560 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(86560)).to eq(days: 1, mins: 2, seconds: 40)
  end

  it 'converts 86760 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(99760)).to eq(days: 1, hours: 3, mins: 42, seconds: 40)
  end

  it 'converts 986760 seconds' do
    expect(date_helper_class.distance_of_time_as_hash(986760)).to eq(days: 11, hours: 10, mins: 6)
  end

  describe '#remaining_days_in_words' do
    around do |example|
      Timecop.freeze(Time.utc(2017, 3, 17)) { example.run }
    end

    context 'when less than 31 days remaining' do
      let(:milestone_remaining) { date_helper_class.remaining_days_in_words(build_stubbed(:milestone, due_date: 12.days.from_now.utc)) }

      it 'returns days remaining' do
        expect(milestone_remaining).to eq("<strong>12</strong> days remaining")
      end
    end

    context 'when less than 1 year and more than 30 days remaining' do
      let(:milestone_remaining) { date_helper_class.remaining_days_in_words(build_stubbed(:milestone, due_date: 2.months.from_now.utc)) }

      it 'returns months remaining' do
        expect(milestone_remaining).to eq("<strong>2</strong> months remaining")
      end
    end

    context 'when more than 1 year remaining' do
      let(:milestone_remaining) { date_helper_class.remaining_days_in_words(build_stubbed(:milestone, due_date: (1.year.from_now + 2.days).utc)) }

      it 'returns years remaining' do
        expect(milestone_remaining).to eq("<strong>1</strong> year remaining")
      end
    end

    context 'when milestone is expired' do
      let(:milestone_remaining) { date_helper_class.remaining_days_in_words(build_stubbed(:milestone, due_date: 2.days.ago.utc)) }

      it 'returns "Past due"' do
        expect(milestone_remaining).to eq("<strong>Past due</strong>")
      end
    end

    context 'when milestone has start_date in the future' do
      let(:milestone_remaining) { date_helper_class.remaining_days_in_words(build_stubbed(:milestone, start_date: 2.days.from_now.utc)) }

      it 'returns "Upcoming"' do
        expect(milestone_remaining).to eq("<strong>Upcoming</strong>")
      end
    end

    context 'when milestone has start_date in the past' do
      let(:milestone_remaining) { date_helper_class.remaining_days_in_words(build_stubbed(:milestone, start_date: 2.days.ago.utc)) }

      it 'returns days elapsed' do
        expect(milestone_remaining).to eq("<strong>2</strong> days elapsed")
      end
    end
  end
end
