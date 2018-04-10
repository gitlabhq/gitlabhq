require 'spec_helper'

describe Ci::PipelineSchedule do
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
  end

  describe '#set_next_run_at' do
    let!(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly) }

    context 'when creates new pipeline schedule' do
      let(:expected_next_run_at) do
        Gitlab::Ci::CronParser.new(pipeline_schedule.cron, pipeline_schedule.cron_timezone)
          .next_time_from(Time.now)
      end

      it 'updates next_run_at automatically' do
        expect(described_class.last.next_run_at).to eq(expected_next_run_at)
      end
    end

    context 'when updates cron of exsisted pipeline schedule' do
      let(:new_cron) { '0 0 1 1 *' }

      let(:expected_next_run_at) do
        Gitlab::Ci::CronParser.new(new_cron, pipeline_schedule.cron_timezone)
          .next_time_from(Time.now)
      end

      it 'updates next_run_at automatically' do
        pipeline_schedule.update!(cron: new_cron)

        expect(described_class.last.next_run_at).to eq(expected_next_run_at)
      end
    end
  end

  describe '#schedule_next_run!' do
    let!(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly) }

    context 'when reschedules after 10 days from now' do
      let(:future_time) { 10.days.from_now }

      let(:expected_next_run_at) do
        Gitlab::Ci::CronParser.new(pipeline_schedule.cron, pipeline_schedule.cron_timezone)
          .next_time_from(future_time)
      end

      it 'points to proper next_run_at' do
        Timecop.freeze(future_time) do
          pipeline_schedule.schedule_next_run!

          expect(pipeline_schedule.next_run_at).to eq(expected_next_run_at)
        end
      end
    end
  end

  describe '#real_next_run' do
    subject do
      described_class.last.real_next_run(worker_cron: worker_cron,
                                         worker_time_zone: worker_time_zone)
    end

    context 'when GitLab time_zone is UTC' do
      before do
        allow(Time).to receive(:zone)
          .and_return(ActiveSupport::TimeZone[worker_time_zone])
      end

      let(:worker_time_zone) { 'UTC' }

      context 'when cron_timezone is Eastern Time (US & Canada)' do
        before do
          create(:ci_pipeline_schedule, :nightly,
                  cron_timezone: 'Eastern Time (US & Canada)')
        end

        let(:worker_cron) { '0 1 2 3 *' }

        it 'returns the next time worker executes' do
          expect(subject.min).to eq(0)
          expect(subject.hour).to eq(1)
          expect(subject.day).to eq(2)
          expect(subject.month).to eq(3)
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
