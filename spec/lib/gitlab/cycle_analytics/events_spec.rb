require 'spec_helper'

describe Gitlab::CycleAnalytics::Events do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }

  subject { described_class.new(project: project, from: from_date) }

  before do
    setup(context)
  end

  describe '#issue_events' do
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    it 'has the total time' do
      expect(subject.issue_events.first['total_time']).to eq('2 days')
    end

    it 'has a title' do
      expect(subject.issue_events.first['title']).to eq(context.title)
    end

    it 'has an iid' do
      expect(subject.issue_events.first['iid']).to eq(context.iid.to_s)
    end

    it 'has a created_at timestamp' do
      expect(subject.issue_events.first['created_at']).to end_with('ago')
    end

    it "has the author's name" do
      expect(subject.issue_events.first['name']).to eq(context.author.name)
    end
  end

  describe '#plan_events' do
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    it 'has the first referenced commit' do
      expect(subject.plan_events.first['commit'].message).to eq('commit message')
    end

    it 'has the total time' do
      expect(subject.plan_events.first['total_time']).to eq('less than a minute')
    end
  end

  describe '#code_events' do
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    before do
      create_commit_referencing_issue(context)
    end

    it 'has the total time' do
      expect(subject.code_events.first['total_time']).to eq('less than a minute')
    end

    it 'has a title' do
      expect(subject.code_events.first['title']).to eq('Awesome merge_request')
    end

    it 'has an iid' do
      expect(subject.code_events.first['iid']).to eq(context.iid.to_s)
    end

    it 'has a created_at timestamp' do
      expect(subject.code_events.first['created_at']).to end_with('ago')
    end

    it "has the author's name" do
      expect(subject.code_events.first['name']).to eq(context.author.name)
    end
  end

  describe '#test_events' do
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }
    let(:merge_request) { MergeRequest.first }
    let!(:pipeline) { create(:ci_pipeline,
                             ref: merge_request.source_branch,
                             sha: merge_request.diff_head_sha,
                             project: context.project) }

    before do
      pipeline.run!
      pipeline.succeed!
    end

    it 'has the build info as a pipeline' do
      expect(subject.test_events.first['pipeline']).to eq(pipeline)
    end

    it 'has the total time' do
      expect(subject.test_events.first['total_time']).to eq('less than a minute')
    end
  end

  def setup(context)
    milestone = create(:milestone, project: project)
    context.update(milestone: milestone)
    create_merge_request_closing_issue(context)
  end
end
