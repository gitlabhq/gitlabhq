require 'spec_helper'

describe Gitlab::GithubImport::ParallelImporter do
  describe '.async?' do
    it 'returns true' do
      expect(described_class).to be_async
    end
  end

  describe '#execute', :clean_gitlab_redis_shared_state do
    let(:project) { create(:project) }
    let(:importer) { described_class.new(project) }

    before do
      expect(Gitlab::GithubImport::Stage::ImportRepositoryWorker)
        .to receive(:perform_async)
        .with(project.id)
        .and_return('123')
    end

    it 'schedules the importing of the repository' do
      expect(importer.execute).to eq(true)
    end

    it 'sets the JID in Redis' do
      expect(Gitlab::SidekiqStatus)
        .to receive(:set)
        .with("github-importer/#{project.id}", StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION)
        .and_call_original

      importer.execute
    end

    it 'updates the import JID of the project' do
      importer.execute

      expect(project.import_jid).to eq("github-importer/#{project.id}")
    end
  end
end
