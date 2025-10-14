# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Schedulable do
  shared_examples 'before_save callback' do
    context 'when allow_next_run_at_update? is true' do
      before do
        allow(object).to receive(:allow_next_run_at_update?).and_return(true)
      end

      it 'updates next_run_at' do
        expect { object.save! }.to change { object.next_run_at }
      end
    end

    context 'when allow_next_run_at_update? is false' do
      before do
        allow(object).to receive(:allow_next_run_at_update?).and_return(false)
      end

      it 'does not update next_run_at' do
        expect { object.save! }.not_to change { object.next_run_at }
      end
    end
  end

  shared_examples '.runnable_schedules' do
    it 'returns the runnable schedules' do
      results = object.class.runnable_schedules

      expect(results).to include(object)
      expect(results).not_to include(non_runnable_object)
    end
  end

  shared_examples '#schedule_next_run!' do
    it 'saves the object and sets next_run_at' do
      expect { object.schedule_next_run! }.to change { object.next_run_at }
    end

    it 'sets next_run_at to nil on error' do
      expect(object).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      object.schedule_next_run!

      expect(object.next_run_at).to be_nil
    end
  end

  context 'for a pipeline_schedule' do
    # let! is used to reset the next_run_at value before each spec
    let(:object) do
      travel_to(1.day.ago) do
        create(:ci_pipeline_schedule, :hourly)
      end
    end

    let(:non_runnable_object) { create(:ci_pipeline_schedule, :hourly) }

    it_behaves_like '#schedule_next_run!'
    it_behaves_like 'before_save callback'
    it_behaves_like '.runnable_schedules'
  end

  context 'for a container_expiration_policy' do
    # let! is used to reset the next_run_at value before each spec
    let(:object) { create(:container_expiration_policy, :runnable) }
    let(:non_runnable_object) { create(:container_expiration_policy) }

    it_behaves_like '#schedule_next_run!'
    it_behaves_like 'before_save callback'
    it_behaves_like '.runnable_schedules'
  end

  context 'for a packages cleanup policy' do
    # let! is used to reset the next_run_at value before each spec
    let(:object) { create(:packages_cleanup_policy, :runnable) }
    let(:non_runnable_object) { create(:packages_cleanup_policy) }

    it_behaves_like '#schedule_next_run!'
    it_behaves_like 'before_save callback'
    it_behaves_like '.runnable_schedules'
  end

  describe '#next_run_at' do
    let(:schedulable_instance) do
      Class.new(ActiveRecord::Base) do
        include Schedulable

        # we need a table for the dummy class to operate
        self.table_name = 'users'
      end.new
    end

    it 'raises a NotImplementedError' do
      expect { schedulable_instance.set_next_run_at }.to raise_error(NotImplementedError)
    end
  end
end
