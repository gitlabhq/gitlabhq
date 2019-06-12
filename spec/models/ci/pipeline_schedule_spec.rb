# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelineSchedule do
  subject { build(:ci_pipeline_schedule) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:owner) }

  it { is_expected.to have_many(:pipelines) }
  it { is_expected.to have_many(:variables) }

  it { is_expected.to respond_to(:ref) }
  it { is_expected.to respond_to(:cron) }
  it { is_expected.to respond_to(:cron_timezone) }
  it { is_expected.to respond_to(:description) }
  it { is_expected.to respond_to(:next_run_at) }

  describe 'validations' do
    it 'does not allow invalid cron patters' do
      pipeline_schedule = build(:ci_pipeline_schedule, cron: '0 0 0 * *')

      expect(pipeline_schedule).not_to be_valid
    end

    it 'does not allow invalid cron patters' do
      pipeline_schedule = build(:ci_pipeline_schedule, cron_timezone: 'invalid')

      expect(pipeline_schedule).not_to be_valid
    end

    context 'when active is false' do
      it 'does not allow nullified ref' do
        pipeline_schedule = build(:ci_pipeline_schedule, :inactive, ref: nil)

        expect(pipeline_schedule).not_to be_valid
      end
    end

    context 'when cron contains trailing whitespaces' do
      it 'strips the attribute' do
        pipeline_schedule = build(:ci_pipeline_schedule, cron: ' 0 0 * * *   ')

        expect(pipeline_schedule).to be_valid
        expect(pipeline_schedule.cron).to eq('0 0 * * *')
      end
    end
  end

  describe '.runnable_schedules' do
    subject { described_class.runnable_schedules }

    let!(:pipeline_schedule) do
      Timecop.freeze(1.day.ago) do
        create(:ci_pipeline_schedule, :hourly)
      end
    end

    it 'returns the runnable schedule' do
      is_expected.to eq([pipeline_schedule])
    end

    context 'when there are no runnable schedules' do
      let!(:pipeline_schedule) { }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe '.preloaded' do
    subject { described_class.preloaded }

    before do
      create_list(:ci_pipeline_schedule, 3)
    end

    it 'preloads the associations' do
      subject

      query = ActiveRecord::QueryRecorder.new { subject.each(&:project) }

      expect(query.count).to eq(2)
    end
  end

  describe '#set_next_run_at' do
    let(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly) }
    let(:ideal_next_run_at) { pipeline_schedule.send(:ideal_next_run_at) }

    let(:expected_next_run_at) do
      Gitlab::Ci::CronParser.new(Settings.cron_jobs['pipeline_schedule_worker']['cron'], Time.zone.name)
        .next_time_from(ideal_next_run_at)
    end

    let(:cron_worker_next_run_at) do
      Gitlab::Ci::CronParser.new(Settings.cron_jobs['pipeline_schedule_worker']['cron'], Time.zone.name)
        .next_time_from(Time.zone.now)
    end

    context 'when creates new pipeline schedule' do
      it 'updates next_run_at automatically' do
        expect(pipeline_schedule.next_run_at).to eq(expected_next_run_at)
      end
    end

    context 'when PipelineScheduleWorker runs at a specific interval' do
      before do
        allow(Settings).to receive(:cron_jobs) do
          {
            'pipeline_schedule_worker' => {
              'cron' => '0 1 2 3 *'
            }
          }
        end
      end

      it "updates next_run_at to the sidekiq worker's execution time" do
        expect(pipeline_schedule.next_run_at.min).to eq(0)
        expect(pipeline_schedule.next_run_at.hour).to eq(1)
        expect(pipeline_schedule.next_run_at.day).to eq(2)
        expect(pipeline_schedule.next_run_at.month).to eq(3)
      end
    end

    context 'when pipeline schedule runs every minute' do
      let(:pipeline_schedule) { create(:ci_pipeline_schedule, :every_minute) }

      it "updates next_run_at to the sidekiq worker's execution time", :quarantine do
        expect(pipeline_schedule.next_run_at).to eq(cron_worker_next_run_at)
      end
    end

    context 'when there are two different pipeline schedules in different time zones' do
      let(:pipeline_schedule_1) { create(:ci_pipeline_schedule, :weekly, cron_timezone: 'Eastern Time (US & Canada)') }
      let(:pipeline_schedule_2) { create(:ci_pipeline_schedule, :weekly, cron_timezone: 'UTC') }

      it 'sets different next_run_at' do
        expect(pipeline_schedule_1.next_run_at).not_to eq(pipeline_schedule_2.next_run_at)
      end
    end

    context 'when there are two different pipeline schedules in the same time zones' do
      let(:pipeline_schedule_1) { create(:ci_pipeline_schedule, :weekly, cron_timezone: 'UTC') }
      let(:pipeline_schedule_2) { create(:ci_pipeline_schedule, :weekly, cron_timezone: 'UTC') }

      it 'sets the sames next_run_at' do
        expect(pipeline_schedule_1.next_run_at).to eq(pipeline_schedule_2.next_run_at)
      end
    end

    context 'when updates cron of exsisted pipeline schedule' do
      let(:new_cron) { '0 0 1 1 *' }

      it 'updates next_run_at automatically' do
        pipeline_schedule.update!(cron: new_cron)

        expect(pipeline_schedule.next_run_at).to eq(expected_next_run_at)
      end
    end
  end

  describe '#schedule_next_run!' do
    let!(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly) }

    context 'when reschedules after 10 days from now' do
      let(:future_time) { 10.days.from_now }
      let(:ideal_next_run_at) { pipeline_schedule.send(:ideal_next_run_at) }

      let(:expected_next_run_at) do
        Gitlab::Ci::CronParser.new(Settings.cron_jobs['pipeline_schedule_worker']['cron'], Time.zone.name)
          .next_time_from(ideal_next_run_at)
      end

      it 'points to proper next_run_at' do
        Timecop.freeze(future_time) do
          pipeline_schedule.schedule_next_run!

          expect(pipeline_schedule.next_run_at).to eq(expected_next_run_at)
        end
      end
    end
  end

  describe '#job_variables' do
    let!(:pipeline_schedule) { create(:ci_pipeline_schedule) }

    let!(:pipeline_schedule_variables) do
      create_list(:ci_pipeline_schedule_variable, 2, pipeline_schedule: pipeline_schedule)
    end

    subject { pipeline_schedule.job_variables }

    before do
      pipeline_schedule.reload
    end

    it { is_expected.to contain_exactly(*pipeline_schedule_variables.map(&:to_runner_variable)) }
  end
end
