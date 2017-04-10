require 'spec_helper'

describe Gitlab::Cache::Ci::ProjectPipelineStatus do
  let(:project) { create(:project) }
  let(:pipeline_status) { described_class.new(project) }

  describe '.load_for_project' do
    it "loads the status" do
      expect_any_instance_of(described_class).to receive(:load_status)

      described_class.load_for_project(project)
    end
  end

  describe '.update_for_pipeline' do
    it 'refreshes the cache if nescessary' do
      pipeline = build_stubbed(:ci_pipeline, sha: '123456', status: 'success')
      fake_status = double
      expect(described_class).to receive(:new).
                                   with(pipeline.project, sha: '123456', status: 'success', ref: 'master').
                                   and_return(fake_status)

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
  end

  describe "#load_from_project" do
    let!(:pipeline) { create(:ci_pipeline, :success, project: project, sha: project.commit.sha) }

    it 'reads the status from the pipeline for the commit' do
      pipeline_status.load_from_project

      expect(pipeline_status.status).to eq('success')
      expect(pipeline_status.sha).to eq(project.commit.sha)
      expect(pipeline_status.ref).to eq(project.default_branch)
    end

    it "doesn't fail for an empty project" do
      status_for_empty_commit = described_class.new(create(:empty_project))

      status_for_empty_commit.load_status

      expect(status_for_empty_commit).to be_loaded
    end
  end

  describe "#store_in_cache", :redis do
    it "sets the object in redis" do
      pipeline_status.sha = '123456'
      pipeline_status.status = 'failed'

      pipeline_status.store_in_cache
      read_sha, read_status = Gitlab::Redis.with { |redis| redis.hmget("projects/#{project.id}/build_status", :sha, :status) }

      expect(read_sha).to eq('123456')
      expect(read_status).to eq('failed')
    end
  end

  describe '#store_in_cache_if_needed', :redis do
    it 'stores the state in the cache when the sha is the HEAD of the project' do
      create(:ci_pipeline, :success, project: project, sha: project.commit.sha)
      build_status = described_class.load_for_project(project)

      build_status.store_in_cache_if_needed
      sha, status, ref = Gitlab::Redis.with { |redis| redis.hmget("projects/#{project.id}/build_status", :sha, :status, :ref) }

      expect(sha).not_to be_nil
      expect(status).not_to be_nil
      expect(ref).not_to be_nil
    end

    it "doesn't store the status in redis when the sha is not the head of the project" do
      other_status = described_class.new(project, sha: "123456", status: "failed")

      other_status.store_in_cache_if_needed
      sha, status = Gitlab::Redis.with { |redis| redis.hmget("projects/#{project.id}/build_status", :sha, :status) }

      expect(sha).to be_nil
      expect(status).to be_nil
    end

    it "deletes the cache if the repository doesn't have a head commit" do
      empty_project = create(:empty_project)
      Gitlab::Redis.with { |redis| redis.mapped_hmset("projects/#{empty_project.id}/build_status", { sha: "sha", status: "pending", ref: 'master' }) }
      other_status = described_class.new(empty_project, sha: "123456", status: "failed")

      other_status.store_in_cache_if_needed
      sha, status, ref = Gitlab::Redis.with { |redis| redis.hmget("projects/#{empty_project.id}/build_status", :sha, :status, :ref) }

      expect(sha).to be_nil
      expect(status).to be_nil
      expect(ref).to be_nil
    end
  end

  describe "with a status in redis", :redis do
    let(:status) { 'success' }
    let(:sha) { '424d1b73bc0d3cb726eb7dc4ce17a4d48552f8c6' }

    before do
      Gitlab::Redis.with { |redis| redis.mapped_hmset("projects/#{project.id}/build_status", { sha: sha, status: status }) }
    end

    describe '#load_from_cache' do
      it 'reads the status from redis' do
        pipeline_status.load_from_cache

        expect(pipeline_status.sha).to eq(sha)
        expect(pipeline_status.status).to eq(status)
      end
    end

    describe '#has_cache?' do
      it 'knows the status is cached' do
        expect(pipeline_status.has_cache?).to be_truthy
      end
    end

    describe '#delete_from_cache' do
      it 'deletes values from redis'  do
        pipeline_status.delete_from_cache

        key_exists = Gitlab::Redis.with { |redis| redis.exists("projects/#{project.id}/build_status") }

        expect(key_exists).to be_falsy
      end
    end
  end
end
