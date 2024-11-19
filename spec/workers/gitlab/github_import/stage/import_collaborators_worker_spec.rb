# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportCollaboratorsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, import_type: ::Import::SOURCE_GITHUB.to_s) }

  let(:settings) { Gitlab::GithubImport::Settings.new(project) }
  let(:stage_enabled) { true }
  let(:importer) { instance_double(Gitlab::GithubImport::Importer::CollaboratorsImporter) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    let(:push_rights_granted) { true }

    before do
      Feature.disable(:github_user_mapping)
      settings.write({ optional_stages: { collaborators_import: stage_enabled } })
      allow(client).to receive(:repository).with(project.import_source)
        .and_return({ permissions: { push: push_rights_granted } })
    end

    context 'when user has push access for this repo' do
      it 'imports all collaborators' do
        waiter = Gitlab::JobWaiter.new(2, '123')

        expect(Gitlab::GithubImport::Importer::CollaboratorsImporter)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)
        expect(importer).to receive(:execute).and_return(waiter)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, { '123' => 2 }, 'issues_and_diff_notes')

        worker.import(client, project)
      end
    end

    context 'when user do not have push access for this repo' do
      let(:push_rights_granted) { false }

      it 'skips stage' do
        expect(Gitlab::GithubImport::Importer::CollaboratorsImporter).not_to receive(:new)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, {}, 'issues_and_diff_notes')

        worker.import(client, project)
      end
    end

    context 'when stage is disabled' do
      let(:stage_enabled) { false }

      it 'skips collaborators import and calls next stage' do
        expect(Gitlab::GithubImport::Importer::CollaboratorsImporter).not_to receive(:new)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, {}, 'issues_and_diff_notes')

        worker.import(client, project)
      end
    end
  end
end
