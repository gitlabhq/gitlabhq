# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Compare, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository.raw }

  let(:compare) { described_class.new(repository, base, head, straight: false) }
  let(:compare_straight) { described_class.new(repository, base, head, straight: true) }
  let(:base) { SeedRepo::BigCommit::ID }
  let(:head) { SeedRepo::Commit::ID }

  describe '#commits' do
    subject do
      compare.commits.map(&:id)
    end

    it 'has 8 elements' do
      expect(subject.size).to eq(8)
    end

    it { is_expected.to include(SeedRepo::Commit::PARENT_ID) }
    it { is_expected.not_to include(SeedRepo::BigCommit::PARENT_ID) }

    context 'non-existing base ref' do
      let(:compare) { described_class.new(repository, 'no-such-branch', SeedRepo::Commit::ID) }

      it { is_expected.to be_empty }
    end

    context 'non-existing head ref' do
      let(:compare) { described_class.new(repository, SeedRepo::BigCommit::ID, '1234567890') }

      it { is_expected.to be_empty }
    end

    context 'base ref is equal to head ref' do
      let(:compare) { described_class.new(repository, SeedRepo::BigCommit::ID, SeedRepo::BigCommit::ID) }

      it { is_expected.to be_empty }
    end

    context 'providing nil as base ref or head ref' do
      let(:compare) { described_class.new(repository, nil, nil) }

      it { is_expected.to be_empty }
    end
  end

  describe '#diffs' do
    subject do
      compare.diffs.map(&:new_path)
    end

    it 'has 10 elements' do
      expect(subject.size).to eq(10)
    end

    it { is_expected.to include('files/ruby/popen.rb') }
    it { is_expected.not_to include('LICENSE') }

    context 'non-existing base ref' do
      let(:compare) { described_class.new(repository, 'no-such-branch', SeedRepo::Commit::ID) }

      it { is_expected.to be_empty }
    end

    context 'non-existing head ref' do
      let(:compare) { described_class.new(repository, SeedRepo::BigCommit::ID, '1234567890') }

      it { is_expected.to be_empty }
    end
  end

  describe '#same' do
    subject do
      compare.same
    end

    it { is_expected.to eq(false) }

    context 'base ref is equal to head ref' do
      let(:compare) { described_class.new(repository, SeedRepo::BigCommit::ID, SeedRepo::BigCommit::ID) }

      it { is_expected.to eq(true) }
    end
  end

  describe '#commits', 'straight compare' do
    subject do
      compare_straight.commits.map(&:id)
    end

    it 'has 8 elements' do
      expect(subject.size).to eq(8)
    end

    it { is_expected.to include(SeedRepo::Commit::PARENT_ID) }
    it { is_expected.not_to include(SeedRepo::BigCommit::PARENT_ID) }
  end

  describe '#diffs', 'straight compare' do
    subject do
      compare_straight.diffs.map(&:new_path)
    end

    it 'has 10 elements' do
      expect(subject.size).to eq(10)
    end

    it { is_expected.to include('files/ruby/popen.rb') }
    it { is_expected.not_to include('LICENSE') }
  end

  describe '#generated_files' do
    subject(:generated_files) { compare.generated_files }

    let(:project) do
      create(:project, :custom_repo, files: {
        '.gitattributes' => '*.txt gitlab-generated'
      })
    end

    let(:repository) { project.repository.raw }
    let(:branch) { 'generated-file-test' }
    let(:base) { project.default_branch }
    let(:head) { branch }

    context 'with a detected generated file' do
      before do
        project.repository.create_branch(branch, project.default_branch)
        project
          .repository
          .create_file(
            project.creator,
            'file1.rb',
            "some content\n",
            branch_name: branch,
            message: 'Add file1')
        project
          .repository
          .create_file(
            project.creator,
            'file1.txt',
            "some content\n",
            branch_name: branch,
            message: 'Add file2')
      end

      it 'returns a set that incldues the generated file' do
        expect(generated_files).to eq Set.new(['file1.txt'])
      end

      context 'when base is nil' do
        let(:base) { nil }

        it 'does not try to detect generated files' do
          expect(repository).not_to receive(:detect_generated_files)
          expect(repository).not_to receive(:find_changed_paths)
          expect(generated_files).to eq Set.new
        end
      end

      context 'when head is nil' do
        let(:head) { nil }

        it 'does not try to detect generated files' do
          expect(repository).not_to receive(:detect_generated_files)
          expect(repository).not_to receive(:find_changed_paths)
          expect(generated_files).to eq Set.new
        end
      end
    end

    context 'with deleted .gitattributes in the HEAD' do
      before do
        project.repository.create_branch(branch, project.default_branch)
        project
          .repository
          .delete_file(
            project.creator,
            '.gitattributes',
            branch_name: branch,
            message: 'Delete .gitattributes file')
        project
          .repository
          .create_file(
            project.creator,
            'file1.rb',
            "some content\n",
            branch_name: branch,
            message: 'Add file1')
        project
          .repository
          .create_file(
            project.creator,
            'file1.txt',
            "some content\n",
            branch_name: branch,
            message: 'Add file2')
      end

      it 'ignores the .gitattributes changes in the HEAD' do
        expect(generated_files).to eq Set.new(['file1.txt'])
      end
    end
  end
end
