# frozen_string_literal: true

require 'spec_helper'

describe CycleAnalytics::GroupLevel do
  let(:group) { create(:group)}
  let(:project) { create(:project, :repository, namespace: group) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  let(:issue) { create(:issue, project: project, created_at: 2.days.ago) }
  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }

  subject { described_class.new(group: group, options: { from: from_date, current_user: user }) }

  describe '#permissions' do
    it 'returns true for all stages' do
      expect(subject.permissions.values.uniq).to eq([true])
    end
  end

  describe '#stats' do
    before do
      allow_next_instance_of(Gitlab::ReferenceExtractor) do |instance|
        allow(instance).to receive(:issues).and_return([issue])
      end

      create_cycle(user, project, issue, mr, milestone, pipeline)
      deploy_master(user, project)
    end

    it 'returns medians for each stage for a specific group' do
      expect(subject.no_stats?).to eq(false)
    end
  end

  describe '#summary' do
    before do
      create_cycle(user, project, issue, mr, milestone, pipeline)
      deploy_master(user, project)
    end

    it 'returns medians for each stage for a specific group' do
      expect(subject.summary.map { |summary| summary[:value] }).to contain_exactly(1, 1)
    end
  end
end
