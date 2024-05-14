# frozen_string_literal: true
# rubocop:disable Layout/LineLength
require 'spec_helper'

RSpec.describe Ci::PipelineSchedules::CalculateNextRunService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :public, :repository) }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    let(:run_service) do
      described_class.new(project).execute(pipeline_schedule,
        fallback_method: pipeline_schedule.method(:calculate_next_run_at))
    end

    let(:pipeline_schedule) { create(:ci_pipeline_schedule, cron: schedule_cron) }
    let(:daily_limit_of_144_runs) { 1.day / 10.minutes }
    let(:daily_limit_of_24_runs) { 1.day / 1.hour }

    before do
      allow(Settings).to receive(:cron_jobs) { { 'pipeline_schedule_worker' => { 'cron' => worker_cron } } }
      create(:plan_limits, :default_plan, ci_daily_pipeline_schedule_triggers: plan_limit) if plan_limit
    end

    context "when there is invalid or no plan limits" do
      where(:worker_cron, :schedule_cron, :plan_limit, :now, :expected_result) do
        '0 1 2 3 *'   | '0 1 * * *'   | nil             | Time.zone.local(2021, 3, 2, 1, 0)   | Time.zone.local(2022, 3, 2, 1, 0)
        '*/5 * * * *' | '*/1 * * * *' | nil             | Time.zone.local(2021, 5, 27, 11, 0) | Time.zone.local(2021, 5, 27, 11, 5)
        '*/5 * * * *' | '0 * * * *'   | nil             | Time.zone.local(2021, 5, 27, 11, 0) | Time.zone.local(2021, 5, 27, 12, 5)
        # 1.day / 2.hours => 12 times a day and it is invalid because there is a minimum for plan limits.
        # See: https://docs.gitlab.com/ee/administration/instance_limits.html#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-per-day
        '*/5 * * * *' | '0 * * * *'   | (1.day / 2.hours) | Time.zone.local(2021, 5, 27, 11, 0) | Time.zone.local(2021, 5, 27, 12, 5)
        '*/5 * * * *' | '0 * * * *'   | 2000            | Time.zone.local(2021, 5, 27, 11, 0) | Time.zone.local(2021, 5, 27, 12, 5)
        '*/5 * * * *' | '0 * * * *'   | -24             | Time.zone.local(2021, 5, 27, 11, 0) | Time.zone.local(2021, 5, 27, 12, 5)
      end

      with_them do
        it 'calls fallback method to get next_run_at' do
          travel_to(now) do
            expect(pipeline_schedule).to receive(:calculate_next_run_at).and_call_original

            result = run_service

            expect(result).to eq(expected_result)
          end
        end
      end
    end

    context "when the workers next run matches schedule's earliest run" do
      where(:worker_cron, :schedule_cron, :plan_limit, :now, :expected_result) do
        '*/5 * * * *' | '0 * * * *'   | daily_limit_of_144_runs  | Time.zone.local(2021, 5, 27, 11, 0)  | Time.zone.local(2021, 5, 27, 12, 0)
        '*/5 * * * *' | '*/5 * * * *' | daily_limit_of_144_runs  | Time.zone.local(2021, 5, 27, 11, 0)  | Time.zone.local(2021, 5, 27, 11, 10)
        '*/5 * * * *' | '0 1 * * *'   | daily_limit_of_144_runs  | Time.zone.local(2021, 5, 27, 1, 0)   | Time.zone.local(2021, 5, 28, 1, 0)
        '*/5 * * * *' | '0 2 * * *'   | daily_limit_of_144_runs  | Time.zone.local(2021, 5, 27, 1, 0)   | Time.zone.local(2021, 5, 27, 2, 0)
        '*/5 * * * *' | '0 3 * * *'   | daily_limit_of_144_runs  | Time.zone.local(2021, 5, 27, 1, 0)   | Time.zone.local(2021, 5, 27, 3, 0)
        '*/5 * * * *' | '0 1 1 * *'   | daily_limit_of_144_runs  | Time.zone.local(2021, 5, 1, 1, 0)    | Time.zone.local(2021, 6, 1, 1, 0)
        '*/9 * * * *' | '0 1 1 * *'   | daily_limit_of_144_runs  | Time.zone.local(2021, 5, 1, 1, 9)    | Time.zone.local(2021, 6, 1, 1, 0)
        '*/5 * * * *' | '45 21 1 2 *' | daily_limit_of_144_runs  | Time.zone.local(2021, 2, 1, 21, 45)  | Time.zone.local(2022, 2, 1, 21, 45)
      end

      with_them do
        it 'calculates the next_run_at to be earliest point of match' do
          travel_to(now) do
            result = run_service

            expect(result).to eq(expected_result)
          end
        end
      end
    end

    context "when next_run_at is restricted by plan limit" do
      where(:worker_cron, :schedule_cron, :plan_limit, :now, :expected_result) do
        '*/5 * * * *' | '59 14 * * *' | daily_limit_of_24_runs   | Time.zone.local(2021, 5, 1, 15, 0)  | Time.zone.local(2021, 5, 2, 15, 0)
        '*/5 * * * *' | '*/1 * * * *' | daily_limit_of_24_runs   | Time.zone.local(2021, 5, 27, 11, 0) | Time.zone.local(2021, 5, 27, 12, 0)
        '*/5 * * * *' | '*/1 * * * *' | daily_limit_of_144_runs  | Time.zone.local(2021, 5, 27, 11, 0) | Time.zone.local(2021, 5, 27, 11, 10)
        '*/5 * * * *' | '*/1 * * * *' | (1.day / 7.minutes).to_i | Time.zone.local(2021, 5, 27, 11, 0) | Time.zone.local(2021, 5, 27, 11, 10)
      end

      with_them do
        it 'calculates the next_run_at based on next available limit' do
          travel_to(now) do
            result = run_service

            expect(result).to eq(expected_result)
          end
        end
      end
    end

    context "when next_run_at is restricted by worker's availability" do
      where(:worker_cron, :schedule_cron, :plan_limit, :now, :expected_result) do
        '0 1 2 3 *' | '0 1 * * *' | daily_limit_of_144_runs | Time.zone.local(2021, 3, 2, 1, 0) | Time.zone.local(2022, 3, 2, 1, 0)
      end

      with_them do
        it 'calculates the next_run_at using worker_cron' do
          travel_to(now) do
            result = run_service

            expect(result).to eq(expected_result)
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
