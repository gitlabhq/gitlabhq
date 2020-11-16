# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'value stream analytics events', :aggregate_failures do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, :admin) }
  let(:from_date) { 10.days.ago }
  let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

  let(:events) do
    CycleAnalytics::ProjectLevel
      .new(project, options: { from: from_date, current_user: user })[stage]
      .events
  end

  let(:event) { events.first }

  before do
    setup(context)
  end

  describe '#issue_events' do
    let(:stage) { :issue }

    it 'has correct attributes' do
      expect(event[:total_time]).not_to be_empty
      expect(event[:title]).to eq(context.title)
      expect(event[:url]).not_to be_nil
      expect(event[:iid]).to eq(context.iid.to_s)
      expect(event[:created_at]).to end_with('ago')
      expect(event[:author][:web_url]).not_to be_nil
      expect(event[:author][:avatar_url]).not_to be_nil
      expect(event[:author][:name]).to eq(context.author.name)
    end
  end

  describe '#plan_events' do
    let(:stage) { :plan }

    before do
      create_commit_referencing_issue(context)
    end

    it 'has correct attributes' do
      expect(event[:total_time]).not_to be_empty
      expect(event[:title]).to eq(context.title)
      expect(event[:url]).not_to be_nil
      expect(event[:iid]).to eq(context.iid.to_s)
      expect(event[:created_at]).to end_with('ago')
      expect(event[:author][:web_url]).not_to be_nil
      expect(event[:author][:avatar_url]).not_to be_nil
      expect(event[:author][:name]).to eq(context.author.name)
    end
  end

  describe '#code_events' do
    let(:stage) { :code }
    let!(:merge_request) { MergeRequest.first }

    before do
      create_commit_referencing_issue(context)
    end

    it 'has correct attributes' do
      expect(event[:total_time]).not_to be_empty
      expect(event[:title]).to eq('Awesome merge_request')
      expect(event[:iid]).to eq(context.iid.to_s)
      expect(event[:created_at]).to end_with('ago')
      expect(event[:author][:web_url]).not_to be_nil
      expect(event[:author][:avatar_url]).not_to be_nil
      expect(event[:author][:name]).to eq(MergeRequest.first.author.name)
    end
  end

  describe '#test_events', :sidekiq_might_not_need_inline do
    let(:stage) { :test }

    let(:merge_request) { MergeRequest.first }
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

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
    end

    it 'has correct attributes' do
      expect(event[:name]).not_to be_nil
      expect(event[:id]).not_to be_nil
      expect(event[:url]).not_to be_nil
      expect(event[:branch]).not_to be_nil
      expect(event[:branch][:url]).not_to be_nil
      expect(event[:short_sha]).not_to be_nil
      expect(event[:commit_url]).not_to be_nil
      expect(event[:date]).not_to be_nil
      expect(event[:total_time]).not_to be_empty
    end
  end

  describe '#review_events' do
    let(:stage) { :review }
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    before do
      merge_merge_requests_closing_issue(user, project, context)
    end

    it 'has correct attributes' do
      expect(event[:total_time]).not_to be_empty
      expect(event[:title]).to eq('Awesome merge_request')
      expect(event[:iid]).to eq(context.iid.to_s)
      expect(event[:url]).not_to be_nil
      expect(event[:state]).not_to be_nil
      expect(event[:created_at]).not_to be_nil
      expect(event[:author][:web_url]).not_to be_nil
      expect(event[:author][:avatar_url]).not_to be_nil
      expect(event[:author][:name]).to eq(MergeRequest.first.author.name)
    end
  end

  describe '#staging_events', :sidekiq_might_not_need_inline do
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

    it 'has correct attributes' do
      expect(event[:name]).not_to be_nil
      expect(event[:id]).not_to be_nil
      expect(event[:url]).not_to be_nil
      expect(event[:branch]).not_to be_nil
      expect(event[:branch][:url]).not_to be_nil
      expect(event[:short_sha]).not_to be_nil
      expect(event[:commit_url]).not_to be_nil
      expect(event[:date]).not_to be_nil
      expect(event[:total_time]).not_to be_empty
      expect(event[:author][:web_url]).not_to be_nil
      expect(event[:author][:avatar_url]).not_to be_nil
      expect(event[:author][:name]).to eq(MergeRequest.first.author.name)
    end
  end

  def setup(context)
    milestone = create(:milestone, project: project)
    context.update!(milestone: milestone)
    mr = create_merge_request_closing_issue(user, project, context, commit_message: "References #{context.to_reference}")

    ProcessCommitWorker.new.perform(project.id, user.id, mr.commits.last.to_hash)
  end
end
