require 'spec_helper'

describe 'cycle analytics events' do
  let(:project) { create(:project, :repository) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

  let(:events) do
    CycleAnalytics.new(project, { from: from_date, current_user: user })[stage].events
  end

  before do
    setup(context)
  end

  describe '#issue_events' do
    let(:stage) { :issue }

    it 'has the total time' do
      expect(events.first[:total_time]).not_to be_empty
    end

    it 'has a title' do
      expect(events.first[:title]).to eq(context.title)
    end

    it 'has the URL' do
      expect(events.first[:url]).not_to be_nil
    end

    it 'has an iid' do
      expect(events.first[:iid]).to eq(context.iid.to_s)
    end

    it 'has a created_at timestamp' do
      expect(events.first[:created_at]).to end_with('ago')
    end

    it "has the author's URL" do
      expect(events.first[:author][:web_url]).not_to be_nil
    end

    it "has the author's avatar URL" do
      expect(events.first[:author][:avatar_url]).not_to be_nil
    end

    it "has the author's name" do
      expect(events.first[:author][:name]).to eq(context.author.name)
    end
  end

  describe '#plan_events' do
    let(:stage) { :plan }

    it 'has a title' do
      expect(events.first[:title]).not_to be_nil
    end

    it 'has a sha short ID' do
      expect(events.first[:short_sha]).not_to be_nil
    end

    it 'has the URL' do
      expect(events.first[:commit_url]).not_to be_nil
    end

    it 'has the total time' do
      expect(events.first[:total_time]).not_to be_empty
    end

    it "has the author's URL" do
      expect(events.first[:author][:web_url]).not_to be_nil
    end

    it "has the author's avatar URL" do
      expect(events.first[:author][:avatar_url]).not_to be_nil
    end

    it "has the author's name" do
      expect(events.first[:author][:name]).not_to be_nil
    end
  end

  describe '#code_events' do
    let(:stage) { :code }

    before do
      create_commit_referencing_issue(context)
    end

    it 'has the total time' do
      expect(events.first[:total_time]).not_to be_empty
    end

    it 'has a title' do
      expect(events.first[:title]).to eq('Awesome merge_request')
    end

    it 'has an iid' do
      expect(events.first[:iid]).to eq(context.iid.to_s)
    end

    it 'has a created_at timestamp' do
      expect(events.first[:created_at]).to end_with('ago')
    end

    it "has the author's URL" do
      expect(events.first[:author][:web_url]).not_to be_nil
    end

    it "has the author's avatar URL" do
      expect(events.first[:author][:avatar_url]).not_to be_nil
    end

    it "has the author's name" do
      expect(events.first[:author][:name]).to eq(MergeRequest.first.author.name)
    end
  end

  describe '#test_events' do
    let(:stage) { :test }

    let(:merge_request) { MergeRequest.first }

    let!(:pipeline) do
      create(:ci_pipeline,
             ref: merge_request.source_branch,
             sha: merge_request.diff_head_sha,
             project: project,
             head_pipeline_of: merge_request)
    end

    before do
      create(:ci_build, :success, pipeline: pipeline, author: user)
      create(:ci_build, :success, pipeline: pipeline, author: user)

      pipeline.run!
      pipeline.succeed!
    end

    it 'has the name' do
      expect(events.first[:name]).not_to be_nil
    end

    it 'has the ID' do
      expect(events.first[:id]).not_to be_nil
    end

    it 'has the URL' do
      expect(events.first[:url]).not_to be_nil
    end

    it 'has the branch name' do
      expect(events.first[:branch]).not_to be_nil
    end

    it 'has the branch URL' do
      expect(events.first[:branch][:url]).not_to be_nil
    end

    it 'has the short SHA' do
      expect(events.first[:short_sha]).not_to be_nil
    end

    it 'has the commit URL' do
      expect(events.first[:commit_url]).not_to be_nil
    end

    it 'has the date' do
      expect(events.first[:date]).not_to be_nil
    end

    it 'has the total time' do
      expect(events.first[:total_time]).not_to be_empty
    end
  end

  describe '#review_events' do
    let(:stage) { :review }
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    it 'has the total time' do
      expect(events.first[:total_time]).not_to be_empty
    end

    it 'has a title' do
      expect(events.first[:title]).to eq('Awesome merge_request')
    end

    it 'has an iid' do
      expect(events.first[:iid]).to eq(context.iid.to_s)
    end

    it 'has the URL' do
      expect(events.first[:url]).not_to be_nil
    end

    it 'has a state' do
      expect(events.first[:state]).not_to be_nil
    end

    it 'has a created_at timestamp' do
      expect(events.first[:created_at]).not_to be_nil
    end

    it "has the author's URL" do
      expect(events.first[:author][:web_url]).not_to be_nil
    end

    it "has the author's avatar URL" do
      expect(events.first[:author][:avatar_url]).not_to be_nil
    end

    it "has the author's name" do
      expect(events.first[:author][:name]).to eq(MergeRequest.first.author.name)
    end
  end

  describe '#staging_events' do
    let(:stage) { :staging }
    let(:merge_request) { MergeRequest.first }

    let!(:pipeline) do
      create(:ci_pipeline,
             ref: merge_request.source_branch,
             sha: merge_request.diff_head_sha,
             project: project,
             head_pipeline_of: merge_request)
    end

    before do
      create(:ci_build, :success, pipeline: pipeline, author: user)
      create(:ci_build, :success, pipeline: pipeline, author: user)

      pipeline.run!
      pipeline.succeed!

      merge_merge_requests_closing_issue(user, project, context)
      deploy_master(user, project)
    end

    it 'has the name' do
      expect(events.first[:name]).not_to be_nil
    end

    it 'has the ID' do
      expect(events.first[:id]).not_to be_nil
    end

    it 'has the URL' do
      expect(events.first[:url]).not_to be_nil
    end

    it 'has the branch name' do
      expect(events.first[:branch]).not_to be_nil
    end

    it 'has the branch URL' do
      expect(events.first[:branch][:url]).not_to be_nil
    end

    it 'has the short SHA' do
      expect(events.first[:short_sha]).not_to be_nil
    end

    it 'has the commit URL' do
      expect(events.first[:commit_url]).not_to be_nil
    end

    it 'has the date' do
      expect(events.first[:date]).not_to be_nil
    end

    it 'has the total time' do
      expect(events.first[:total_time]).not_to be_empty
    end

    it "has the author's URL" do
      expect(events.first[:author][:web_url]).not_to be_nil
    end

    it "has the author's avatar URL" do
      expect(events.first[:author][:avatar_url]).not_to be_nil
    end

    it "has the author's name" do
      expect(events.first[:author][:name]).to eq(MergeRequest.first.author.name)
    end
  end

  describe '#production_events' do
    let(:stage) { :production }
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    before do
      merge_merge_requests_closing_issue(user, project, context)
      deploy_master(user, project)
    end

    it 'has the total time' do
      expect(events.first[:total_time]).not_to be_empty
    end

    it 'has a title' do
      expect(events.first[:title]).to eq(context.title)
    end

    it 'has the URL' do
      expect(events.first[:url]).not_to be_nil
    end

    it 'has an iid' do
      expect(events.first[:iid]).to eq(context.iid.to_s)
    end

    it 'has a created_at timestamp' do
      expect(events.first[:created_at]).to end_with('ago')
    end

    it "has the author's URL" do
      expect(events.first[:author][:web_url]).not_to be_nil
    end

    it "has the author's avatar URL" do
      expect(events.first[:author][:avatar_url]).not_to be_nil
    end

    it "has the author's name" do
      expect(events.first[:author][:name]).to eq(context.author.name)
    end
  end

  def setup(context)
    milestone = create(:milestone, project: project)
    context.update(milestone: milestone)
    mr = create_merge_request_closing_issue(user, project, context, commit_message: "References #{context.to_reference}")

    ProcessCommitWorker.new.perform(project.id, user.id, mr.commits.last.to_hash)
  end
end
