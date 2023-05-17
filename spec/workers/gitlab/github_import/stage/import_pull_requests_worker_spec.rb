# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportPullRequestsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:import_state) { create(:import_state, project: project) }

  let(:worker) { described_class.new }
  let(:importer) { double(:importer) }
  let(:client) { double(:client) }

  describe '#import' do
    it 'imports all the pull requests' do
      waiter = Gitlab::JobWaiter.new(2, '123')

      expect(Gitlab::GithubImport::Importer::PullRequestsImporter)
        .to receive(:new)
        .with(project, client)
        .and_return(importer)

      expect(importer)
        .to receive(:execute)
        .and_return(waiter)

      expect(import_state)
        .to receive(:refresh_jid_expiration)

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, :collaborators)

      worker.import(client, project)
    end
  end

  it 'raises an error' do
    exception = StandardError.new('_some_error_')

    expect_next_instance_of(Gitlab::GithubImport::Importer::PullRequestsImporter) do |importer|
      expect(importer).to receive(:execute).and_raise(exception)
    end
    expect(Gitlab::Import::ImportFailureService).to receive(:track)
                                                      .with(
                                                        project_id: project.id,
                                                        exception: exception,
                                                        error_source: described_class.name,
                                                        fail_import: true,
                                                        metrics: true
                                                      ).and_call_original

    expect { worker.import(client, project) }.to raise_error(StandardError)
  end
end
