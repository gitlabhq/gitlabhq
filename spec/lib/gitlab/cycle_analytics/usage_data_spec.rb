# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CycleAnalytics::UsageData do
  describe '#to_json' do
    before do
      # Since git commits only have second precision, round up to the
      # nearest second to ensure we have accurate median and standard
      # deviation calculations.
      current_time = Time.at(Time.now.to_i)

      Timecop.freeze(current_time) do
        user = create(:user, :admin)
        projects = create_list(:project, 2, :repository)

        projects.each_with_index do |project, time|
          issue = create(:issue, project: project, created_at: (time + 1).hour.ago)

          allow_next_instance_of(Gitlab::ReferenceExtractor) do |instance|
            allow(instance).to receive(:issues).and_return([issue])
          end

          milestone = create(:milestone, project: project)
          mr = create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}")
          pipeline = create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr)

          create_cycle(user, project, issue, mr, milestone, pipeline)
          deploy_master(user, project, environment: 'staging')
          deploy_master(user, project)
        end
      end
    end

    context 'a valid usage data result' do
      let(:expect_values_per_stage) do
        {
          issue: {
            average: 5400,
            sd: 2545,
            missing: 0
          },
          plan: {
            average: 1,
            sd: 0,
            missing: 0
          },
          code: {
            average: nil,
            sd: 0,
            missing: 2
          },
          test: {
            average: nil,
            sd: 0,
            missing: 2
          },
          review: {
            average: 0,
            sd: 0,
            missing: 0
          },
          staging: {
            average: 0,
            sd: 0,
            missing: 0
          },
          production: {
            average: 5400,
            sd: 2545,
            missing: 0
          }
        }
      end

      it 'returns the aggregated usage data of every selected project', :sidekiq_might_not_need_inline do
        result = subject.to_json

        expect(result).to have_key(:avg_cycle_analytics)

        CycleAnalytics::LevelBase::STAGES.each do |stage|
          expect(result[:avg_cycle_analytics]).to have_key(stage)

          stage_values    = result[:avg_cycle_analytics][stage]
          expected_values = expect_values_per_stage[stage]

          expected_values.each_pair do |op, value|
            expect(stage_values).to have_key(op)
            expect(stage_values[op]).to eq(value)
          end
        end
      end
    end
  end
end
