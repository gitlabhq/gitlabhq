# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportBaseDataWorker do
  let(:project) { create(:project) }
  let(:import_state) { create(:import_state, project: project) }
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports the base data of a project' do
      importer = double(:importer)
      client = double(:client)

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
