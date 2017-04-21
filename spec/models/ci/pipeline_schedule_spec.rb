require 'spec_helper'

describe Ci::TriggerSchedule, models: true do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:trigger) }
  it { is_expected.to respond_to(:ref) }

  describe '#set_next_run_at' do
    context 'when creates new TriggerSchedule' do
      before do
        trigger_schedule = create(:ci_trigger_schedule, :nightly)
        @expected_next_run_at = Gitlab::Ci::CronParser.new(trigger_schedule.cron, trigger_schedule.cron_timezone)
                                                      .next_time_from(Time.now)
      end

      it 'updates next_run_at automatically' do
        expect(Ci::TriggerSchedule.last.next_run_at).to eq(@expected_next_run_at)
      end
    end

    context 'when updates cron of exsisted TriggerSchedule' do
      before do
        trigger_schedule = create(:ci_trigger_schedule, :nightly)
        new_cron = '0 0 1 1 *'
        trigger_schedule.update!(cron: new_cron) # Subject
        @expected_next_run_at = Gitlab::Ci::CronParser.new(new_cron, trigger_schedule.cron_timezone)
                                                      .next_time_from(Time.now)
      end

      it 'updates next_run_at automatically' do
        expect(Ci::TriggerSchedule.last.next_run_at).to eq(@expected_next_run_at)
      end
    end
  end

  describe '#schedule_next_run!' do
    context 'when reschedules after 10 days from now' do
      before do
        trigger_schedule = create(:ci_trigger_schedule, :nightly)
        time_future = Time.now + 10.days
        allow(Time).to receive(:now).and_return(time_future)
        trigger_schedule.schedule_next_run! # Subject
        @expected_next_run_at = Gitlab::Ci::CronParser.new(trigger_schedule.cron, trigger_schedule.cron_timezone)
                                                      .next_time_from(time_future)
      end

      it 'points to proper next_run_at' do
        expect(Ci::TriggerSchedule.last.next_run_at).to eq(@expected_next_run_at)
      end
    end

    context 'when cron is invalid' do
      before do
        trigger_schedule = create(:ci_trigger_schedule, :nightly)
        trigger_schedule.cron = 'Invalid-cron'
        trigger_schedule.schedule_next_run! # Subject
      end

      it 'sets nil to next_run_at' do
        expect(Ci::TriggerSchedule.last.next_run_at).to be_nil
      end
    end

    context 'when cron_timezone is invalid' do
      before do
        trigger_schedule = create(:ci_trigger_schedule, :nightly)
        trigger_schedule.cron_timezone = 'Invalid-cron_timezone'
        trigger_schedule.schedule_next_run! # Subject
      end

      it 'sets nil to next_run_at' do
        expect(Ci::TriggerSchedule.last.next_run_at).to be_nil
      end
    end
  end
end
