require 'spec_helper'

describe CycleAnalytics do
  let(:project) { create(:project, :repository) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  let(:issue) { create(:issue, project: project, created_at: 2.days.ago) }
  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }

  subject { described_class.new(project, from: from_date) }

  describe '#all_medians_per_stage' do
    before do
      allow_any_instance_of(Gitlab::ReferenceExtractor).to receive(:issues).and_return([issue])

      create_cycle(user, project, issue, mr, milestone, pipeline)
      deploy_master(user, project)
    end

    it 'returns every median for each stage for a specific project' do
      values = described_class::STAGES.each_with_object({}) do |stage_name, hsh|
        hsh[stage_name] = subject[stage_name].median.presence
      end

      expect(subject.all_medians_per_stage).to eq(values)
    end
  end
end
