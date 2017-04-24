require 'spec_helper'

describe Ci::PipelineSchedule, models: true do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:trigger) }
  it { is_expected.to respond_to(:ref) }

  describe 'validations' do
    it 'does not allow invalid cron patters' do
      pipeline_schedule = build(:ci_pipeline_schedule, cron: '0 0 0 * *')

      expect(pipeline_schedule).not_to be_valid
    end

    it 'does not allow invalid cron patters' do
      pipeline_schedule = build(:ci_pipeline_schedule, cron_timezone: 'invalid')

      expect(pipeline_schedule).not_to be_valid
    end
  end

  describe '#set_next_run_at' do
    let!(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly) }

    context 'when creates new pipeline schedule' do
      let(:expected_next_run_at) do
        Gitlab::Ci::CronParser.new(pipeline_schedule.cron, pipeline_schedule.cron_timezone).
          next_time_from(Time.now)
      end

      it 'updates next_run_at automatically' do
        expect(Ci::PipelineSchedule.last.next_run_at).to eq(expected_next_run_at)
      end
    end

    context 'when updates cron of exsisted pipeline schedule' do
      let(:new_cron) { '0 0 1 1 *' }

      let(:expected_next_run_at) do
        Gitlab::Ci::CronParser.new(new_cron, pipeline_schedule.cron_timezone).
          next_time_from(Time.now)
      end

      it 'updates next_run_at automatically' do
        pipeline_schedule.update!(cron: new_cron)

        expect(Ci::PipelineSchedule.last.next_run_at).to eq(expected_next_run_at)
      end
    end
  end

  describe '#schedule_next_run!' do
    let!(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly) }

    context 'when reschedules after 10 days from now' do
      let(:future_time) { 10.days.from_now }

      let(:expected_next_run_at) do
        Gitlab::Ci::CronParser.new(pipeline_schedule.cron, pipeline_schedule.cron_timezone).
          next_time_from(future_time)
      end

      it 'points to proper next_run_at' do
        Timecop.freeze(future_time) do
          pipeline_schedule.schedule_next_run!

          expect(pipeline_schedule.next_run_at).to eq(expected_next_run_at)
        end
      end
    end
  end
end
