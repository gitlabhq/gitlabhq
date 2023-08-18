# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CommitWithPipeline, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:commit) { described_class.new(project.commit) }

  describe '#last_pipeline' do
    let!(:first_pipeline) do
      create(:ci_empty_pipeline,
        project: project,
        sha: commit.sha,
        status: 'success')
    end

    let!(:second_pipeline) do
      create(:ci_empty_pipeline,
        project: project,
        sha: commit.sha,
        status: 'success')
    end

    it 'returns last pipeline' do
      expect(commit.last_pipeline).to eq second_pipeline
    end
  end

  describe '#lazy_latest_pipeline' do
    let_it_be(:other_project) { create(:project, :repository) }

    let_it_be(:commits_with_pipelines) do
      [
        described_class.new(Commit.new(RepoHelpers.sample_commit, project)),
        described_class.new(Commit.new(RepoHelpers.another_sample_commit, project)),
        described_class.new(Commit.new(RepoHelpers.sample_big_commit, project)),
        described_class.new(Commit.new(RepoHelpers.sample_commit, other_project))
      ]
    end

    let_it_be(:commits) do
      commits_with_pipelines + [
        described_class.new(Commit.new(RepoHelpers.another_sample_commit, other_project))
      ]
    end

    before_all do
      commits_with_pipelines.each do |commit|
        create(:ci_empty_pipeline, project: commit.project, sha: commit.sha)
      end
    end

    it 'returns the correct pipelines with only 1 SQL query per project', :aggregate_failures do
      recorder = ActiveRecord::QueryRecorder.new do
        # batch commits
        commits.each(&:lazy_latest_pipeline)

        # assert result correctness
        commits_with_pipelines.each do |commit|
          expect(commit.lazy_latest_pipeline.project).to eq(commit.project)
        end

        expect(commits.last.lazy_latest_pipeline&.itself).to be_nil
      end

      expect(recorder.count).to eq(2)
    end
  end

  describe '#latest_pipeline' do
    let(:pipeline) { double }

    shared_examples_for 'fetching latest pipeline' do |ref|
      it 'returns the latest pipeline for the project' do
        if ref
          expect(commit)
            .to receive(:latest_pipeline_for_project)
            .with(ref, project)
            .and_return(pipeline)
        else
          expect(commit)
            .to receive(:lazy_latest_pipeline)
            .and_return(pipeline)
        end

        expect(result).to eq(pipeline)
      end

      it "returns the memoized pipeline for the key of #{ref}" do
        commit.set_latest_pipeline_for_ref(ref, pipeline)

        expect(commit)
          .not_to receive(:latest_pipeline_for_project)

        expect(result).to eq(pipeline)
      end
    end

    context 'without ref argument' do
      let(:result) { commit.latest_pipeline }

      it_behaves_like 'fetching latest pipeline', nil
    end

    context 'when a particular ref is specified' do
      let(:result) { commit.latest_pipeline('master') }

      it_behaves_like 'fetching latest pipeline', 'master'
    end
  end

  describe '#latest_pipeline_for_project' do
    let(:project_pipelines) { double }
    let(:pipeline_project) { double }
    let(:pipeline) { double }
    let(:ref) { 'master' }
    let(:result) { commit.latest_pipeline_for_project(ref, pipeline_project) }

    before do
      allow(pipeline_project).to receive(:ci_pipelines).and_return(project_pipelines)
    end

    it 'returns the latest pipeline of the commit for the given ref and project' do
      expect(project_pipelines)
        .to receive(:latest_pipeline_per_commit)
        .with(commit.id, ref)
        .and_return(commit.id => pipeline)

      expect(result).to eq(pipeline)
    end
  end

  describe '#set_latest_pipeline_for_ref' do
    let(:pipeline) { double }

    it 'sets the latest pipeline for a given reference' do
      commit.set_latest_pipeline_for_ref('master', pipeline)

      expect(commit.latest_pipeline('master')).to eq(pipeline)
    end
  end

  describe "#status" do
    it 'returns the status of the latest pipeline for the given ref' do
      expect(commit)
        .to receive(:latest_pipeline)
        .with('master')
        .and_return(double(status: 'success'))

      expect(commit.status('master')).to eq('success')
    end

    it 'returns nil when latest pipeline is not present for the given ref' do
      expect(commit)
        .to receive(:latest_pipeline)
        .with('master')
        .and_return(nil)

      expect(commit.status('master')).to eq(nil)
    end

    it 'returns the status of the latest pipeline when no ref is given' do
      expect(commit)
        .to receive(:latest_pipeline)
        .with(nil)
        .and_return(double(status: 'success'))

      expect(commit.status).to eq('success')
    end
  end
end
