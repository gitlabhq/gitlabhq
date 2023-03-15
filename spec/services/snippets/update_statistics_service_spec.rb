# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::UpdateStatisticsService, feature_category: :source_code_management do
  describe '#execute' do
    subject { described_class.new(snippet).execute }

    shared_examples 'updates statistics' do
      it 'returns a successful response' do
        expect(subject).to be_success
      end

      it 'expires statistics cache' do
        expect(snippet.repository).to receive(:expire_statistics_caches)

        subject
      end

      context 'when snippet statistics does not exist' do
        it 'creates snippet statistics' do
          snippet.statistics.delete
          snippet.reload

          expect do
            subject
          end.to change(SnippetStatistics, :count).by(1)

          expect(snippet.statistics.commit_count).not_to be_zero
          expect(snippet.statistics.file_count).not_to be_zero
          expect(snippet.statistics.repository_size).not_to be_zero
        end
      end

      context 'when snippet statistics exists' do
        it 'updates snippet statistics' do
          expect(snippet.statistics.commit_count).to be_zero
          expect(snippet.statistics.file_count).to be_zero
          expect(snippet.statistics.repository_size).to be_zero

          subject

          expect(snippet.statistics.commit_count).not_to be_zero
          expect(snippet.statistics.file_count).not_to be_zero
          expect(snippet.statistics.repository_size).not_to be_zero
        end
      end

      context 'when snippet does not have a repository' do
        it 'returns an error response' do
          expect(snippet).to receive(:repository_exists?).and_return(false)

          expect(subject).to be_error
        end
      end

      it 'schedules a namespace storage statistics update' do
        expect(Namespaces::ScheduleAggregationWorker)
            .to receive(:perform_async).once

        subject
      end
    end

    context 'with PersonalSnippet' do
      let!(:snippet) { create(:personal_snippet, :repository) }

      it_behaves_like 'updates statistics'
    end

    context 'with ProjectSnippet' do
      let!(:snippet) { create(:project_snippet, :repository) }
      let(:project_statistics) { snippet.project.statistics }

      it_behaves_like 'updates statistics'

      it 'updates projects statistics "snippets_size"' do
        expect(project_statistics.snippets_size).to be_zero

        subject

        expect(snippet.reload.statistics.repository_size).to eq project_statistics.reload.snippets_size
      end
    end
  end
end
