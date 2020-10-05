# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::ObjectPool do
  include RepoHelpers

  let(:pool_repository) { create(:pool_repository) }
  let(:source_repository) { pool_repository.source_project.repository }

  subject { pool_repository.object_pool }

  describe '#storage' do
    it "equals the pool repository's shard name" do
      expect(subject.storage).not_to be_nil
      expect(subject.storage).to eq(pool_repository.shard_name)
    end
  end

  describe '#create' do
    before do
      subject.create # rubocop:disable Rails/SaveBang
    end

    context "when the pool doesn't exist yet" do
      it 'creates the pool' do
        expect(subject.exists?).to be(true)
      end
    end

    context 'when the pool already exists' do
      it 'raises an FailedPrecondition' do
        expect do
          subject.create # rubocop:disable Rails/SaveBang
        end.to raise_error(GRPC::FailedPrecondition)
      end
    end
  end

  describe '#exists?' do
    context "when the object pool doesn't exist" do
      it 'returns false' do
        expect(subject.exists?).to be(false)
      end
    end

    context 'when the object pool exists' do
      let(:pool) { create(:pool_repository, :ready) }

      subject { pool.object_pool }

      it 'returns true' do
        expect(subject.exists?).to be(true)
      end
    end
  end

  describe '#link' do
    let!(:pool_repository) { create(:pool_repository, :ready) }

    context 'when linked for the first time' do
      it 'sets a remote' do
        expect do
          subject.link(source_repository)
        end.not_to raise_error
      end
    end

    context 'when the remote is already set' do
      before do
        subject.link(source_repository)
      end

      it "doesn't raise an error" do
        expect do
          subject.link(source_repository)
        end.not_to raise_error
      end
    end
  end

  describe '#fetch' do
    let(:source_repository_path) { File.join(TestEnv.repos_path, source_repository.relative_path) }
    let(:source_repository_rugged) { Rugged::Repository.new(source_repository_path) }
    let(:commit_count) { source_repository.commit_count }

    context "when the object's pool repository exists" do
      it 'does not raise an error' do
        expect { subject.fetch }.not_to raise_error
      end
    end

    context "when the object's pool repository does not exist" do
      before do
        subject.delete
      end

      it "re-creates the object pool's repository" do
        subject.fetch

        expect(subject.repository.exists?).to be true
      end

      it 'does not raise an error' do
        expect { subject.fetch }.not_to raise_error
      end

      it 'fetches objects from the source repository' do
        new_commit_id = new_commit_edit_old_file(source_repository_rugged).oid

        expect(subject.repository.exists?).to be false

        subject.fetch

        expect(subject.repository.commit_count('refs/remotes/origin/master')).to eq(commit_count)
        expect(subject.repository.commit(new_commit_id).id).to eq(new_commit_id)
      end
    end
  end
end
