# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::RepositoryImporter, feature_category: :importers do
  let_it_be(:project) { create(:project, import_url: 'http://bitbucket:test@my-bitbucket') }

  subject(:importer) { described_class.new(project) }

  describe '#execute' do
    context 'when repository is empty' do
      it 'imports the repository' do
        expect(project.repository).to receive(:import_repository).with(project.import_url)
        expect(project.last_repository_updated_at).to be_present

        importer.execute
      end
    end

    context 'when repository is not empty' do
      before do
        allow(project).to receive(:empty_repo?).and_return(false)

        project.last_repository_updated_at = 1.day.ago
      end

      it 'does not import the repository' do
        expect(project.repository).not_to receive(:import_repository)

        expect { importer.execute }.not_to change { project.last_repository_updated_at }
      end
    end

    context 'when a Git CommandError is raised and the repository exists' do
      before do
        allow(project.repository).to receive(:import_repository).and_raise(::Gitlab::Git::CommandError)
        allow(project).to receive(:repository_exists?).and_return(true)
      end

      it 'expires repository caches' do
        expect(project.repository).to receive(:expire_content_cache)

        expect { importer.execute }.to raise_error(::Gitlab::Git::CommandError)
      end
    end
  end
end
