require 'spec_helper'

describe Gitlab::CycleAnalytics::Events do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

  subject { described_class.new(project: project, from: from_date) }

  before do
    setup(context)
  end

  describe '#issue_events' do
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

    it "has the author's URL" do
      expect(subject.issue_events.first['author_profile_url']).not_to be_nil
    end

    it "has the author's avatar URL" do
      expect(subject.issue_events.first['author_avatar_url']).not_to be_nil
    end

    it "has the author's name" do
      expect(subject.issue_events.first['author_name']).to eq(context.author.name)
    end
  end

  describe '#plan_events' do
    it 'has a title' do
      expect(subject.plan_events.first['title']).not_to be_nil
    end

    it 'has a sha short ID' do
      expect(subject.plan_events.first['sha']).not_to be_nil
    end

    it 'has the total time' do
      expect(subject.plan_events.first['total_time']).to eq('less than a minute')
    end

    it "has the author's URL" do
      expect(subject.plan_events.first['author_profile_url']).not_to be_nil
    end

    it "has the author's avatar URL" do
      expect(subject.plan_events.first['author_avatar_url']).not_to be_nil
    end

    it "has the author's name" do
      expect(subject.plan_events.first['author_name']).not_to be_nil
    end
  end

  describe '#code_events' do
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

    it "has the author's URL" do
      expect(subject.code_events.first['author_profile_url']).not_to be_nil
    end

    it "has the author's avatar URL" do
      expect(subject.code_events.first['author_avatar_url']).not_to be_nil
    end

    it "has the author's name" do
      expect(subject.code_events.first['author_name']).to eq(context.author.name)
    end
  end

  describe '#test_events' do
    let(:merge_request) { MergeRequest.first }
    let!(:pipeline) do
      create(:ci_pipeline,
             ref: merge_request.source_branch,
             sha: merge_request.diff_head_sha,
             project: context.project)
    end

    before do
      create(:ci_build, pipeline: pipeline, status: :success)
      create(:ci_build, pipeline: pipeline, status: :success)

      pipeline.run!
      pipeline.succeed!
    end

    it 'has the name' do
      expect(subject.test_events.first['name']).not_to be_nil
    end

    it 'has the ID' do
      expect(subject.test_events.first['id']).not_to be_nil
    end

    it 'has the URL' do
      expect(subject.test_events.first['url']).not_to be_nil
    end

    it 'has the branch name' do
      expect(subject.test_events.first['branch']).not_to be_nil
    end

    it 'has the branch URL' do
      expect(subject.test_events.first['branch_url']).not_to be_nil
    end

    it 'has the short SHA' do
      expect(subject.test_events.first['sha']).not_to be_nil
    end

    it 'has the commit URL' do
      expect(subject.test_events.first['commit_url']).not_to be_nil
    end

    it 'has the date' do
      expect(subject.test_events.first['date']).not_to be_nil
    end

    it 'has the total time' do
      expect(subject.test_events.first['total_time']).not_to be_nil
    end
  end

  describe '#review_events' do
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    it 'has the total time' do
      expect(subject.review_events.first['total_time']).to eq('less than a minute')
    end

    it 'has a title' do
      expect(subject.review_events.first['title']).to eq('Awesome merge_request')
    end

    it 'has an iid' do
      expect(subject.review_events.first['iid']).to eq(context.iid.to_s)
    end

    it 'has a created_at timestamp' do
      expect(subject.review_events.first['created_at']).to end_with('ago')
    end

    it "has the author's email" do
      expect(subject.review_events.first['email']).to eq(MergeRequest.first.author.email)
    end

    it "has the author's name" do
      expect(subject.review_events.first['name']).to eq(MergeRequest.first.author.name)
    end
  end

  describe '#staging_events' do
    let(:merge_request) { MergeRequest.first }
    let!(:pipeline) do
      create(:ci_pipeline,
             ref: merge_request.source_branch,
             sha: merge_request.diff_head_sha,
             project: context.project)
    end

    before do
      pipeline.run!
      pipeline.succeed!

      merge_merge_requests_closing_issue(context)
      deploy_master
    end

    it 'has the build info as a pipeline' do
      expect(subject.staging_events.first['pipeline']).to eq(pipeline)
    end

    it 'has the total time' do
      expect(subject.staging_events.first['total_time']).to eq('less than a minute')
    end
  end

  describe '#production_events' do
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    before do
      merge_merge_requests_closing_issue(context)
      deploy_master
    end

    it 'has the total time' do
      expect(subject.production_events.first['total_time']).to eq('2 days')
    end

    it 'has a title' do
      expect(subject.production_events.first['title']).to eq(context.title)
    end

    it 'has an iid' do
      expect(subject.production_events.first['iid']).to eq(context.iid.to_s)
    end

    it 'has a created_at timestamp' do
      expect(subject.production_events.first['created_at']).to end_with('ago')
    end

    it "has the author's email" do
      expect(subject.production_events.first['email']).to eq(context.author.email)
    end

    it "has the author's name" do
      expect(subject.production_events.first['name']).to eq(context.author.name)
    end
  end

  def setup(context)
    milestone = create(:milestone, project: project)
    context.update(milestone: milestone)
    create_merge_request_closing_issue(context)
  end
end
