require 'spec_helper'

describe CommitCollection do
  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit("c1c67abbaf91f624347bb3ae96eabe3a1b742478") }

  describe '#each' do
    it 'yields every commit' do
      collection = described_class.new(project, [commit])

      expect { |b| collection.each(&b) }.to yield_with_args(commit)
    end
  end

  describe '.authors' do
    it 'returns a relation of users when users are found' do
      user = create(:user, email: commit.author_email.upcase)
      collection = described_class.new(project, [commit])

      expect(collection.authors).to contain_exactly(user)
    end

    it 'returns empty array when authors cannot be found' do
      collection = described_class.new(project, [commit])

      expect(collection.authors).to be_empty
    end

    it 'excludes authors of merge commits' do
      commit = project.commit("60ecb67744cb56576c30214ff52294f8ce2def98")
      create(:user, email: commit.author_email.upcase)
      collection = described_class.new(project, [commit])

      expect(collection.authors).to be_empty
    end
  end

  describe '#without_merge_commits' do
    it 'returns all commits except merge commits' do
      merge_commit = project.commit("60ecb67744cb56576c30214ff52294f8ce2def98")
      expect(merge_commit).to receive(:merge_commit?).and_return(true)

      collection = described_class.new(project, [
        commit,
        merge_commit
      ])

      expect(collection.without_merge_commits).to contain_exactly(commit)
    end
  end

  describe 'enrichment methods' do
    let(:gitaly_commit) { commit }
    let(:hash_commit) { Commit.from_hash(gitaly_commit.to_hash, project) }

    describe '#unenriched' do
      it 'returns all commits that are not backed by gitaly data' do
        collection = described_class.new(project, [gitaly_commit, hash_commit])

        expect(collection.unenriched).to contain_exactly(hash_commit)
      end
    end

    describe '#fully_enriched?' do
      it 'returns true when all commits are backed by gitaly data' do
        collection = described_class.new(project, [gitaly_commit, gitaly_commit])

        expect(collection.fully_enriched?).to eq(true)
      end

      it 'returns false when any commits are not backed by gitaly data' do
        collection = described_class.new(project, [gitaly_commit, hash_commit])

        expect(collection.fully_enriched?).to eq(false)
      end

      it 'returns true when the collection is empty' do
        collection = described_class.new(project, [])

        expect(collection.fully_enriched?).to eq(true)
      end
    end

    describe '#enrich!' do
      it 'replaces commits in the collection with those backed by gitaly data' do
        collection = described_class.new(project, [hash_commit])

        collection.enrich!

        new_commit = collection.commits.first
        expect(new_commit.id).to eq(hash_commit.id)
        expect(hash_commit.gitaly_commit?).to eq(false)
        expect(new_commit.gitaly_commit?).to eq(true)
      end

      it 'maintains the original order of the commits' do
        gitaly_commits = [gitaly_commit] * 3
        hash_commits = [hash_commit] * 3
        # Interleave the gitaly and hash commits together
        original_commits = gitaly_commits.zip(hash_commits).flatten
        collection = described_class.new(project, original_commits)

        collection.enrich!

        original_commits.each_with_index do |original_commit, i|
          new_commit = collection.commits[i]
          expect(original_commit.id).to eq(new_commit.id)
        end
      end

      it 'fetches data if there are unenriched commits' do
        collection = described_class.new(project, [hash_commit])

        expect(Commit).to receive(:lazy).exactly(:once)

        collection.enrich!
      end

      it 'does not fetch data if all commits are enriched' do
        collection = described_class.new(project, [gitaly_commit])

        expect(Commit).not_to receive(:lazy)

        collection.enrich!
      end
    end
  end

  describe '#with_pipeline_status' do
    it 'sets the pipeline status for every commit so no additional queries are necessary' do
      create(
        :ci_empty_pipeline,
        ref: 'master',
        sha: commit.id,
        status: 'success',
        project: project
      )

      collection = described_class.new(project, [commit])
      collection.with_pipeline_status

      recorder = ActiveRecord::QueryRecorder.new do
        expect(commit.status).to eq('success')
      end

      expect(recorder.count).to be_zero
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true when the underlying Array responds to the message' do
      collection = described_class.new(project, [])

      expect(collection.respond_to?(:last)).to eq(true)
    end

    it 'returns false when the underlying Array does not respond to the message' do
      collection = described_class.new(project, [])

      expect(collection.respond_to?(:foo)).to eq(false)
    end
  end

  describe '#method_missing' do
    it 'delegates undefined methods to the underlying Array' do
      collection = described_class.new(project, [commit])

      expect(collection.length).to eq(1)
      expect(collection.last).to eq(commit)
      expect(collection).not_to be_empty
    end
  end
end
