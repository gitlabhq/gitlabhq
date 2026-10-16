# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, :clean_gitlab_redis_shared_state, :sidekiq_inline,
  feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }

  let(:ref) { project.default_branch }

  let(:config) do
    <<~YAML
      build:
        script: sleep 60
        interruptible: true
    YAML
  end

  before do
    stub_ci_pipeline_yaml_file(config)
  end

  def create_pipeline(source = :push)
    described_class
      .new(project, user, ref: ref)
      .execute(source)
      .payload
  end

  def cache
    Gitlab::Ci::RedundantPipelines::CandidateCache.for(project_id: project.id, ref: ref)
  end

  def push_commit
    project.repository.create_file(
      user, "file-#{SecureRandom.hex(8)}", 'content',
      message: 'New commit', branch_name: ref
    )
  end

  it 'cancels the pipeline of an earlier commit' do
    previous = create_pipeline

    push_commit

    create_pipeline

    expect(previous.reload).to be_canceled
  end

  # A pipeline for the commit the ref points at goes back in the cache.
  context 'when pipelines are run for the commit the ref points at' do
    it 'cancels all of them on a newer commit' do
      previous = create_pipeline
      same_commit = create_pipeline(:web)

      push_commit

      create_pipeline

      expect(previous.reload).to be_canceled
      expect(same_commit.reload).to be_canceled
    end
  end

  it 'does not search p_ci_pipelines for the pipelines to cancel' do
    create_pipeline

    push_commit

    recorder = ActiveRecord::QueryRecorder.new { create_pipeline }

    expect(recorder.log.grep(/FROM "p_ci_pipelines".*"ref" =.*IN \('created'/)).to be_empty
  end

  context 'when the pipeline started a child pipeline' do
    it 'cancels the child of the pipeline of an earlier commit' do
      previous = create_pipeline
      child = create(:ci_pipeline, :running, child_of: previous)
      child_job = create(:ci_build, :interruptible, :running, pipeline: child)

      push_commit

      create_pipeline

      expect(child_job.reload).to be_canceled
    end

    it 'cancels a child that outlived its parent' do
      previous = create_pipeline
      child = create(:ci_pipeline, :running, child_of: previous)
      child_job = create(:ci_build, :interruptible, :running, pipeline: child)
      previous.succeed!

      push_commit

      create_pipeline

      expect(child_job.reload).to be_canceled
    end

    it 'leaves a child configured never to be auto-canceled alone' do
      previous = create_pipeline
      child = create(:ci_pipeline, :running, child_of: previous)
      child.create_pipeline_metadata!(project: project, auto_cancel_on_new_commit: 'none')
      child_job = create(:ci_build, :interruptible, :running, pipeline: child)

      push_commit

      create_pipeline

      expect(child_job.reload).to be_running
      expect(previous.reload).to be_canceled
    end

    it 'leaves a child whose non-interruptible job has started alone' do
      previous = create_pipeline
      child = create(:ci_pipeline, :running, child_of: previous)
      child_job = create(:ci_build, :pending, pipeline: child)
      child_job.run!

      push_commit

      create_pipeline

      expect(child_job.reload).to be_running
      expect(previous.reload).to be_canceled
    end
  end

  context 'when a non-interruptible job has started' do
    let(:config) do
      <<~YAML
        build:
          script: sleep 60
      YAML
    end

    it 'keeps the pipeline out of reach of auto-cancellation' do
      previous = create_pipeline
      previous.builds.first.run!

      push_commit

      create_pipeline

      expect(previous.reload).not_to be_canceled
    end

    it 'keeps the pipeline out of reach before the column is written' do
      allow(Ci::RedundantPipelines::ProtectPipelineWorker).to receive(:perform_async)

      previous = create_pipeline
      previous.builds.first.run!

      push_commit

      create_pipeline

      expect(previous.reload).not_to be_canceled
    end
  end

  context 'when a finished pipeline is retried' do
    it 'cancels the retried pipeline on a newer commit' do
      previous = create_pipeline
      previous.builds.each { |build| build.drop!(:script_failure) }

      Ci::RetryPipelineService.new(project, user).execute(previous)

      push_commit

      create_pipeline

      expect(previous.reload).to be_canceled
    end
  end

  # Playing a job does not start the pipeline, so the cache keeps its first entry.
  context 'when a manual job of a finished pipeline is played' do
    let(:config) do
      <<~YAML
        build:
          script: sleep 60
          interruptible: true
        deploy:
          script: sleep 60
          interruptible: true
          when: manual
      YAML
    end

    it 'cancels the played job on a newer commit' do
      previous = create_pipeline
      previous.builds.find_by_name('build').success!
      manual = previous.builds.find_by_name('deploy')

      Ci::PlayBuildService.new(current_user: user, build: manual).execute

      expect(previous.reload).to be_running

      push_commit

      create_pipeline

      expect(manual.reload).to be_canceled
      expect(previous.reload.auto_canceled_by_id).to be_present
    end
  end

  context 'when the cache is gone' do
    it 'cancels nothing' do
      previous = create_pipeline

      Gitlab::Redis::SharedState.with(&:flushdb)

      push_commit

      create_pipeline

      expect(previous.reload).not_to be_canceled
    end
  end

  # The cache fills for days before cancellation reads from it.
  context 'when the pipelines are cached but cancellation does not read the cache yet' do
    before do
      stub_feature_flags(ci_redundant_pipeline_cancel_from_cache: false)
    end

    it 'still cancels the pipeline of an earlier commit' do
      previous = create_pipeline

      push_commit

      create_pipeline

      expect(previous.reload).to be_canceled
    end
  end

  # Only the creation chain asks for the cancellation, so no flag state asks twice.
  describe 'asking for the cancellation' do
    where(:candidates_cache, :cancel_from_cache) do
      false | false
      true  | false
      true  | true
      false | true
    end

    with_them do
      before do
        stub_feature_flags(
          ci_redundant_pipeline_candidates_cache: candidates_cache,
          ci_redundant_pipeline_cancel_from_cache: cancel_from_cache
        )
      end

      it 'is asked for once' do
        expect(Ci::CancelRedundantPipelinesWorker).to receive(:perform_async).once.and_call_original

        create_pipeline
      end
    end
  end
end
