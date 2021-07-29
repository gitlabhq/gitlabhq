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
      file_count = snippet_with_repo.repository.ls_files(snippet_with_repo.default_branch).count

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
    it 'retrieves and saves statistic data from repository' do
      expect(statistics).to receive(:update_commit_count)
      expect(statistics).to receive(:update_file_count)
      expect(statistics).to receive(:update_repository_size)
      expect(statistics).to receive(:save!)

      statistics.refresh!
    end

    context 'when the database is read-only' do
      it 'does nothing' do
        allow(Gitlab::Database.main).to receive(:read_only?) { true }

        expect(statistics).not_to receive(:update_commit_count)
        expect(statistics).not_to receive(:update_file_count)
        expect(statistics).not_to receive(:update_repository_size)
        expect(statistics).not_to receive(:save!)
        expect(Namespaces::ScheduleAggregationWorker)
          .not_to receive(:perform_async)

        statistics.refresh!
      end
    end
  end

  context 'with a PersonalSnippet' do
    let!(:snippet) { create(:personal_snippet, :repository) }

    shared_examples 'personal snippet statistics updates' do
      it 'schedules a namespace statistics worker' do
        expect(Namespaces::ScheduleAggregationWorker)
          .to receive(:perform_async).once

        statistics.save!
      end

      it 'does not try to update project stats' do
        expect(statistics).not_to receive(:schedule_update_project_statistic)

        statistics.save!
      end
    end

    context 'when creating' do
      let(:statistics) { build(:snippet_statistics, snippet_id: snippet.id, with_data: true) }

      before do
        snippet.statistics.delete
      end

      it_behaves_like 'personal snippet statistics updates'
    end

    context 'when updating' do
      let(:statistics) { snippet.statistics }

      before do
        snippet.statistics.repository_size = 123
      end

      it_behaves_like 'personal snippet statistics updates'
    end
  end

  context 'with a ProjectSnippet' do
    let!(:snippet) { create(:project_snippet) }

    it_behaves_like 'UpdateProjectStatistics' do
      subject { build(:snippet_statistics, snippet: snippet, id: snippet.id, with_data: true) }

      before do
        # The shared examples requires the snippet statistics not to be present
        snippet.statistics.delete
        snippet.reload
      end
    end

    it 'does not call personal snippet callbacks' do
      expect(snippet.statistics).not_to receive(:update_author_root_storage_statistics)
      expect(snippet.statistics).to receive(:schedule_update_project_statistic)

      snippet.statistics.update!(repository_size: 123)
    end
  end
end
