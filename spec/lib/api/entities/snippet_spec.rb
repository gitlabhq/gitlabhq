# frozen_string_literal: true

require 'spec_helper'

describe ::API::Entities::Snippet do
  let_it_be(:user) { create(:user) }
  let_it_be(:personal_snippet) { create(:personal_snippet, :repository, author: user ) }
  let_it_be(:project_snippet) { create(:project_snippet, :repository, author: user) }

  let(:entity) { described_class.new(snippet) }

  subject { entity.as_json }

  shared_examples 'common attributes' do
    it { expect(subject[:id]).to eq snippet.id }
    it { expect(subject[:title]).to eq snippet.title }
    it { expect(subject[:description]).to eq snippet.description }
    it { expect(subject[:updated_at]).to eq snippet.updated_at }
    it { expect(subject[:created_at]).to eq snippet.created_at }
    it { expect(subject[:project_id]).to eq snippet.project_id }
    it { expect(subject[:visibility]).to eq snippet.visibility }
    it { expect(subject).to include(:author) }

    describe 'file_name' do
      it 'returns attribute from repository' do
        expect(subject[:file_name]).to eq snippet.blobs.first.path
      end

      context 'when feature flag :version_snippets is disabled' do
        it 'returns attribute from db' do
          stub_feature_flags(version_snippets: false)

          expect(subject[:file_name]).to eq snippet.file_name
        end
      end

      context 'when repository is empty' do
        it 'returns attribute from db' do
          allow(snippet.repository).to receive(:empty?).and_return(true)

          expect(subject[:file_name]).to eq snippet.file_name
        end
      end
    end

    describe 'ssh_url_to_repo' do
      it 'returns attribute' do
        expect(subject[:ssh_url_to_repo]).to eq snippet.ssh_url_to_repo
      end

      context 'when feature flag :version_snippets is disabled' do
        it 'does not include attribute' do
          stub_feature_flags(version_snippets: false)

          expect(subject).not_to include(:ssh_url_to_repo)
        end
      end

      context 'when repository does not exist' do
        it 'does not include attribute' do
          allow(snippet).to receive(:repository_exists?).and_return(false)

          expect(subject).not_to include(:ssh_url_to_repo)
        end
      end
    end

    describe 'http_url_to_repo' do
      it 'returns attribute' do
        expect(subject[:http_url_to_repo]).to eq snippet.http_url_to_repo
      end

      context 'when feature flag :version_snippets is disabled' do
        it 'does not include attribute' do
          stub_feature_flags(version_snippets: false)

          expect(subject).not_to include(:http_url_to_repo)
        end
      end

      context 'when repository does not exist' do
        it 'does not include attribute' do
          allow(snippet).to receive(:repository_exists?).and_return(false)

          expect(subject).not_to include(:http_url_to_repo)
        end
      end
    end
  end

  context 'with PersonalSnippet' do
    let(:snippet) { personal_snippet }

    it_behaves_like 'common attributes'

    it 'returns snippet web_url attribute' do
      expect(subject[:web_url]).to match("/snippets/#{snippet.id}")
    end

    it 'returns snippet raw_url attribute' do
      expect(subject[:raw_url]).to match("/snippets/#{snippet.id}/raw")
    end
  end

  context 'with ProjectSnippet' do
    let(:snippet) { project_snippet }

    it_behaves_like 'common attributes'

    it 'returns snippet web_url attribute' do
      expect(subject[:web_url]).to match("#{snippet.project.full_path}/snippets/#{snippet.id}")
    end

    it 'returns snippet raw_url attribute' do
      expect(subject[:raw_url]).to match("#{snippet.project.full_path}/snippets/#{snippet.id}/raw")
    end
  end
end
