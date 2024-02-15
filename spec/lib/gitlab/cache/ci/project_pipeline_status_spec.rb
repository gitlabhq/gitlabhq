# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::Ci::ProjectPipelineStatus, :clean_gitlab_redis_cache, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }

  let(:pipeline_status) { described_class.new(project) }
  let(:cache_key) { pipeline_status.cache_key }

  describe '.load_for_project' do
    it "loads the status" do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:load_status)
      end

      described_class.load_for_project(project)
    end
  end

  describe 'loading in batches' do
    describe '.load_in_batch_for_projects' do
      it 'loads pipeline_status on projects' do
        described_class.load_in_batch_for_projects([project])

        # Don't call the accessor that would lazy load the variable
        project_pipeline_status = project.instance_variable_get(:@pipeline_status)

        expect(project_pipeline_status).to be_a(described_class)
        expect(project_pipeline_status).to be_loaded
      end

      it 'loads 10 projects without hitting Gitaly call limit', :request_store do
        projects = Gitlab::GitalyClient.allow_n_plus_1_calls do
          (1..10).map { create(:project, :repository) }
        end
        Gitlab::GitalyClient.reset_counts

        expect { described_class.load_in_batch_for_projects(projects) }.not_to raise_error
      end
    end
  end

  describe '.update_for_pipeline' do
    it 'refreshes the cache if nescessary' do
      pipeline = build_stubbed(:ci_pipeline, sha: '123456', status: 'success', ref: 'master')
      fake_status = double
      expect(described_class).to receive(:new)
        .with(pipeline.project,
          pipeline_info: { sha: '123456', status: 'success', ref: 'master' }
        )
        .and_return(fake_status)

      expect(fake_status).to receive(:store_in_cache_if_needed)

      described_class.update_for_pipeline(pipeline)
    end
  end

  describe '#has_status?' do
    it "is false when the status wasn't loaded yet" do
      expect(pipeline_status.has_status?).to be_falsy
    end

    it 'is true when all status information was loaded' do
      fake_commit = double
      allow(fake_commit).to receive(:status).and_return('failed')
      allow(fake_commit).to receive(:sha).and_return('failed424d1b73bc0d3cb726eb7dc4ce17a4d48552f8c6')
      allow(pipeline_status).to receive(:commit).and_return(fake_commit)
      allow(pipeline_status).to receive(:has_cache?).and_return(false)

      pipeline_status.load_status

      expect(pipeline_status.has_status?).to be_truthy
    end
  end

  describe '#load_status' do
    describe 'gitaly call counts', :request_store do
      context 'not cached' do
        before do
          expect(pipeline_status).not_to be_has_cache
        end

        it 'makes a Gitaly call' do
          expect { pipeline_status.load_status }.to change { Gitlab::GitalyClient.get_request_count }.by(1)
        end
      end

      context 'cached' do
        before do
          described_class.load_in_batch_for_projects([project])

          expect(pipeline_status).to be_has_cache
        end

        it 'makes no Gitaly calls' do
          expect { pipeline_status.load_status }.to change { Gitlab::GitalyClient.get_request_count }.by(0)
        end
      end
    end

    it 'loads the status from the cache when there is one' do
      expect(pipeline_status).to receive(:has_cache?).and_return(true)
      expect(pipeline_status).to receive(:load_from_cache)

      pipeline_status.load_status
    end

    it 'loads the status from the project commit when there is no cache' do
      allow(pipeline_status).to receive(:has_cache?).and_return(false)

      expect(pipeline_status).to receive(:load_from_project)

      pipeline_status.load_status
    end

    it 'stores the status in the cache when it loading it from the project' do
      allow(pipeline_status).to receive(:has_cache?).and_return(false)
      allow(pipeline_status).to receive(:load_from_project)

      expect(pipeline_status).to receive(:store_in_cache)

      pipeline_status.load_status
    end

    it 'sets the state to loaded' do
      pipeline_status.load_status

      expect(pipeline_status).to be_loaded
    end

    it 'only loads the status once' do
      expect(pipeline_status).to receive(:has_cache?).and_return(true).exactly(1)
      expect(pipeline_status).to receive(:load_from_cache).exactly(1)

      pipeline_status.load_status
      pipeline_status.load_status
    end

    it 'handles Gitaly unavailable exceptions gracefully' do
      allow(pipeline_status).to receive(:commit).and_raise(GRPC::Unavailable)

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        an_instance_of(GRPC::Unavailable), project_id: project.id
      )
      expect { pipeline_status.load_status }.not_to raise_error
    end

    it 'handles Gitaly timeout exceptions gracefully' do
      allow(pipeline_status).to receive(:commit).and_raise(GRPC::DeadlineExceeded)

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        an_instance_of(GRPC::DeadlineExceeded), project_id: project.id
      )
      expect { pipeline_status.load_status }.not_to raise_error
    end
  end

  describe "#load_from_project", :clean_gitlab_redis_cache do
    let!(:pipeline) { create(:ci_pipeline, :success, project: project, sha: project.commit.sha) }

    it 'reads the status from the pipeline for the commit' do
      pipeline_status.load_from_project

      expect(pipeline_status.status).to eq('success')
      expect(pipeline_status.sha).to eq(project.commit.sha)
      expect(pipeline_status.ref).to eq(project.default_branch)
    end

    it "doesn't fail for an empty project" do
      status_for_empty_commit = described_class.new(create(:project))

      status_for_empty_commit.load_status

      expect(status_for_empty_commit.sha).to be_nil
      expect(status_for_empty_commit.status).to be_nil
      expect(status_for_empty_commit.ref).to be_nil
    end
  end

  describe "#store_in_cache", :clean_gitlab_redis_cache do
    it "sets the object in caching" do
      pipeline_status.sha = '123456'
      pipeline_status.status = 'failed'

      pipeline_status.store_in_cache
      read_sha, read_status = Gitlab::Redis::Cache.with { |redis| redis.hmget(cache_key, :sha, :status) }
      ttl = Gitlab::Redis::Cache.with { |redis| redis.ttl(cache_key) }

      expect(read_sha).to eq('123456')
      expect(read_status).to eq('failed')
      expect(ttl).to be > 0
    end
  end

  describe '#store_in_cache_if_needed', :clean_gitlab_redis_cache do
    it 'stores the state in the cache when the sha is the HEAD of the project' do
      create(:ci_pipeline, :success, project: project, sha: project.commit.sha)
      pipeline_status = described_class.load_for_project(project)

      pipeline_status.store_in_cache_if_needed
      sha, status, ref = Gitlab::Redis::Cache.with { |redis| redis.hmget(cache_key, :sha, :status, :ref) }

      expect(sha).not_to be_nil
      expect(status).not_to be_nil
      expect(ref).not_to be_nil
    end

    it "doesn't store the status in redis_cache when the sha is not the head of the project" do
      other_status = described_class.new(
        project,
        pipeline_info: { sha: "123456", status: "failed" }
      )

      other_status.store_in_cache_if_needed
      sha, status = Gitlab::Redis::Cache.with { |redis| redis.hmget(cache_key, :sha, :status) }

      expect(sha).to be_nil
      expect(status).to be_nil
    end

    it "deletes the cache if the repository doesn't have a head commit" do
      empty_project = create(:project)
      Gitlab::Redis::Cache.with do |redis|
        redis.mapped_hmset(cache_key, { sha: 'sha', status: 'pending', ref: 'master' })
      end

      other_status = described_class.new(empty_project, pipeline_info: { sha: "123456", status: "failed" })

      other_status.store_in_cache_if_needed
      sha, status, ref = Gitlab::Redis::Cache.with { |redis| redis.hmget("projects/#{empty_project.id}/pipeline_status", :sha, :status, :ref) }

      expect(sha).to be_nil
      expect(status).to be_nil
      expect(ref).to be_nil
    end
  end

  describe "with a status in caching", :clean_gitlab_redis_cache do
    let(:status) { 'success' }
    let(:sha) { '424d1b73bc0d3cb726eb7dc4ce17a4d48552f8c6' }
    let(:ref) { 'master' }

    before do
      Gitlab::Redis::Cache.with do |redis|
        redis.mapped_hmset(cache_key, { sha: sha, status: status, ref: ref })
      end
    end

    describe '#load_from_cache' do
      subject { pipeline_status.load_from_cache }

      it 'reads the status from redis_cache' do
        subject

        expect(pipeline_status.sha).to eq(sha)
        expect(pipeline_status.status).to eq(status)
        expect(pipeline_status.ref).to eq(ref)
      end

      it 'refreshes ttl' do
        subject

        ttl = Gitlab::Redis::Cache.with { |redis| redis.ttl(cache_key) }

        expect(ttl).to be > 0
      end

      context 'when status is empty string' do
        before do
          Gitlab::Redis::Cache.with do |redis|
            redis.mapped_hmset(cache_key, { sha: sha, status: '', ref: ref })
          end
        end

        it 'reads the status as nil' do
          subject

          expect(pipeline_status.status).to eq(nil)
        end
      end
    end

    describe '#has_cache?' do
      it 'knows the status is cached' do
        expect(pipeline_status.has_cache?).to be_truthy
      end
    end

    describe '#delete_from_cache' do
      it 'deletes values from redis_cache' do
        pipeline_status.delete_from_cache

        key_exists = Gitlab::Redis::Cache.with { |redis| redis.exists?(cache_key) }

        expect(key_exists).to be_falsy
      end
    end
  end
end
