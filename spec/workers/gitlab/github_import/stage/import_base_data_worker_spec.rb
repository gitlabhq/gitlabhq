# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportBaseDataWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:import_state) { create(:import_state, project: project) }

  let(:worker) { described_class.new }
  let(:importer) { double(:importer) }
  let(:client) { double(:client) }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    it 'imports the base data of a project' do
      described_class::IMPORTERS.each do |klass|
        expect(klass)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)

        expect(importer).to receive(:execute)
      end

      expect(import_state).to receive(:refresh_jid_expiration)

      expect(Gitlab::GithubImport::Stage::ImportPullRequestsWorker)
        .to receive(:perform_async)
        .with(project.id)

      worker.import(client, project)
    end
  end
end
