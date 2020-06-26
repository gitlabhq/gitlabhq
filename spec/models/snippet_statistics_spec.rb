# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetStatistics do
  let_it_be(:snippet_without_repo) { create(:snippet) }
  let_it_be(:snippet_with_repo) { create(:snippet, :repository) }

  let(:statistics) { snippet_with_repo.statistics }

  it { is_expected.to belong_to(:snippet) }
  it { is_expected.to validate_presence_of(:snippet) }

  describe '#update_commit_count' do
    subject { statistics.update_commit_count }

    it 'updates the count of commits' do
      commit_count = snippet_with_repo.repository.commit_count

      subject

      expect(statistics.commit_count).to eq commit_count
    end

    context 'when the snippet does not have a repository' do
      let(:statistics) { snippet_without_repo.statistics }

      it 'returns 0' do
        expect(subject).to eq 0
        expect(statistics.commit_count).to eq 0
      end
    end
  end

  describe '#update_file_count' do
    subject { statistics.update_file_count }

    it 'updates the count of files' do
      file_count = snippet_with_repo.repository.ls_files(nil).count

      subject

      expect(statistics.file_count).to eq file_count
    end

    context 'when the snippet does not have a repository' do
      let(:statistics) { snippet_without_repo.statistics }

      it 'returns 0' do
        expect(subject).to eq 0
        expect(statistics.file_count).to eq 0
      end
    end
  end

  describe '#update_repository_size' do
    subject { statistics.update_repository_size }

    it 'updates the repository_size' do
      repository_size = snippet_with_repo.repository.size.megabytes.to_i

      subject

      expect(statistics.repository_size).to eq repository_size
    end

    context 'when the snippet does not have a repository' do
      let(:statistics) { snippet_without_repo.statistics }

      it 'returns 0' do
        expect(subject).to eq 0
        expect(statistics.repository_size).to eq 0
      end
    end
  end

  describe '#refresh!' do
    subject { statistics.refresh! }

    it 'retrieves and saves statistic data from repository' do
      expect(statistics).to receive(:update_commit_count)
      expect(statistics).to receive(:update_file_count)
      expect(statistics).to receive(:update_repository_size)
      expect(statistics).to receive(:save!)

      subject
    end
  end
end
