# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iteration do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  describe "#iid" do
    it "is properly scoped on project and group" do
      iteration1 = create(:iteration, :skip_project_validation, project: project)
      iteration2 = create(:iteration, :skip_project_validation, project: project)
      iteration3 = create(:iteration, group: group)
      iteration4 = create(:iteration, group: group)
      iteration5 = create(:iteration, :skip_project_validation, project: project)

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

  describe '.filter_by_state' do
    let_it_be(:closed_iteration) { create(:iteration, :closed, :skip_future_date_validation, group: group, start_date: 8.days.ago, due_date: 2.days.ago) }
    let_it_be(:started_iteration) { create(:iteration, :started, :skip_future_date_validation, group: group, start_date: 1.day.ago, due_date: 6.days.from_now) }
    let_it_be(:upcoming_iteration) { create(:iteration, :upcoming, group: group, start_date: 1.week.from_now, due_date: 2.weeks.from_now) }

    shared_examples_for 'filter_by_state' do
      it 'filters by the given state' do
        expect(described_class.filter_by_state(Iteration.all, state)).to match(expected_iterations)
      end
    end

    context 'filtering by closed iterations' do
      it_behaves_like 'filter_by_state' do
        let(:state) { 'closed' }
        let(:expected_iterations) { [closed_iteration] }
      end
    end

    context 'filtering by started iterations' do
      it_behaves_like 'filter_by_state' do
        let(:state) { 'started' }
        let(:expected_iterations) { [started_iteration] }
      end
    end

    context 'filtering by opened iterations' do
      it_behaves_like 'filter_by_state' do
        let(:state) { 'opened' }
        let(:expected_iterations) { [started_iteration, upcoming_iteration] }
      end
    end

    context 'filtering by upcoming iterations' do
      it_behaves_like 'filter_by_state' do
        let(:state) { 'upcoming' }
        let(:expected_iterations) { [upcoming_iteration] }
      end
    end

    context 'filtering by "all"' do
      it_behaves_like 'filter_by_state' do
        let(:state) { 'all' }
        let(:expected_iterations) { [closed_iteration, started_iteration, upcoming_iteration] }
      end
    end

    context 'filtering by nonexistent filter' do
      it 'raises ArgumentError' do
        expect { described_class.filter_by_state(Iteration.none, 'unknown') }.to raise_error(ArgumentError, 'Unknown state filter: unknown')
      end
    end
  end

  context 'Validations' do
    subject { build(:iteration, group: group, start_date: start_date, due_date: due_date) }

    describe '#not_belonging_to_project' do
      subject { build(:iteration, project: project, start_date: Time.current, due_date: 1.day.from_now) }

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:project_id]).to include('is not allowed. We do not currently support project-level iterations')
      end
    end

    describe '#dates_do_not_overlap' do
      let_it_be(:existing_iteration) { create(:iteration, group: group, start_date: 4.days.from_now, due_date: 1.week.from_now) }

      context 'when no Iteration dates overlap' do
        let(:start_date) { 2.weeks.from_now }
        let(:due_date) { 3.weeks.from_now }

        it { is_expected.to be_valid }
      end

      context 'when updated iteration dates overlap with its own dates' do
        it 'is valid' do
          existing_iteration.start_date = 5.days.from_now

          expect(existing_iteration).to be_valid
        end
      end

      context 'when dates overlap' do
        let(:start_date) { 5.days.from_now }
        let(:due_date) { 6.days.from_now }

        shared_examples_for 'overlapping dates' do |skip_constraint_test: false|
          context 'when start_date is in range' do
            let(:start_date) { 5.days.from_now }
            let(:due_date) { 3.weeks.from_now }

            it 'is not valid' do
              expect(subject).not_to be_valid
              expect(subject.errors[:base]).to include('Dates cannot overlap with other existing Iterations')
            end

            unless skip_constraint_test
              it 'is not valid even if forced' do
                subject.validate # to generate iid/etc
                expect { subject.save!(validate: false) }.to raise_exception(ActiveRecord::StatementInvalid, /#{constraint_name}/)
              end
            end
          end

          context 'when end_date is in range' do
            let(:start_date) { Time.current }
            let(:due_date) { 6.days.from_now }

            it 'is not valid' do
              expect(subject).not_to be_valid
              expect(subject.errors[:base]).to include('Dates cannot overlap with other existing Iterations')
            end

            unless skip_constraint_test
              it 'is not valid even if forced' do
                subject.validate # to generate iid/etc
                expect { subject.save!(validate: false) }.to raise_exception(ActiveRecord::StatementInvalid, /#{constraint_name}/)
              end
            end
          end

          context 'when both overlap' do
            it 'is not valid' do
              expect(subject).not_to be_valid
              expect(subject.errors[:base]).to include('Dates cannot overlap with other existing Iterations')
            end

            unless skip_constraint_test
              it 'is not valid even if forced' do
                subject.validate # to generate iid/etc
                expect { subject.save!(validate: false) }.to raise_exception(ActiveRecord::StatementInvalid, /#{constraint_name}/)
              end
            end
          end
        end

        context 'group' do
          it_behaves_like 'overlapping dates' do
            let(:constraint_name) { 'iteration_start_and_due_daterange_group_id_constraint' }
          end

          context 'different group' do
            let(:group) { create(:group) }

            it { is_expected.to be_valid }

            it 'does not trigger exclusion constraints' do
              expect { subject.save! }.not_to raise_exception
            end
          end

          context 'sub-group' do
            let(:subgroup) { create(:group, parent: group) }

            subject { build(:iteration, group: subgroup, start_date: start_date, due_date: due_date) }

            it_behaves_like 'overlapping dates', skip_constraint_test: true
          end
        end

        context 'project' do
          let_it_be(:existing_iteration) { create(:iteration, :skip_project_validation, project: project, start_date: 4.days.from_now, due_date: 1.week.from_now) }

          subject { build(:iteration, :skip_project_validation, project: project, start_date: start_date, due_date: due_date) }

          it_behaves_like 'overlapping dates' do
            let(:constraint_name) { 'iteration_start_and_due_daterange_project_id_constraint' }
          end

          context 'different project' do
            let(:project) { create(:project) }

            it { is_expected.to be_valid }

            it 'does not trigger exclusion constraints' do
              expect { subject.save! }.not_to raise_exception
            end
          end

          context 'in a group' do
            let(:group) { create(:group) }

            subject { build(:iteration, group: group, start_date: start_date, due_date: due_date) }

            it { is_expected.to be_valid }

            it 'does not trigger exclusion constraints' do
              expect { subject.save! }.not_to raise_exception
            end
          end
        end

        context 'project in a group' do
          let_it_be(:project) { create(:project, group: create(:group)) }
          let_it_be(:existing_iteration) { create(:iteration, :skip_project_validation, project: project, start_date: 4.days.from_now, due_date: 1.week.from_now) }

          subject { build(:iteration, :skip_project_validation, project: project, start_date: start_date, due_date: due_date) }

          it_behaves_like 'overlapping dates' do
            let(:constraint_name) { 'iteration_start_and_due_daterange_project_id_constraint' }
          end
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

  context 'time scopes' do
    let_it_be(:project) { create(:project, :empty_repo) }
    let_it_be(:iteration_1) { create(:iteration, :skip_future_date_validation, :skip_project_validation, project: project, start_date: 3.days.ago, due_date: 1.day.from_now) }
    let_it_be(:iteration_2) { create(:iteration, :skip_future_date_validation, :skip_project_validation, project: project, start_date: 10.days.ago, due_date: 4.days.ago) }
    let_it_be(:iteration_3) { create(:iteration, :skip_project_validation, project: project, start_date: 4.days.from_now, due_date: 1.week.from_now) }

    describe 'start_date_passed' do
      it 'returns iterations where start_date is in the past but due_date is in the future' do
        expect(described_class.start_date_passed).to contain_exactly(iteration_1)
      end
    end

    describe 'due_date_passed' do
      it 'returns iterations where due date is in the past' do
        expect(described_class.due_date_passed).to contain_exactly(iteration_2)
      end
    end
  end

  describe '.within_timeframe' do
    let_it_be(:now) { Time.current }
    let_it_be(:project) { create(:project, :empty_repo) }
    let_it_be(:iteration_1) { create(:iteration, :skip_project_validation, project: project, start_date: now, due_date: 1.day.from_now) }
    let_it_be(:iteration_2) { create(:iteration, :skip_project_validation, project: project, start_date: 2.days.from_now, due_date: 3.days.from_now) }
    let_it_be(:iteration_3) { create(:iteration, :skip_project_validation, project: project, start_date: 4.days.from_now, due_date: 1.week.from_now) }

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
