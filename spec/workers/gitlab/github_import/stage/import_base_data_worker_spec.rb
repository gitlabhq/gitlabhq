# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportBaseDataWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:importer) { double(:importer) }
  let(:client) { double(:client) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    it 'imports the base data of a project' do
      allow_next_instance_of(Gitlab::GithubImport::Settings) do |setting|
        allow(setting).to receive(:prioritize_collaborators?).and_return(true)
      end

      described_class::IMPORTERS.each do |klass|
        expect(klass)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)

        expect(importer).to receive(:execute)
      end

      expect(Gitlab::GithubImport::Stage::ImportCollaboratorsWorker)
        .to receive(:perform_async)
        .with(project.id)

      worker.import(client, project)
    end

    context 'when the prioritize_collaborators feature flag is disabled' do
      it 'imports the base data of a project' do
        allow_next_instance_of(Gitlab::GithubImport::Settings) do |setting|
          allow(setting).to receive(:prioritize_collaborators?).and_return(false)
        end

        described_class::IMPORTERS.each do |klass|
          expect(klass)
            .to receive(:new)
            .with(project, client)
            .and_return(importer)

          expect(importer).to receive(:execute)
        end

        expect(Gitlab::GithubImport::Stage::ImportPullRequestsWorker)
          .to receive(:perform_async)
          .with(project.id)

        worker.import(client, project)
      end
    end
  end
end
