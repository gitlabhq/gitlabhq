# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Scheduling::ScheduleWithinWorker, feature_category: :scalability do
  let(:worker_class) { Class.new { def self.perform_at(_); end } }
  let(:worker_class_name) { 'MyScheduledWorker' }

  before do
    stub_const(worker_class_name, worker_class)
  end

  describe '#perform', :freeze_time do
    let(:args) { { 'worker_class' => worker_class_name } }

    subject(:execution) { described_class.new.perform(args) }

    context 'when all arguments are valid' do
      let(:within_minutes) { 10 }
      let(:within_hours) { 5 }
      let(:selected_minute) { 5 }
      let(:selected_hour) { 3 }

      before do
        allow(Random).to receive(:rand).and_return(0)
      end

      context 'when neither within_minutes nor within_hours are given' do
        let(:expected_time) { Time.current }

        it 'schedules the worker to run immediately' do
          expect(Random).not_to receive(:rand)
          expect(worker_class).to receive(:perform_at).with(expected_time)

          execution
        end
      end

      context 'when only within_minutes is given' do
        let(:expected_time) { Time.current + selected_minute.minutes }
        let(:args) { super().merge('within_minutes' => within_minutes) }

        it 'schedules the worker to run after a random number of minutes' do
          expect(Random).to receive(:rand).with(within_minutes + 1).and_return(selected_minute)
          expect(worker_class).to receive(:perform_at).with(expected_time)

          execution
        end
      end

      context 'when only within_hours is given' do
        let(:expected_time) { Time.current + selected_hour.hours }
        let(:args) { super().merge('within_hours' => within_hours) }

        it 'schedules the worker to run after a random number of hours' do
          expect(Random).to receive(:rand).with(within_hours + 1).and_return(selected_hour)
          expect(worker_class).to receive(:perform_at).with(expected_time)

          execution
        end
      end

      context 'when both within_minutes and within_hours are given' do
        let(:expected_time) { Time.current + selected_hour.hours + selected_minute.minutes }
        let(:args) { super().merge('within_minutes' => within_minutes, 'within_hours' => within_hours) }

        it 'schedules the worker to run after a random number of hours and minutes' do
          expect(Random).to receive(:rand).with(within_minutes + 1).and_return(selected_minute)
          expect(Random).to receive(:rand).with(within_hours + 1).and_return(selected_hour)

          expect(worker_class).to receive(:perform_at).with(expected_time)

          execution
        end
      end

      context 'when within_minutes is a string' do
        let(:args) { super().merge('within_minutes' => '5') }

        it 'converts it to an integer and schedules the worker' do
          expect(Random).to receive(:rand).with(5 + 1).and_return(3)
          expect(worker_class).to receive(:perform_at).with(Time.current + 3.minutes)

          execution
        end
      end

      context 'when within_hours is a string' do
        let(:args) { super().merge('within_hours' => '5') }

        it 'converts it to an integer and schedules the worker' do
          expect(Random).to receive(:rand).with(5 + 1).and_return(3)
          expect(worker_class).to receive(:perform_at).with(Time.current + 3.hours)

          execution
        end
      end

      it 'logs metadata about the scheduled job' do
        expect_next_instance_of(described_class) do |worker|
          expect(worker).to receive(:log_hash_metadata_on_done).with({
            worker_class: worker_class_name,
            within_minutes: 0,
            within_hours: 0,
            selected_minute: 0,
            selected_hour: 0,
            scheduled_for: Time.current
          })
        end

        execution
      end
    end

    describe 'arguments validation' do
      context 'when worker_class is missing' do
        let(:args) { {} }

        it 'raises an ArgumentError' do
          expect { execution }.to raise_error(ArgumentError, 'worker_class is a required argument')
        end
      end

      context 'when within_minutes is given but too small' do
        let(:args) { { 'worker_class' => worker_class_name, 'within_minutes' => 0 } }

        it 'raises an ArgumentError' do
          expect { execution }.to raise_error(ArgumentError, 'within_minutes must be nil or in [1..59]')
        end
      end

      context 'when within_minutes is given but too large' do
        let(:args) { { 'worker_class' => worker_class_name, 'within_minutes' => 60 } }

        it 'raises an ArgumentError' do
          expect { execution }.to raise_error(ArgumentError, 'within_minutes must be nil or in [1..59]')
        end
      end

      context 'when within_hours is given but too small' do
        let(:args) { { 'worker_class' => worker_class_name, 'within_hours' => 0 } }

        it 'raises an ArgumentError' do
          expect { execution }.to raise_error(ArgumentError, 'within_hours must be nil or in [1..23]')
        end
      end

      context 'when within_hours is given but too large' do
        let(:args) { { 'worker_class' => worker_class_name, 'within_hours' => 24 } }

        it 'raises an ArgumentError' do
          expect { execution }.to raise_error(ArgumentError, 'within_hours must be nil or in [1..23]')
        end
      end
    end
  end
end
