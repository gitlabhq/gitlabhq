# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportAttachmentsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:settings) { ::Gitlab::GithubImport::Settings.new(project.reload) }
  let(:stage_enabled) { true }

  subject(:worker) { described_class.new }

  before do
    settings.write({ optional_stages: { attachments_import: stage_enabled } })
  end

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    let(:client) { instance_double('Gitlab::GithubImport::Client') }
    let(:importers) do
      [
        {
          klass: Gitlab::GithubImport::Importer::Attachments::ReleasesImporter,
          double: instance_double('Gitlab::GithubImport::Importer::Attachments::ReleasesImporter'),
          waiter: Gitlab::JobWaiter.new(2, '123')
        },
        {
          klass: Gitlab::GithubImport::Importer::Attachments::NotesImporter,
          double: instance_double('Gitlab::GithubImport::Importer::Attachments::NotesImporter'),
          waiter: Gitlab::JobWaiter.new(3, '234')
        },
        {
          klass: Gitlab::GithubImport::Importer::Attachments::IssuesImporter,
          double: instance_double('Gitlab::GithubImport::Importer::Attachments::IssuesImporter'),
          waiter: Gitlab::JobWaiter.new(4, '345')
        },
        {
          klass: Gitlab::GithubImport::Importer::Attachments::MergeRequestsImporter,
          double: instance_double('Gitlab::GithubImport::Importer::Attachments::MergeRequestsImporter'),
          waiter: Gitlab::JobWaiter.new(5, '456')
        }
      ]
    end

    it 'imports attachments' do
      importers.each do |importer|
        expect_next_instance_of(importer[:klass], project, client) do |instance|
          expect(instance).to receive(:execute).and_return(importer[:waiter])
        end
      end

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2, '234' => 3, '345' => 4, '456' => 5 }, 'protected_branches')

      worker.import(client, project)
    end

    context 'when stage is disabled' do
      let(:stage_enabled) { false }

      it 'skips release attachments import and calls next stage' do
        importers.each { |importer| expect(importer[:klass]).not_to receive(:new) }
        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async).with(project.id, {}, 'protected_branches')

        worker.import(client, project)
      end
    end
  end
end
