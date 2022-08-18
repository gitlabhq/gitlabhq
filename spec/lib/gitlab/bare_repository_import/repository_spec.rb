# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::BareRepositoryImport::Repository do
  context 'legacy storage' do
    subject { described_class.new('/full/path/', '/full/path/to/repo.git') }

    it 'stores the repo path' do
      expect(subject.repo_path).to eq('/full/path/to/repo.git')
    end

    it 'stores the group path' do
      expect(subject.group_path).to eq('to')
    end

    it 'stores the project name' do
      expect(subject.project_name).to eq('repo')
    end

    it 'stores the wiki path' do
      expect(subject.wiki_path).to eq('/full/path/to/repo.wiki.git')
    end

    describe '#processable?' do
      it 'returns false if it is a wiki' do
        subject = described_class.new('/full/path/', '/full/path/to/a/b/my.wiki.git')

        expect(subject).not_to be_processable
      end

      it 'returns true if group path is missing' do
        subject = described_class.new('/full/path/', '/full/path/repo.git')

        expect(subject).to be_processable
      end

      it 'returns true when group path and project name are present' do
        expect(subject).to be_processable
      end
    end

    describe '#project_full_path' do
      it 'returns the project full path with trailing slash in the root path' do
        expect(subject.project_full_path).to eq('to/repo')
      end

      it 'returns the project full path with no trailing slash in the root path' do
        subject = described_class.new('/full/path', '/full/path/to/repo.git')

        expect(subject.project_full_path).to eq('to/repo')
      end
    end
  end

  context 'hashed storage' do
    let(:hashed_path) { "@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b" }
    let(:root_path) { TestEnv.repos_path }
    let(:repo_path) { File.join(root_path, "#{hashed_path}.git") }
    let(:wiki_path) { File.join(root_path, "#{hashed_path}.wiki.git") }
    let(:raw_repository) { Gitlab::Git::Repository.new('default', "#{hashed_path}.git", nil, nil) }
    let(:full_path) { 'to/repo' }

    before do
      raw_repository.create_repository
      raw_repository.set_full_path(full_path: full_path) if full_path
    end

    after do
      raw_repository.remove
    end

    subject { described_class.new(root_path, repo_path) }

    it 'stores the repo path' do
      expect(subject.repo_path).to eq(repo_path)
    end

    it 'stores the wiki path' do
      expect(subject.wiki_path).to eq(wiki_path)
    end

    it 'reads the group path from .git/config' do
      expect(subject.group_path).to eq('to')
    end

    it 'reads the project name from .git/config' do
      expect(subject.project_name).to eq('repo')
    end

    describe '#processable?' do
      it 'returns false if it is a wiki' do
        subject = described_class.new(root_path, wiki_path)

        expect(subject).not_to be_processable
      end

      it 'returns true when group path and project name are present' do
        expect(subject).to be_processable
      end

      context 'group and project name are missing' do
        let(:full_path) { nil }

        it 'returns false' do
          expect(subject).not_to be_processable
        end
      end
    end

    describe '#project_full_path' do
      it 'returns the project full path with trailing slash in the root path' do
        expect(subject.project_full_path).to eq('to/repo')
      end

      it 'returns the project full path with no trailing slash in the root path' do
        subject = described_class.new(root_path[0...-1], repo_path)

        expect(subject.project_full_path).to eq('to/repo')
      end
    end
  end
end
