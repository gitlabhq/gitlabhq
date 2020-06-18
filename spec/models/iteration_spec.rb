# frozen_string_literal: true

require 'spec_helper'

describe Iteration do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  describe "#iid" do
    it "is properly scoped on project and group" do
      iteration1 = create(:iteration, project: project)
      iteration2 = create(:iteration, project: project)
      iteration3 = create(:iteration, group: group)
      iteration4 = create(:iteration, group: group)
      iteration5 = create(:iteration, project: project)

      want = {
          iteration1: 1,
          iteration2: 2,
          iteration3: 1,
          iteration4: 2,
          iteration5: 3
      }
      got = {
          iteration1: iteration1.iid,
          iteration2: iteration2.iid,
          iteration3: iteration3.iid,
          iteration4: iteration4.iid,
          iteration5: iteration5.iid
      }
      expect(got).to eq(want)
    end
  end

  context 'Validations' do
    subject { build(:iteration, group: group, start_date: start_date, due_date: due_date) }

    describe '#dates_do_not_overlap' do
      let_it_be(:existing_iteration) { create(:iteration, group: group, start_date: 4.days.from_now, due_date: 1.week.from_now) }

      context 'when no Iteration dates overlap' do
        let(:start_date) { 2.weeks.from_now }
        let(:due_date) { 3.weeks.from_now }

        it { is_expected.to be_valid }
      end

      context 'when dates overlap' do
        context 'same group' do
          context 'when start_date is in range' do
            let(:start_date) { 5.days.from_now }
            let(:due_date) { 3.weeks.from_now }

            it 'is not valid' do
              expect(subject).not_to be_valid
              expect(subject.errors[:base]).to include('Dates cannot overlap with other existing Iterations')
            end
          end

          context 'when end_date is in range' do
            let(:start_date) { Time.current }
            let(:due_date) { 6.days.from_now }

            it 'is not valid' do
              expect(subject).not_to be_valid
              expect(subject.errors[:base]).to include('Dates cannot overlap with other existing Iterations')
            end
          end

          context 'when both overlap' do
            let(:start_date) { 5.days.from_now }
            let(:due_date) { 6.days.from_now }

            it 'is not valid' do
              expect(subject).not_to be_valid
              expect(subject.errors[:base]).to include('Dates cannot overlap with other existing Iterations')
            end
          end
        end

        context 'different group' do
          let(:start_date) { 5.days.from_now }
          let(:due_date) { 6.days.from_now }
          let(:group) { create(:group) }

          it { is_expected.to be_valid }
        end
      end
    end

    describe '#future_date' do
      context 'when dates are in the future' do
        let(:start_date) { Time.current }
        let(:due_date) { 1.week.from_now }

        it { is_expected.to be_valid }
      end

      context 'when start_date is in the past' do
        let(:start_date) { 1.week.ago }
        let(:due_date) { 1.week.from_now }

        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors[:start_date]).to include('cannot be in the past')
        end
      end

      context 'when due_date is in the past' do
        let(:start_date) { Time.current }
        let(:due_date) { 1.week.ago }

        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors[:due_date]).to include('cannot be in the past')
        end
      end

      context 'when start_date is over 500 years in the future' do
        let(:start_date) { 501.years.from_now }
        let(:due_date) { Time.current }

        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors[:start_date]).to include('cannot be more than 500 years in the future')
        end
      end

      context 'when due_date is over 500 years in the future' do
        let(:start_date) { Time.current }
        let(:due_date) { 501.years.from_now }

        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors[:due_date]).to include('cannot be more than 500 years in the future')
        end
      end
    end
  end

  describe '.within_timeframe' do
    let_it_be(:now) { Time.current }
    let_it_be(:project) { create(:project, :empty_repo) }
    let_it_be(:iteration_1) { create(:iteration, project: project, start_date: now, due_date: 1.day.from_now) }
    let_it_be(:iteration_2) { create(:iteration, project: project, start_date: 2.days.from_now, due_date: 3.days.from_now) }
    let_it_be(:iteration_3) { create(:iteration, project: project, start_date: 4.days.from_now, due_date: 1.week.from_now) }

    it 'returns iterations with start_date and/or end_date between timeframe' do
      iterations = described_class.within_timeframe(2.days.from_now, 3.days.from_now)

      expect(iterations).to match_array([iteration_2])
    end

    it 'returns iterations which starts before the timeframe' do
      iterations = described_class.within_timeframe(1.day.from_now, 3.days.from_now)

      expect(iterations).to match_array([iteration_1, iteration_2])
    end

    it 'returns iterations which ends after the timeframe' do
      iterations = described_class.within_timeframe(3.days.from_now, 5.days.from_now)

      expect(iterations).to match_array([iteration_2, iteration_3])
    end
  end
end
