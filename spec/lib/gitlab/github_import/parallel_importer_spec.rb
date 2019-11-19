# frozen_string_literal: true

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
      create(:import_state, :started, project: project)

      expect(Gitlab::GithubImport::Stage::ImportRepositoryWorker)
        .to receive(:perform_async)
        .with(project.id)
        .and_return('123')
    end

    it 'schedules the importing of the repository' do
      expect(importer.execute).to eq(true)
    end

    it 'sets the JID in Redis' do
      expect(Gitlab::Import::SetAsyncJid).to receive(:set_jid).with(project).and_call_original

      importer.execute
    end
  end
end
