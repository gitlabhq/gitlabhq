require 'spec_helper'
require 'rufus-scheduler' # Included in sidekiq-cron

describe Ci::ScheduledTrigger, models: true do

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:owner) }
  end

  describe '#schedule_next_run!' do
    context 'when cron and cron_time_zone are vaild' do
      context 'when nightly build' do
        it 'schedules next run' do
          scheduled_trigger = create(:ci_scheduled_trigger, :cron_nightly_build)
          scheduled_trigger.schedule_next_run!
          puts "scheduled_trigger: #{scheduled_trigger.inspect}"

          expect(scheduled_trigger.cron).to be_nil
        end
      end

      context 'when weekly build' do

      end

      context 'when monthly build' do

      end
    end

    context 'when cron and cron_time_zone are invaild' do
      it 'schedules nothing' do

      end
    end
  end
end
