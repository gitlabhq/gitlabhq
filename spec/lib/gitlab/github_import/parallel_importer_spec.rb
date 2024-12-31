# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ParallelImporter, feature_category: :importers do
  describe '.async?' do
    it 'returns true' do
      expect(described_class).to be_async
    end
  end

  describe '.track_start_import' do
    it 'tracks the start of import' do
      project = double(:project)
      metrics = double(:metrics)

      expect(Gitlab::Import::Metrics).to receive(:new).with(:github_importer, project).and_return(metrics)
      expect(metrics).to receive(:track_start_import)

      described_class.track_start_import(project)
    end
  end

  describe '#execute', :clean_gitlab_redis_shared_state do
    let(:project) { create(:project) }
    let(:importer) { described_class.new(project) }

    before do
      create(:import_state, :started, project: project)
      worker = double(:worker)

      expect(Gitlab::GithubImport::Stage::ImportRepositoryWorker)
        .to receive(:with_status)
        .and_return(worker)

      expect(worker)
        .to receive(:perform_async)
        .with(project.id)
        .and_return('123')
    end

    it 'schedules the importing of the repository' do
      expect(importer.execute).to eq(true)
    end

    it 'sets the JID in Redis' do
      expect(Gitlab::Import::SetAsyncJid).to receive(:set_jid).with(project.import_state).and_call_original

      importer.execute
    end
  end
end
