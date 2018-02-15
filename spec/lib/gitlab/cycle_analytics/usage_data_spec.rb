require 'spec_helper'

describe Gitlab::CycleAnalytics::UsageData do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, :admin) }
  let(:issue) { create(:issue, project: project, created_at: 2.days.ago) }
  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }

  subject { described_class.new([project]) }

  describe '#to_json' do
    before do
      allow_any_instance_of(Gitlab::ReferenceExtractor).to receive(:issues).and_return([issue])

      create_cycle(user, project, issue, mr, milestone, pipeline)
      deploy_master
    end

    it 'returns the aggregated usage data of every selected project' do
      result = subject.to_json
      avg_cycle_analytics = result[:avg_cycle_analytics]

      expect(result).to have_key(:avg_cycle_analytics)
      CycleAnalytics::STAGES.each do |stage_name|
        stage_values = avg_cycle_analytics[stage_name]

        expect(avg_cycle_analytics).to have_key(stage_name)
        expect(stage_values).to have_key(:average)
        expect(stage_values).to have_key(:sd)
        expect(stage_values).to have_key(:missing)
      end
    end
  end
end
