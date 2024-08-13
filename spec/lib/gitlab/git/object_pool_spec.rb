# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::ObjectPool, feature_category: :source_code_management do
  let(:pool_repository) { create(:pool_repository) }
  let(:source_repository) { pool_repository.source_project.repository }

  subject { pool_repository.object_pool }

  describe '#storage' do
    it "equals the pool repository's shard name" do
      expect(subject.storage).not_to be_nil
      expect(subject.storage).to eq(pool_repository.shard_name)
    end
  end

  describe '.init_from_gitaly' do
    let(:gitaly_object_pool) { Gitaly::ObjectPool.new(repository: repository) }
    let(:repository) do
      Gitaly::Repository.new(
        storage_name: 'default',
        relative_path: '@pools/ef/2d/ef2d127d',
        gl_project_path: ''
      )
    end

    it 'returns an object pool object' do
      object_pool = described_class.init_from_gitaly(gitaly_object_pool, source_repository)

      expect(object_pool).to be_kind_of(described_class)
      expect(object_pool).to have_attributes(
        storage: repository.storage_name,
        relative_path: repository.relative_path,
        source_repository: source_repository,
        gl_project_path: repository.gl_project_path
      )
    end
  end

  describe '#create' do
    before do
      subject.create # rubocop:disable Rails/SaveBang
    end

    it 'creates the pool' do
      expect(subject.exists?).to be(true)
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
    context 'when the object pool repository exists' do
      let!(:pool_repository) { create(:pool_repository, :ready) }

      context 'without changes' do
        it 'does not raise an error' do
          expect { subject.fetch }.not_to raise_error
        end
      end

      context 'with new commit in source repository' do
        let(:branch_name) { Gitlab::Git::Ref.extract_branch_name(source_repository.root_ref) }
        let(:source_ref_name) { "refs/heads/#{branch_name}" }
        let(:pool_ref_name) { "refs/remotes/origin/heads/#{branch_name}" }

        let(:new_commit_id) do
          source_repository.create_file(
            pool_repository.source_project.owner,
            'a.file',
            'This is a file',
            branch_name: branch_name,
            message: 'Add a file'
          )
        end

        it 'fetches objects from the source repository' do
          # Sanity-check that the commit does not yet exist in the pool repository.
          expect(subject.repository.commit(new_commit_id)).to be_nil

          subject.fetch

          expect(subject.repository.commit(pool_ref_name).id).to eq(new_commit_id)
          expect(subject.repository.commit_count(pool_ref_name))
            .to eq(source_repository.raw_repository.commit_count(source_ref_name))
        end
      end
    end
  end
end
