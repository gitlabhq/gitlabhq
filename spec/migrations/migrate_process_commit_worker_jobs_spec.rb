# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20161124141322_migrate_process_commit_worker_jobs.rb')

describe MigrateProcessCommitWorkerJobs do
  set(:project) { create(:project, :legacy_storage, :repository) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  set(:user) { create(:user) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let(:commit) do
    Gitlab::Git::Commit.last(project.repository.raw)
  end

  describe 'Project' do
    describe 'find_including_path' do
      it 'returns Project instances' do
        expect(described_class::Project.find_including_path(project.id))
          .to be_an_instance_of(described_class::Project)
      end

      it 'selects the full path for every Project' do
        migration_project = described_class::Project
          .find_including_path(project.id)

        expect(migration_project[:path_with_namespace])
          .to eq(project.full_path)
      end
    end

    describe '#repository' do
      it 'returns a mock implemention of ::Repository' do
        migration_project = described_class::Project
          .find_including_path(project.id)

        expect(migration_project.repository).to respond_to(:storage)
        expect(migration_project.repository).to respond_to(:gitaly_repository)
      end
    end
  end

  describe '#up', :clean_gitlab_redis_shared_state do
    let(:migration) { described_class.new }

    def job_count
      Sidekiq.redis { |r| r.llen('queue:process_commit') }
    end

    def pop_job
      JSON.parse(Sidekiq.redis { |r| r.lpop('queue:process_commit') })
    end

    before do
      Sidekiq.redis do |redis|
        job = JSON.dump(args: [project.id, user.id, commit.id])
        redis.lpush('queue:process_commit', job)
      end
    end

    it 'skips jobs using a project that no longer exists' do
      allow(described_class::Project).to receive(:find_including_path)
        .with(project.id)
        .and_return(nil)

      migration.up

      expect(job_count).to eq(0)
    end

    it 'skips jobs using commits that no longer exist' do
      allow_any_instance_of(Gitlab::GitalyClient::CommitService)
        .to receive(:find_commit)
        .with(commit.id)
        .and_return(nil)

      migration.up

      expect(job_count).to eq(0)
    end

    it 'inserts migrated jobs back into the queue' do
      migration.up

      expect(job_count).to eq(1)
    end

    it 'encodes data to UTF-8' do
      allow(commit).to receive(:body)
        .and_return('김치'.force_encoding('BINARY'))

      migration.up

      job = pop_job

      # We don't care so much about what is being stored, instead we just want
      # to make sure the encoding is right so that JSON encoding the data
      # doesn't produce any errors.
      expect(job['args'][2]['message'].encoding).to eq(Encoding::UTF_8)
    end

    context 'a migrated job' do
      let(:job) do
        migration.up
        pop_job
      end

      let(:commit_hash) do
        job['args'][2]
      end

      it 'includes the project ID' do
        expect(job['args'][0]).to eq(project.id)
      end

      it 'includes the user ID' do
        expect(job['args'][1]).to eq(user.id)
      end

      it 'includes the commit ID' do
        expect(commit_hash['id']).to eq(commit.id)
      end

      it 'includes the commit message' do
        expect(commit_hash['message']).to eq(commit.message)
      end

      it 'includes the parent IDs' do
        expect(commit_hash['parent_ids']).to eq(commit.parent_ids)
      end

      it 'includes the author date' do
        expect(commit_hash['authored_date']).to eq(commit.authored_date.to_s)
      end

      it 'includes the author name' do
        expect(commit_hash['author_name']).to eq(commit.author_name)
      end

      it 'includes the author Email' do
        expect(commit_hash['author_email']).to eq(commit.author_email)
      end

      it 'includes the commit date' do
        expect(commit_hash['committed_date']).to eq(commit.committed_date.to_s)
      end

      it 'includes the committer name' do
        expect(commit_hash['committer_name']).to eq(commit.committer_name)
      end

      it 'includes the committer Email' do
        expect(commit_hash['committer_email']).to eq(commit.committer_email)
      end
    end
  end

  describe '#down', :clean_gitlab_redis_shared_state do
    let(:migration) { described_class.new }

    def job_count
      Sidekiq.redis { |r| r.llen('queue:process_commit') }
    end

    before do
      Sidekiq.redis do |redis|
        job = JSON.dump(args: [project.id, user.id, commit.id])
        redis.lpush('queue:process_commit', job)

        migration.up
      end
    end

    it 'pushes migrated jobs back into the queue' do
      migration.down

      expect(job_count).to eq(1)
    end

    context 'a migrated job' do
      let(:job) do
        migration.down

        JSON.parse(Sidekiq.redis { |r| r.lpop('queue:process_commit') })
      end

      it 'includes the project ID' do
        expect(job['args'][0]).to eq(project.id)
      end

      it 'includes the user ID' do
        expect(job['args'][1]).to eq(user.id)
      end

      it 'includes the commit SHA' do
        expect(job['args'][2]).to eq(commit.id)
      end
    end
  end
end
